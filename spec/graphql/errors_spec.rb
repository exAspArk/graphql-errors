# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::Errors do
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
      "data" => {"posts" => [nil]},
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
      "data" => {"posts" => [nil]},
      "errors" => [
        "message" => "Something went wrong. Try again later",
        "locations" => ["line" => 1, "column" => 54],
        "path" => ["posts", 0, "description"]
      ]
    )
  end
end
