# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

ruby '>= 2.5.0'

# GUI
gem 'gtk3'

# IRCボットフレームワーク
gem 'mcinch', '>= 2.4'

gem 'activesupport'

group :development, :test do
  gem 'rake'
end

group :development do
  gem 'rubocop', require: false

  gem 'byebug'

  gem 'yard'
  gem 'redcarpet'
end

group :test do
  gem 'test-unit'
end
