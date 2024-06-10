# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb", "test/**/*_spec.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-performance"
end

task default: %i[test rubocop]
