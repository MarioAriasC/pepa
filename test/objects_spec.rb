# frozen_string_literal: true

require "minitest/autorun"
require "objects"

describe "Objects" do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  it "string hash key" do
    hello1 = Objects::MString.new("Hello World")
    hello2 = Objects::MString.new("Hello World")
    diff1 = Objects::MString.new("My name is johnny")
    diff2 = Objects::MString.new("My name is johnny")
    assert_equal hello2.hash_key, hello1.hash_key

    assert_equal diff2.hash_key, diff1.hash_key
    assert diff2.hash_key != hello1.hash_key
  end
end
