# Pghub::AutoAssign

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/pghub/auto_assign`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pghub-auto_assign'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pghub-auto_assign

## Usage

### Get Github Access Token
### Deploy to heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/playground-live/pghub-server/tree/auto_assign)

### Deploy manually
- mount in routes.rb

```ruby
mount Pghub::Base::Engine => 'some/path'
```

- Get github access token
- Add following settings to config/initializers/pghub.rb

```ruby
Pghub.configure do |config|
  config.github_organization = "Your organization (or user) name"
  config.github_access_token = "Your Github Access Token"
  config.num_of_assignees_per_team = { your_team_name: 1, your_team_name2: 1 }
  config.num_of_reviewers_per_team = { your_team_name: 2, your_team_name2: 2 }
end
```

### Set webhook to your repository

|||
|:-:|:-:|
|URL|heroku'sURL/github\_webhooks or heroku'sURL/some/path|
|Content-Type|application/json|
|Secret||
|event|check the following events|

#### events
- commit comment
- issue comment
- issues
- pull request
- pull request comment
- pull request review comment

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pghub-auto_assign. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pghub::AutoAssign project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pghub-auto_assign/blob/master/CODE_OF_CONDUCT.md).
