# frozen_string_literal: true

PostType = GraphQL::ObjectType.define do
  name "Post"
  field :id, !types.ID
  field :title, !types.String
  field :description, !types.String, resolve: ->(_obj, _args, _ctx) { raise Post::WorksOnMyMachine.new('Can not parse the description') }
  field :language, !types.String, resolve: ->(_obj, _args, _ctx) { raise "Request failed" }
  field :category, !types.String, resolve: ->(_obj, _args, _ctx) { raise Post::Invalid.new('Post is invalid') }
  field :author, !types.String, resolve: ->(_obj, _args, _ctx) { raise Post::Boom.new('Invalid author') }
end

QueryType = GraphQL::ObjectType.define do
  name "Query"
  field :posts, !types[!PostType] do
    argument :user_id, !types.ID
    resolve ->(_obj, args, _ctx) { Post.where(user_id: args[:user_id]) }
  end

  field :post, !PostType do
    argument :id, !types.ID
    resolve ->(_obj, _args, _ctx) { raise Post::NotFound.new('Post not found') }
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
end

GraphQL::Errors.configure(Schema) do
  rescue_from Post::NotFound, Post::Invalid do |exception|
    GraphQL::ExecutionError.new('Post is invalid')
  end

  rescue_from Post::Oops do |exception|
    GraphQL::ExecutionError.new('Something went wrong. Try again later')
  end

  rescue_from Post::Boom do |exception, object, arguments, context|
    firstError = GraphQL::ExecutionError.new("The first thing went wrong")
    firstError.path = context.path + ["firstError"]
    context.add_error(firstError)

    secondError = GraphQL::ExecutionError.new("The second thing went wrong")
    secondError.path = context.path + ["secondError"]
    context.add_error(secondError)
  end

end
