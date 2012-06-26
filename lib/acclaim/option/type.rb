module Acclaim
  class Option

    # Associates a class with a handler block.
    #
    # @author Matheus Afonso Martins Moreira
    # @since 0.0.4
    module Type
    end

    # The class methods.
    class << Type

      # Yields class, proc pairs if a block was given. Returns an enumerator
      # otherwise.
      #
      # @yieldparam [Class, Module] type the class or module
      # @yieldparam [Proc] handler the type handler
      def each(&block)
        table.each &block
      end

      # Take advantage of each method.
      include Enumerable

      # Returns all registered classes.
      #
      # @return [Array<Class, Module>] registered types
      def all
        table.keys
      end

      alias registered all

      # Registers a handler for a class.
      #
      # @param [Class, Module] classes the types to associate with the handler
      # @param [Proc] block how to handle the type(s)
      # @yieldparam [String] string the command line argument
      # @yieldreturn [Class, Module] new object of the handled type
      def register(*classes, &block)
        classes.each { |klass| table[klass] = block }
      end

      alias add_handler_for register
      alias accept register

      # Returns the handler for the given class.
      def handler_for(klass)
        table.fetch klass do
          raise "#{klass} does not have an associated handler"
        end
      end

      alias [] handler_for

      private

      # The hash used to associate classes with their handlers.
      def table
        @table ||= {}
      end

    end

  end
end

%w(
  big_decimal
  complex
  date
  date_time
  float
  integer
  pathname
  rational
  string
  symbol
  time
  uri
).each do |type|
  require type.prepend 'acclaim/option/type/'
end
