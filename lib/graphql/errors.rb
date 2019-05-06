# frozen_string_literal: true

require "graphql"
require "graphql/errors/version"

module GraphQL
  class Errors
    EmptyConfigurationError = Class.new(StandardError)
    EmptyRescueError = Class.new(StandardError)
    NotRescuableError = Class.new(StandardError)

    def self.configure(schema, &block)
      raise EmptyConfigurationError unless block

      instance = new(&block)
      schema.instrument(:field, instance)
    end

    def initialize(&block)
      @handler_by_class = {}
      if Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.9.0.pre3')
        @field_extension = generate_field_extension
      end
      self.instance_eval(&block)
    end

    def instrument(_type, field)
      old_resolve_proc = field.resolve_proc

      if @field_extension && (type_class = field.metadata[:type_class])
        type_class.extension(@field_extension)
        field
      else
        new_resolve_proc = lambda do |obj, args, ctx|
          wrap_proc(obj, args, ctx, old_resolve_proc)
        end

        old_lazy_resolve_proc = field.lazy_resolve_proc

        new_lazy_resolve_proc = lambda do |obj, args, ctx|
          wrap_proc(obj, args, ctx, old_lazy_resolve_proc)
        end

        field.redefine do
          resolve(new_resolve_proc)
          lazy_resolve(new_lazy_resolve_proc)
        end
      end
    end

    def rescue_from(*classes, &block)
      raise EmptyRescueError unless block

      classes.each do |klass|
        raise NotRescuableError.new(klass.inspect) unless klass.is_a?(Class)
        @handler_by_class[klass] ||= block
      end
    end

    private

    def wrap_proc(object, arguments, context, old_proc)
      begin
        old_proc.call(object, arguments, context)
      rescue => exception
        if handler = find_handler(exception)
          handler.call(exception, object, arguments, context)
        else
          raise exception
        end
      end
    end

    def find_handler(exception)
      @handler_by_class.each do |klass, handler|
        return handler if exception.is_a?(klass)
      end

      nil
    end

    def generate_field_extension
      field_extension = Class.new(GraphQL::Schema::FieldExtension) do

        def resolve(object:, arguments:, context:, **_rest)
          begin
            yield(object, arguments)
          rescue => exception
            if (handler = self.class::ERRORS_INSTANCE.send(:find_handler, exception))
              handler.call(exception, object, arguments, context)
            else
              raise exception
            end
          end
        end

      end
      field_extension.const_set(:ERRORS_INSTANCE, self)
      field_extension
    end
  end
end
