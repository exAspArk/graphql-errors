# frozen_string_literal: true

require "spec_helper"

RSpec.describe GraphQL::Errors do
  it 'works without errors' do
    query = "query($user_id: ID!) { posts(user_id: $user_id) { id title } }"

    result = Schema.execute(query, variables: {'user_id' => 1})

    expect(result).to eq({"data" => {"posts" => [{"id" => "1", "title" => "Post Title"}]}})
  end
end
