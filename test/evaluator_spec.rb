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
      test_integer(input, expected)
    end
  end

  it "eval boolean expression" do
    [
      ["true", true],
      ["false", false],
      ["1 < 2", true],
      ["1 > 2", false],
      ["1 < 1", false],
      ["1 > 1", false],
      ["1 == 1", true],
      ["1 != 1", false],
      ["1 == 2", false],
      ["1 != 2", true],
      ["true == true", true],
      ["false == false", true],
      ["true == false", false],
      ["true != false", true],
      ["false != true", true],
      ["(1 < 2) == true", true],
      ["(1 < 2) == false", false],
      ["(1 > 2) == true", false],
      ["(1 > 2) == false", true]
    ].each do |input, expected|
      test_boolean(input, expected)
    end
  end

  it "bang operator" do
    [
      ["!true", false],
      ["!false", true],
      ["!5", false],
      ["!!true", true],
      ["!!false", false],
      ["!!5", true]
    ].each do |input, expected|
      test_boolean(input, expected)
    end
  end

  it "if else expression" do
    [
      ["if (true) { 10 }", 10],
      ["if (false) { 10 }", nil],
      ["if (1) { 10 }", 10],
      ["if (1 < 2) { 10 }", 10],
      ["if (1 > 2) { 10 }", nil],
      ["if (1 > 2) { 10 } else { 20 }", 20],
      ["if (1 < 2) { 10 } else { 20 }", 10]
    ].each do |input, expected|
      evaluated = test_eval(input)
      if expected.nil?
        test_nil_object(evaluated)
      else
        test_integer_object(evaluated, expected)
      end
    end
  end

  it "return statement" do
    [
      ["return 10;", 10],
      ["return 10; 9;", 10],
      ["return 2 * 5; 9;", 10],
      ["9; return 2 * 5; 9;", 10],
      ["if (10 > 1) {
          if (10 > 1) {
            return 10;
          }

          return 1;
          }", 10],
      ["let f = fn(x) {
                return x;
                x + 10;
              };
              f(10);", 10],
      ["let f = fn(x) {
                 let result = x + 10;
                 return result;
                 return 10;
              };
              f(10);", 20]
    ].each do |input, expected|
      test_integer(input, expected)
    end
  end
end
