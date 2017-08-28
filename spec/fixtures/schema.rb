# frozen_string_literal: true

PostType = GraphQL::ObjectType.define do
  name "Post"
  field :id, !types.ID
  field :title, !types.String
  field :description, !types.String, resolve: ->(_obj, _args, _ctx) { raise Post::Oops.new('Can not parse the description') }
  field :category, !types.String, resolve: ->(_obj, _args, _ctx) { raise Post::Invalid.new('Post is invalid') }
end

QueryType = GraphQL::ObjectType.define do
  name "Query"
  field :posts, !types[PostType] do
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

  rescue_from StandardError do |exception|
    GraphQL::ExecutionError.new('Something went wrong. Try again later')
  end
end
