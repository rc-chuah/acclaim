%w(

erb
ribbon/core_extensions/array

).each { |file| require file }

module Acclaim
  class Command
    module Help

      # Manages help templates.
      #
      # @author Matheus Afonso Martins Moreira
      # @since 0.0.5
      module Template
      end

      class << Template

        # Returns the path to the directory where templates are stored.
        #
        # @return [String] absolute path to the templates directory
        # @since 0.6.0
        def directory
          Acclaim::Gem.root.templates.help.to_s
        end

        alias folder directory

        # Loads the contents of a template file from the template directory.
        #
        # @param [String] template_file the name of the template file
        # @return [String] the contents of the template file
        def load(template_file)
          File.read File.join(folder, template_file)
        end

        # Creates a new ERB instance with the contents of the template.
        #
        # @param [String] template_file the name of the template file
        # @return [ERB] a new ERB template
        # @since 0.2.0
        def create_from(template_file)
          ERB.new load(template_file), nil, '%<>'
        end

        # Computes the result of the template +file+ using the +command+'s
        # binding.
        #
        # @param [Acclaim::Command::DSL] command the command to display help for
        # @param [Hash, Ribbon, Ribbon::Raw] template_options template
        #   configuration options
        # @option template_options [true, false] :include_root (false) whether
        #   to include the root command in command invocation lines
        def for(command, template_options = {})
          template_options = Ribbon.new template_options
          template = create_from template_options.file? { 'command.erb' }
          command_binding = command.instance_eval { binding }
          # Since blocks are closures, the binding has access to the
          # template_options ribbon:
          #
          # p command_binding.eval 'template_options'
          #  => {}
          template.result command_binding
        end

      end

    end
  end
end
