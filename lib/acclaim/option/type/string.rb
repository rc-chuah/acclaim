require 'acclaim/option/type'

module Acclaim
  class Option
    module Type

      # Handles strings given as arguments in the command line.
      #
      # @author Matheus Afonso Martins Moreira
      module String
      end

      class << String

        # Makes sure the given string is a string by coercing it using +to_s+.
        #
        # @param [String] string the string to coerce
        # @return [String] the coerced string
        def handle(string)
          string.to_s
        end

        # New empty string.
        #
        # @return [String] empty string
        # @since 0.6.0
        def default
          ::String.new
        end

      end

      accept ::String, &String.method(:handle)

    end
  end
end
