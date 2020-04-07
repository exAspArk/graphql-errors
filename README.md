# graphql-errors

:warning: This gem is **deprecated** in favor of the new `GraphQL::Execution::Errors` in the `graphql` gem. See more details [rmosolgo/graphql-ruby#2458](https://github.com/rmosolgo/graphql-ruby/pull/2458).

---

[![Build Status](https://travis-ci.org/exAspArk/graphql-errors.svg?branch=master)](https://travis-ci.org/exAspArk/graphql-errors)
[![Coverage Status](https://coveralls.io/repos/github/exAspArk/graphql-errors/badge.svg?branch=master)](https://coveralls.io/github/exAspArk/graphql-errors?branch=master)
[![Downloads](https://img.shields.io/gem/dt/graphql-errors.svg)](https://rubygems.org/gems/graphql-errors)
[![Latest Version](https://img.shields.io/gem/v/graphql-errors.svg)](https://rubygems.org/gems/graphql-errors)

This gem provides a simple error handling for [graphql-ruby](https://github.com/rmosolgo/graphql-ruby).

## Highlights

* Error handling for each field.
* Logic inside the `rescue_from` block, similarly to Rails.
* Catching exceptions by ancestors, e.g. `CustomError` with `rescue_from StandardError`.
* Per schema configuration.
* No dependencies.

## Usage

Once you defined your GraphQL schema:

```ruby
Schema = GraphQL::Schema.define do
  query QueryType
end
```

You can add `rescue_from` error handlers with `GraphQL::Errors`. For example:

```ruby
GraphQL::Errors.configure(Schema) do
  rescue_from ActiveRecord::RecordNotFound do |exception|
    nil
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    GraphQL::ExecutionError.new(exception.record.errors.full_messages.join("\n"))
  end

  # uses Module to handle several similar errors with single rescue_from
  rescue_from MyNetworkErrors do |_|
    GraphQL::ExecutionError.new("Don't mind, just retry the mutation")
  end

  rescue_from StandardError do |exception|
    GraphQL::ExecutionError.new("Please try to execute the query for this field later")
  end

  rescue_from CustomError do |exception, object, arguments, context|
    error = GraphQL::ExecutionError.new("Error found!")
    firstError.path = context.path + ["myError"]
    context.add_error(firstError)
  end
end
```

It'll handle exceptions raised from each resolver in the schema:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"

  field :post, PostType do
    argument :id, !types.ID
    resolve ->(obj, args, ctx) { Post.find(args['id']) } # <= will raise ActiveRecord::RecordNotFound
  end
end

Schema.execute('query { post(id: "1") { title } }') # handles the error without failing the whole query
# => { data: { post: nil } }
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-errors'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphql-errors

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/exAspArk/graphql-errors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Graphql::Errors project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/exAspArk/graphql-errors/blob/master/CODE_OF_CONDUCT.md).
