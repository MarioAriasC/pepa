# frozen_string_literal: true

require "minitest/autorun"
require "spec_helper"
require "objects"
describe "Evaluator" do
  it "eval integer expressions" do
    [
      ["5", 5],
      ["10", 10],
      ["-5", -5],
      ["-10", -10],
      ["5 + 5 + 5 + 5 - 10", 10],
      ["2 * 2 * 2 * 2 * 2", 32],
      ["-50 + 100 + -50", 0],
      ["5 * 2 + 10", 20],
      ["5 + 2 * 10", 25],
      ["20 + 2 * -10", 0],
      ["50 / 2 * 2 + 10", 60],
      ["2 * (5 + 10)", 30],
      ["3 * 3 * 3 + 10", 37],
      ["3 * (3 * 3) + 10", 37],
      ["(5 + 10 * 2 + 15 / 3) * 2 + -10", 50]
    ].each do |input, expected|
      evaluated = test_eval(input)
      case evaluated
      when Objects::MInteger
        assert_equal expected, evaluated.value
      else
        raise "obj is not MInteger, got #{evaluated.class}, #{evaluated}"
      end
    end
  end
end
