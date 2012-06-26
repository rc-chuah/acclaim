require 'acclaim/option/type'

module Acclaim
  class Option
    module Type

      # Handles complex numbers given as arguments in the command line.
      #
      # @author Matheus Afonso Martins Moreira
      # @since 0.3.0
      module Complex
      end

      class << Complex

        # Uses Complex() to convert the string to a complex number
        #
        # @param [String] string string representation of the complex number
        # @param [Rational] the complex number converted from the string
        def handle(string)
          Complex(string)
        end

      end

      accept ::Complex, &Complex.method(:handle)

    end
  end
end
