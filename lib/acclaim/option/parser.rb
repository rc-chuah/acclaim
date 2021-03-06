%w(

acclaim/option/parser/error
acclaim/option/parser/regexp

ribbon

).each { |file| require file }

module Acclaim
  class Option

    # Parses arrays of strings and returns an Options instance containing data.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.0.1
    class Parser

      include Parser::Regexp

      # The argument array to parse.
      attr_accessor :argv

      # The options to be parsed.
      attr_accessor :options

      # Initializes a new parser, with the given argument array and set of
      # options. If no option array is given, the argument array will be
      # preprocessed only.
      def initialize(argv, options = nil)
        self.argv = argv || []
        self.options = options || []
      end

      # Parses the given argument array, looking for the given {Option options}
      # and their arguments if any.
      #
      # If no options were given, the argument array will be preprocessed only.
      #
      # @note Parsed options and their parameters will be removed from the
      #   argument array.
      #
      # @example
      #   include Acclaim
      #
      #   args = %w(-F log.txt --verbose arg1 arg2)
      #   options = []
      #   options << Option.new(:file, '-F', arity: [1,0], required: true)
      #   options << Option.new(:verbose)
      #
      #   Option::Parser.new(args, options).parse!
      #   # => {file: "log.txt", verbose: true}
      #
      #   args
      #   # => ["arg1", "arg2"]
      def parse!
        preprocess_argv!
        parse_values!.tap do
          delete_options_from_argv!
        end
      end

      private

      # List of arguments that are to be removed from argv, identified by their
      # index.
      #
      # @return [Array] the indexes of options marked for deletion
      # @see #delete_options_from_argv!
      # @since 0.4.0
      def deleted_options
        @deleted_options ||= []
      end

      # Deletes all marked options from argv.
      #
      # @note The list of removed indexes will be discarded.
      #
      # @see #deleted_options
      # @since 0.4.0
      def delete_options_from_argv!
        argv.delete_if.with_index do |argument, index|
          deleted_options.include? index
        end
      ensure
        deleted_options.clear
      end

      # Preprocesses the argument array.
      def preprocess_argv!
        split_multiple_short_options!
        normalize_parameters!
        argv.compact!
        check_for_errors!
      end

      # Splits multiple short options.
      #
      #   %w(-abcdef PARAM1 PARAM2) => %w(-a -b -c -d -e -f PARAM1 PARAM2)
      def split_multiple_short_options!
        argv.each_with_index.find_all do |argument, index|
          argument =~ MULTIPLE_SHORT_SWITCHES
        end.each do |argument, index|
          argv.delete_at index
          switches = argument.gsub(/\A-/, '').split(//).each { |letter| letter.prepend '-' }
          argv.insert index, switches
        end
        argv.flatten!
      end

      # Splits switches that are connected to a comma-separated parameter list.
      #
      #   %w(--switch=)              => %w(--switch)
      #   %w(--switch=PARAM1,PARAM2) => %w(--switch PARAM1 PARAM2)
      #   %w(--switch=PARAM1,)       => %w(--switch PARAM1)
      #   %w(--switch=,PARAM2)       =>   [ '--switch', '', 'PARAM2' ]
      #
      # @since 0.0.3
      def normalize_parameters!
        argv.each_with_index.find_all do |argument, index|
          argument =~ SWITCH_PARAM_EQUALS
        end.each do |switch, index|
          argv.delete_at index
          switch, parameters = switch.split /\=/
          parameters = if parameters.respond_to? :split then parameters else '' end.split /,/
          argv.insert index, [switch, *parameters]
        end
        argv.flatten!
      end

      # Checks to see if the arguments have any errors
      #
      # @since 0.4.0
      def check_for_errors!
        ensure_required_options_are_present!
        raise_on_multiple_options!
      end

      # Ensures all options are present in the argument array; raises a parser
      # error otherwise.
      #
      # @since 0.4.0
      def ensure_required_options_are_present!
        options.find_all(&:required?).each do |option|
          Error.raise_missing_required option if argv.find_all do |argument|
            option =~ argument
          end.empty?
        end
      end

      # Raises a parser error if multiple switches were found for an option that
      # explicitly disallowed it.
      #
      # @since 0.4.0
      def raise_on_multiple_options!
        options.find_all do |option|
          option.on_multiple == :raise
        end.each do |option|
          Error.raise_multiple option if argv.find_all do |argument|
            option =~ argument
          end.count > 1
        end
      end

      # Parses the options and their arguments, associating that information
      # with a ribbon.
      #
      # @since 0.0.3
      def parse_values!
        Ribbon.new.tap do |values|
          # Pre-initialize the ribbon with default values
          options.each do |option|
            key = option.key
            values[key] = option.default unless values.has_key? key
          end

          # Now, with that out of the way, let's parse the command line.
          argv.each_with_index do |argument, index|
            options.find_all do |option|
              option =~ argument
            end.each do |option|
              if option.flag?
                found_boolean option, values
                deleted_options << index
              else
                parameters = extract_parameters_of! option, index
                found_params_for option, parameters, values
              end
            end
          end
        end
      end

      # Starting from the given index, extracts parameters from the following
      # arguments. Stops if it finds nil, another switch, an argument separator,
      # or if enough values have been found according to the option's arity.
      #
      # @note All arguments scanned, in addition to the option at the given
      #   index, will be marked for deletion.
      #
      # @return [Array] the parameters for the given option found in argv
      # @raise [Parser::Error] if not enough arguments are found
      # @since 0.0.4
      def extract_parameters_of!(option, index)
        arity = option.arity
        length = if arity.bound? then index + arity.total else argv.length - 1 end
        values = []
        argv[index + 1, length].each do |param|
          case param
            when nil, SWITCH, ARGUMENT_SEPARATOR then break
            else
              break if arity.bound? and values.count >= arity.total
              values << param
          end
        end
        count = values.count
        Error.raise_wrong_arg_number count, *arity if count < arity.required
        limit = index + count
        range = index..limit
        deleted_options.push *range
        values
      end

      # If the option has an custom handler associated, it will be called with
      # the option values as the first argument and the array of parameters
      # found as the second argument. Otherwise, the value will be set to
      # <tt>params.first</tt>, if the option takes only one argument, or to
      # +params+ if it takes more.
      #
      # Appends +params+ to the current values of the option if the it specifies
      # so. In this case, the value of the option will always be an array.
      #
      # The parameters will be converted according to the option's type.
      #
      # @since 0.0.6
      def found_params_for(option, params = [], ribbon = Ribbon.new)
        params = option.convert_parameters *params
        if handler = option.handler then handler.call ribbon, params
        else
          key = option.key
          value = option.arity.total == 1 ? params.first : params
          value = [*ribbon[key], *value] if [:append, :collect].include? option.on_multiple
          ribbon[key] = value unless params.empty?
        end
      end

      # If the option has an custom handler associated, it will be called with
      # only the option values as the first argument. Otherwise, the value will
      # be set to <tt>true</tt>.
      #
      # @since 0.0.6
      def found_boolean(option, ribbon = Ribbon.new)
        if handler = option.handler then handler.call ribbon
        else ribbon[option.key] = true end
      end

    end
  end
end
