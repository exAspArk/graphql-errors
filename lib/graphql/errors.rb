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
      self.instance_eval(&block)
    end

    def instrument(_type, field)
      old_resolve_proc = field.resolve_proc

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

    def rescue_from(*classes, &block)
      raise EmptyRescueError unless block

      classes.each do |klass|
        if klass.is_a?(Module) && klass.respond_to?(:===)
          @handler_by_class[klass] ||= block
        else
          raise NotRescuableError.new(klass.inspect)
        end
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
        return handler if klass === exception
      end

      nil
    end
  end
end
