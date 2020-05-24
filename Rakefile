# frozen_string_literal: true

require 'rake/testtask'
require 'yard'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.libs << 'vendor/bcdice/src'

  t.test_files = FileList['test/**/*_test.rb']
end

YARD::Rake::YardocTask.new do |t|
  t.files = [
    'lib/**/*.rb',
    'exe/**/*.rb',
    '-',
    'README.md',
    'master_commands.md',
  ]
  t.options = [
    '--protected',
    '--private',
    '--markup-provider=redcarpet',
    '--markup=markdown',
  ]
end

task default: :test
