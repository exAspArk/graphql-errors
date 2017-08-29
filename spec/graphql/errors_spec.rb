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
    it 'raises an exception if the object which was passed is not a class' do
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
      query = "query($user_id: ID!) { posts(user_id: $user_id) { id title } }"

      result = Schema.execute(query, variables: {'user_id' => 1})

      expect(result).to eq("data" => {"posts" => [{"id" => "1", "title" => "Post Title"}]})
    end

    it 'rescues the first error in the list' do
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

    it 'rescues the second error in the list' do
      query = "query($user_id: ID!) { posts(user_id: $user_id) { id category } }"

      result = Schema.execute(query, variables: {'user_id' => 1})

      expect(result).to eq(
        "data" => nil,
        "errors" => [
          "message" => "Post is invalid",
          "locations" => ["line" => 1, "column" => 54],
          "path" => ["posts", 0, "category"]
        ]
      )
    end

    it 'rescues the standard error' do
      query = "query($user_id: ID!) { posts(user_id: $user_id) { id description } }"

      result = Schema.execute(query, variables: {'user_id' => 1})

      expect(result).to eq(
        "data" => nil,
        "errors" => [
          "message" => "Something went wrong. Try again later",
          "locations" => ["line" => 1, "column" => 54],
          "path" => ["posts", 0, "description"]
        ]
      )
    end
  end
end
