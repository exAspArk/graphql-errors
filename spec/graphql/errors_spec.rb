# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::Errors do
  describe '.configure' do
    it 'raises an exception if it was called without a block' do
      expect {
        GraphQL::Errors.configure(Schema)
      }.to raise_error(GraphQL::Errors::EmptyConfigurationError)
    end
  end

  describe '#rescue_from' do
    before do
      module NetworkErrors
        extend self

        ERRORS = [Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EFAULT,].freeze

        def ===(error)
          ERRORS.any? { |error_class| error_class === error }
        end
      end
    end

    it 'doesn\'t raise an exception if the object which was passed is a module' do
      expect {
        GraphQL::Errors.configure(Schema) { rescue_from(NetworkErrors) { |e| puts e.inspect } }
      }.not_to raise_error
    end

    it 'raises an exception if the object which was passed is not a module' do
      expect {
        GraphQL::Errors.configure(Schema) { rescue_from(1) { |e| puts e.inspect } }
      }.to raise_error(GraphQL::Errors::NotRescuableError)
    end

    it 'raises an exception if there the block was not specified' do
      expect {
        GraphQL::Errors.configure(Schema) { rescue_from(StandardError) }
      }.to raise_error(GraphQL::Errors::EmptyRescueError)
    end
  end

  context 'GraphQL integration' do
    it 'works without errors' do
      query = "query($userId: ID!) { posts(userId: $userId) { id title } }"

      result = Schema.execute(query, variables: {'userId' => 1})

      expect(result).to eq("data" => {"posts" => [{"id" => "1", "title" => "Post Title"}]})
    end

    it 'rescues errors from BatchLoader' do
      query = "query($id: ID!) { lazyPost(id: $id) { id title } }"

      result = Schema.execute(query, variables: {'id' => 1})

      expect(result).to eq(
        "data" => nil,
        "errors" => [
          "message" => "Something went wrong. Try again later",
          "locations" => ["line" => 1, "column" => 19],
          "path" => ["lazyPost"]
        ]
      )
    end

    it 'rescues the first Post::NotFound error in the list' do
      query = "query($id: ID!) { post(id: $id) { id title } }"

      result = Schema.execute(query, variables: {'id' => 1})

      expect(result).to eq(
        "data" => nil,
        "errors" => [
          "message" => "Post is invalid",
          "locations" => ["line" => 1, "column" => 19],
          "path" => ["post"]
        ]
      )
    end

    it 'rescues Post::NotFound error with mutation' do
      query = "mutation($postId: ID!) { createComment(input: { postId: $postId }) { post { id } } }"

      result = Schema.execute(query, variables: {'postId' => 1})

      expect(result).to eq(
        "data" => {
          "createComment" => nil
        },
        "errors" => [
          "message" => "Post is invalid",
          "locations" => ["line" => 1, "column" => 26],
          "path" => ["createComment"]
        ]
      )
    end

    it 'rescues the second Post::Invalid error in the list' do
      query = "query($userId: ID!) { posts(userId: $userId) { id category } }"

      result = Schema.execute(query, variables: {'userId' => 1})

      expect(result).to eq(
        "data" => nil,
        "errors" => [
          "message" => "Post is invalid",
          "locations" => ["line" => 1, "column" => 51],
          "path" => ["posts", 0, "category"]
        ]
      )
    end

    it 'handles the inherited Post::WorksOnMyMachine error by rescuing Post::Oops' do
      query = "query($userId: ID!) { posts(userId: $userId) { id description } }"

      result = Schema.execute(query, variables: {'userId' => 1})

      expect(result).to eq(
        "data" => nil,
        "errors" => [
          "message" => "Something went wrong. Try again later",
          "locations" => ["line" => 1, "column" => 51],
          "path" => ["posts", 0, "description"]
        ]
      )
    end

    it 'handles the multiple errors in context by rescuing Post::Boom' do
      query = "query($userId: ID!) { posts(userId: $userId) { author } }"

      result = Schema.execute(query, variables: {'userId' => 1})

      expect(result['errors'].size).to eq(3)

      expect(result['errors'].first).to eq(
        "message" => "The first thing went wrong",
        "locations" => ["line" => 1, "column" => 48],
        "path" => ["posts", 0, "author", "firstError"]
      )
    end

    it 'raises the error if there is no handler' do
      query = "query($userId: ID!) { posts(userId: $userId) { id language } }"

      expect {
        Schema.execute(query, variables: {'userId' => 1})
      }.to raise_error(RuntimeError, 'Request failed')
    end
  end
end
