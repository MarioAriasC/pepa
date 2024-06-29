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

  it "if else expressions" do
    [
      ["if (true) { 10 }", 10],
      ["if (false) { 10 }", nil],
      ["if (1) { 10 }", 10],
      ["if (1 < 2) { 10 }", 10],
      ["if (1 > 2) { 10 }", nil],
      ["if (1 > 2) { 10 } else { 20 }", 20],
      ["if (1 < 2) { 10 } else { 20 }", 10]
    ].each do |input, expected|
      transpile_and_assert(input, expected)
    end
  end

  it "return statements" do
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
      transpile_and_assert(input, expected)
    end
  end

  it "error handling" do
    [
      ["5 + true;", "true can't be coerced into Integer"],
      ["5 + true; 5;", "true can't be coerced into Integer"],
      ["-true", "undefined method `-@' for true"],
      ["true + false;", "undefined method `+' for true"],
      [
        "true + false + true + false;",
        "undefined method `+' for true"
      ],
      [
        "5; true + false; 5",
        "undefined method `+' for true"
      ],
      [
        "if (10 > 1) { true + false; }",
        "undefined method `+' for true"
      ],
      [
        "
            if (10 > 1) {
              if (10 > 1) {
                return true + false;
              }

              return 1;
            }
            ",
        "undefined method `+' for true"
      ],
      [
        "foobar",
        "undefined local variable or method `foobar' for module Kernel"
      ],
      [
        %("Hello" - "World"),
        "undefined method `-' for an instance of String"
      ]
      # this is valid in Ruby, ie, having a proc as index key
      # ({"name" => "Monkey"}.freeze)[->(x) { x }]
      #       [
      #         %({"name": "Monkey"}[fn(x) {x}];),
      #         "unusable as a hash key: Objects::MFunction"
      #       ]
    ].each do |input, expected|
      transpile_and_assert(input, expected)
    end
  end

  it "let statements" do
    [
      ["let a = 5; a;", 5],
      ["let a = 5 * 5; a;", 25],
      ["let a = 5; let b = a; b;", 5],
      ["let a = 5; let b = a; let c = a + b + 5; c;", 15]
    ].each do |input, expected|
      transpile_and_assert(input, expected)
    end
  end

  it "function application" do
    [
      ["let identity = fn(x) { x; }; identity(5);", 5],
      ["let identity = fn(x) { return x; }; identity(5);", 5],
      ["let double = fn(x) { x * 2; }; double(5);", 10],
      ["let add = fn(x, y) { x + y; }; add(5, 5);", 10],
      ["let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20],
      ["fn(x) { x; }(5)", 5]
    ].each do |input, expected|
      transpile_and_assert(input, expected)
    end
  end

  it "enclosing environments" do
    input = "let first = 10;
          let second = 10;
          let THIRD = 10;

          let ourFunction = fn(first) {
            let second = 20;

            first + second + THIRD;
          };

          ourFunction(20) + first + second;"
    transpile_and_assert(input, 70)
  end

  it "string literal" do
    transpile_and_assert(%("Hello World!"), "Hello World!")
  end

  it "string concatenation" do
    transpile_and_assert(%("Hello" + " " + "World!"), "Hello World!")
  end

  it "builtin functions" do
    [
      [%(len("")), 0],
      [%(len("four")), 4],
      [%(len("hello world")), 11],
      ["len(1)", "argument to `len` not supported, got Integer"],
      [%(len("one", "two")), "wrong number of arguments (given 2, expected 1)"],
      ["len([1, 2, 3])", 3],
      ["len([])", 0],
      ["push([], 1)", [1]],
      ["push(1, 1)", "argument to `push` must be ARRAY, got Integer"],
      ["first([1, 2, 3])", 1],
      ["first([])", nil],
      ["first(1)", "argument to `first` must be ARRAY, got Integer"],
      ["last([1, 2, 3])", 3],
      ["last([])", nil],
      ["last(1)", "argument to `last` must be ARRAY, got Integer"],
      ["rest([1, 2, 3])", [2, 3]],
      ["rest([])", nil]
    ].each do |input, expected|
      transpile_and_assert(input, expected)
    end
  end

  it "recursive fibonacci" do
    input = "
let fibonacci = fn(x) {
	if (x == 0) {
		return 0;
	} else {
		if (x == 1) {
			return 1;
		} else {
			fibonacci(x - 1) + fibonacci(x - 2);
		}
	}
};
fibonacci(15);"
    transpile_and_assert(input, 610)
  end
end

def transpile_and_assert(input, expected)
  puts "--> start"
  pp input
  program = create_program(input)
  pp program
  transpiled = Transpiler.transpile(program)
  puts transpiled
  result = nil

  begin
    result = Kernel.eval(transpiled)
  rescue StandardError => e
    result = e.message
  end
  puts "--> result"
  pp result
  if expected.nil?
    assert_nil result
  else
    assert_equal expected, result
  end
end
