# frozen_string_literal: true

require "graphql"
require "graphql/errors/version"

module GraphQL
  class Errors
    class << self
      def configuration(&block)
        new(&block)
      end
    end

    def initialize(&block)
      @block = block
    end

    def use(schema_definition)

    end
  end
end
