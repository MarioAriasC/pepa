# frozen_string_literal: true

require "minitest/autorun"
require "spec_helper"
require "transpiler"
describe "Transpiler" do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  it "transpile and execute integer expressions" do
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
      transpile_and_assert(input, expected)
    end
  end

  it "transpile and execute boolean expressions" do
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
      transpile_and_assert(input, expected)
    end
  end

  it "transpile and execute bang operator" do
    [
      ["!true", false],
      ["!false", true],
      ["!5", false],
      ["!!true", true],
      ["!!false", false],
      ["!!5", true]
    ].each do |input, expected|
      transpile_and_assert(input, expected)
    end
  end
end

def transpile_and_assert(input, expected)
  program = create_program(input)
  transpiled = Transpiler.transpile(program)
  result = Kernel.eval(transpiled)
  assert_equal expected, result
end
