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

  it "error handling" do
    [
      ["5 + true;", "type mismatch: Objects::MInteger + Objects::MBoolean"],
      ["5 + true; 5;", "type mismatch: Objects::MInteger + Objects::MBoolean"],
      ["-true", "unknown operator: -Objects::MBoolean"],
      ["true + false;", "unknown operator: Objects::MBoolean + Objects::MBoolean"],
      [
        "true + false + true + false;",
        "unknown operator: Objects::MBoolean + Objects::MBoolean"
      ],
      [
        "5; true + false; 5",
        "unknown operator: Objects::MBoolean + Objects::MBoolean"
      ],
      [
        "if (10 > 1) { true + false; }",
        "unknown operator: Objects::MBoolean + Objects::MBoolean"
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
        "unknown operator: Objects::MBoolean + Objects::MBoolean"
      ],
      [
        "foobar",
        "identifier not found: foobar"
      ],
      [
        %("Hello" - "World"),
        "unknown operator: Objects::MString - Objects::MString"
      ],
      [
        %({"name": "Monkey"}[fn(x) {x}];),
        "unusable as a hash key: Objects::MFunction"
      ]
    ].each do |input, expected|
      error = test_eval(input)
      assert_equal expected, error.message
    end
  end

  it "let statement" do
    [
      ["let a = 5; a;", 5],
      ["let a = 5 * 5; a;", 25],
      ["let a = 5; let b = a; b;", 5],
      ["let a = 5; let b = a; let c = a + b + 5; c;", 15]
    ].each do |input, expected|
      test_integer(input, expected)
    end
  end

  it "function object" do
    input = "fn(x) { x + 2; };"
    fn = test_eval(input)
    parameters = fn.parameters
    assert_equal 1, parameters.size
    assert_equal "x", parameters[0].to_s
    assert_equal "(x + 2)", fn.body.to_s
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
      test_integer(input, expected)
    end
  end

  it "enclosing environments" do
    input = "let first = 10;
          let second = 10;
          let third = 10;

          let ourFunction = fn(first) {
            let second = 20;

            first + second + third;
          };

          ourFunction(20) + first + second;"
    test_integer_object(test_eval(input), 70)
  end

  it "string literal" do
    test_string(%("Hello World!"), "Hello World!")
  end

  it "string concatenation" do
    test_string(%("Hello" + " " + "World!"), "Hello World!")
  end

  it "builtin functions" do
    [
      [%(len("")), 0],
      [%(len("four")), 4],
      [%(len("hello world")), 11],
      ["len(1)", "argument to `len` not supported, got Objects::MInteger"],
      [%(len("one", "two")), "wrong number of arguments. got=2, want=1"],
      ["len([1, 2, 3])", 3],
      ["len([])", 0],
      ["push([], 1)", [1]],
      ["push(1, 1)", "argument to `push` must be ARRAY, got Objects::MInteger"],
      ["first([1, 2, 3])", 1],
      ["first([])", nil],
      ["first(1)", "argument to `first` must be ARRAY, got Objects::MInteger"],
      ["last([1, 2, 3])", 3],
      ["last([])", nil],
      ["last(1)", "argument to `last` must be ARRAY, got Objects::MInteger"],
      ["rest([1, 2, 3])", [2, 3]],
      ["rest([])", nil]
    ].each do |input, expected|
      evaluated = test_eval(input)
      case expected
      when NilClass
        test_nil_object(evaluated)
      when Integer
        test_integer_object(evaluated, expected)
      when String
        assert_equal expected, evaluated.message
      when Array
        assert_equal expected.size, evaluated.elements.size
        expected.each_with_index do |element, i|
          test_integer_object(evaluated.elements[i], element)
        end
      end
    end
  end

  it "array literal" do
    result = test_eval("[1, 2 * 2, 3 + 3]")
    assert_equal 3, result.elements.size
    [1, 4, 6].each_with_index do |v, i|
      test_integer_object(result.elements[i], v)
    end
  end

  it "array index expression" do
    [
      [
        "[1, 2, 3][0]",
        1
      ],
      [
        "[1, 2, 3][1]",
        2
      ],
      [
        "[1, 2, 3][2]",
        3
      ],
      [
        "let i = 0; [1][i];",
        1
      ],
      [
        "[1, 2, 3][1 + 1];",
        3
      ],
      [
        "let myArray = [1, 2, 3]; myArray[2];",
        3
      ],
      [
        "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];",
        6
      ],
      [
        "let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]",
        2
      ],
      [
        "[1, 2, 3][3]",
        nil
      ],
      [
        "[1, 2, 3][-1]",
        nil
      ]
    ].each do |input, expected|
      evaluated = test_eval(input)
      case expected
      when Integer
        test_integer_object(evaluated, expected)
      else
        test_nil_object(evaluated)
      end
    end
  end

  it "hash literals" do
    input = %(
      let two = "two";
      	{
      		"one": 10 - 9,
      		two: 1 + 1,
      		"thr" + "ee": 6 / 2,
      		4: 4,
      		true: 5,
      		false: 6
      	})
    result = test_eval(input)
    expected = {
      Objects::MString.new("one").hash_key => 1,
      Objects::MString.new("two").hash_key => 2,
      Objects::MString.new("three").hash_key => 3,
      Objects::MInteger.new(4).hash_key => 4,
      Evaluator::M_TRUE.hash_key => 5,
      Evaluator::M_FALSE.hash_key => 6
    }
    assert_equal 6, expected.size
    assert_equal result.pairs.size, expected.size
    expected.each do |expected_key, expected_value|
      pair = result.pairs[expected_key]
      assert !pair.nil?
      test_integer_object(pair.value, expected_value)
    end
  end

  it "hash index expressions" do
    [
      [%({"foo": 5, "bar": 7}["foo"]), 5],
      [%({"foo": 5}["bar"]), nil],
      [%(let key = "foo";{"foo": 5}[key]), 5],
      [%({}["foo"]), nil],
      ["{5:5}[5]", 5],
      ["{true:5}[true]", 5],
      ["{false:5}[false]", 5]
    ].each do |input, expected|
      evaluated = test_eval(input)
      case expected
      when Integer
        test_integer_object(evaluated, expected)
      else
        test_nil_object(evaluated)
      end
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
    evaluated = test_eval(input)
    test_integer_object(evaluated, 610)
  end
end
