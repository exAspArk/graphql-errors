# graphql-errors

[![Build Status](https://travis-ci.org/exAspArk/graphql-errors.svg?branch=master)](https://travis-ci.org/exAspArk/graphql-errors)
[![Coverage Status](https://coveralls.io/repos/github/exAspArk/graphql-errors/badge.svg?branch=master)](https://coveralls.io/github/exAspArk/graphql-errors?branch=master)
[![Code Climate](https://img.shields.io/codeclimate/github/exAspArk/graphql-errors.svg)](https://codeclimate.com/github/exAspArk/graphql-errors)
[![Downloads](https://img.shields.io/gem/dt/graphql-errors.svg)](https://rubygems.org/gems/graphql-errors)
[![Latest Version](https://img.shields.io/gem/v/graphql-errors.svg)](https://rubygems.org/gems/graphql-errors)

This gem provides a simple error handling for [graphql-ruby](https://github.com/rmosolgo/graphql-ruby).

<a href="https://www.universe.com/" target="_blank" rel="noopener noreferrer">
  <img src="images/universe.png" height="41" width="153" alt="Sponsored by Universe" style="max-width:100%;">
</a>

## Usage

Once you defined your GraphQL schema:

```ruby
Schema = GraphQL::Schema.define do
  query QueryType
end
```

You can add error handlers with `GraphQL::Errors`. For example:

```ruby
GraphQL::Errors.configure(Schema) do
  rescue_from ActiveRecord::RecordNotFound do |exception|
    nil
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    GraphQL::ExecutionError.new(exception.record.errors.full_messages.join("\n"))
  end

  rescue_from StandardError do |exception|
    Notify.about(exception)
    GraphQL::ExecutionError.new("Please try to execute the query for this field later")
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
