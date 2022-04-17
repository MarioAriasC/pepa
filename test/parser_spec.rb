# frozen_string_literal: true

require "minitest/autorun"
require "spec_helper"

describe "Parsers::Parser" do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  describe "Parser" do
    it "let statement" do
      [
        ["let x = 5;", "x", 5],
        ["let y = true;", "y", true],
        ["let foobar = y;", "foobar", "y"]
      ].each do |input, expected_identifier, expected_value|
        program = create_program(input)
        count_statements(1, program)

        statement = program.statements[0]
        test_let_statement(statement, expected_identifier)

        value = statement.value
        test_literal_expression(value, expected_value)
      end
    end

    it "return statement" do
      [
        ["return 5;", 5],
        ["return true;", true],
        ["return foobar;", "foobar"]
      ].each do |input, expected_value|
        program = create_program(input)
        count_statements(1, program)

        return_statement = program.statements[0]
        assert_equal return_statement.token_literal, "return"
        test_literal_expression(return_statement.return_value, expected_value)
      end
    end

    it "identifier expression" do
      input = "foobar"
      program = create_program(input)
      count_statements(1, program)
      identifier = program.statements[0].expression
      assert_equal identifier.value, "foobar"
      assert_equal identifier.token_literal, "foobar"
    end

    it "integer literal" do
      input = "5;"
      program = create_program(input)
      count_statements(1, program)
      literal = program.statements[0].expression
      case literal
      when Ast::IntegerLiteral
        assert_equal literal.value, 5
        assert_equal literal.token_literal, "5"
      else
        raise "expression_statement.expression? not an Integer Literal"
      end
    end

    it "parsing prefix expressions" do
      [
        ["!5;", "!", 5],
        ["-15;", "-", 15],
        ["!true", "!", true],
        ["!false", "!", false]
      ].each do |input, operator, value|
        program = create_program(input)
        count_statements(1, program)
        prefix_expression = program.statements[0].expression
        assert_equal prefix_expression.operator, operator
        test_literal_expression(prefix_expression.right, value)
      end
    end

    it "parsing infix expressions" do
      [
        ["5 + 5;", 5, "+", 5],
        ["5 - 5;", 5, "-", 5],
        ["5 * 5;", 5, "*", 5],
        ["5 / 5;", 5, "/", 5],
        ["5 > 5;", 5, ">", 5],
        ["5 < 5;", 5, "<", 5],
        ["5 == 5;", 5, "==", 5],
        ["5 != 5;", 5, "!=", 5],
        ["true == true", true, "==", true],
        ["true != false", true, "!=", false],
        ["false == false", false, "==", false]
      ].each do |input, left_value, operator, right_value|
        program = create_program(input)
        count_statements(1, program)
        expression_statement = program.statements[0]
        test_infix_expression(expression_statement.expression, left_value, operator, right_value)
      end
    end

    it "operator precedence" do
      [
        [
          "-a * b",
          "((-a) * b)"
        ],
        %w[!-a (!(-a))],
        [
          "a + b + c",
          "((a + b) + c)"
        ],
        [
          "a + b - c",
          "((a + b) - c)"
        ],
        [
          "a * b * c",
          "((a * b) * c)"
        ],
        [
          "a * b / c",
          "((a * b) / c)"
        ],
        [
          "a + b / c",
          "(a + (b / c))"
        ],
        [
          "a + b * c + d / e - f",
          "(((a + (b * c)) + (d / e)) - f)"
        ],
        [
          "3 + 4; -5 * 5",
          "(3 + 4)((-5) * 5)"
        ],
        [
          "5 > 4 == 3 < 4",
          "((5 > 4) == (3 < 4))"
        ],
        [
          "5 < 4 != 3 > 4",
          "((5 < 4) != (3 > 4))"
        ],
        [
          "3 + 4 * 5 == 3 * 1 + 4 * 5",
          "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"
        ],
        %w[true true],
        %w[false false],
        [
          "3 > 5 == false",
          "((3 > 5) == false)"
        ],
        [
          "3 < 5 == true",
          "((3 < 5) == true)"
        ],
        [
          "1 + (2 + 3) + 4",
          "((1 + (2 + 3)) + 4)"
        ],
        [
          "(5 + 5) * 2",
          "((5 + 5) * 2)"
        ],
        [
          "2 / (5 + 5)",
          "(2 / (5 + 5))"
        ],
        [
          "(5 + 5) * 2 * (5 + 5)",
          "(((5 + 5) * 2) * (5 + 5))"
        ],
        [
          "-(5 + 5)",
          "(-(5 + 5))"
        ],
        [
          "!(true == true)",
          "(!(true == true))"
        ],
        [
          "a + add(b * c) + d",
          "((a + add((b * c))) + d)"
        ],
        [
          "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
          "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
        ],
        [
          "add(a + b + c * d / f + g)",
          "add((((a + b) + ((c * d) / f)) + g))"
        ],
        [
          "a * [1, 2, 3, 4][b * c] * d",
          "((a * ([1, 2, 3, 4][(b * c)])) * d)"
        ],
        [
          "add(a * b[2], b[1], 2 * [1, 2][1])",
          "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
        ]
      ].each do |input, expected|
        program = create_program(input)
        assert_equal expected, program.to_s
      end
    end

    it "boolean expressions" do
      [
        ["true", true],
        ["false", false]
      ].each do |input, expected_boolean|
        program = create_program(input)
        count_statements(1, program)
        bool_literal = program.statements[0].expression
        assert_equal expected_boolean, bool_literal.value
      end
    end

    it "if expression" do
      input = "if (x < y) { x }"
      program = create_program(input)
      count_statements(1, program)
      if_expression = program.statements[0].expression
      test_infix_expression(if_expression.condition, "x", "<", "y")
      test_branch(if_expression.consequence, "x")
    end

    it "if else expression" do
      input = "if (x < y) { x } else { y }"
      program = create_program(input)
      count_statements(1, program)
      if_expression = program.statements[0].expression
      test_infix_expression(if_expression.condition, "x", "<", "y")
      test_branch(if_expression.consequence, "x")
      test_branch(if_expression.alternative, "y")
    end

    it "function literal parsing" do
      input = "fn(x, y) { x + y;}"
      program = create_program(input)
      function_literal = program.statements[0].expression
      parameters = function_literal.parameters
      test_literal_expression(parameters[0], "x")
      test_literal_expression(parameters[1], "y")
      body = function_literal.body
      statements = body.statements
      assert_equal 1, statements.size
      test_infix_expression(statements[0].expression, "x", "+", "y")
    end

    it "function parameter parsing" do
      [
        ["fn () {}", []],
        ["fn (x) {}", ["x"]],
        ["fn (x, y, z) {}", %w[x y z]]
      ].each do |input, expected_params|
        program = create_program(input)
        function_literal = program.statements[0].expression
        parameters = function_literal.parameters
        assert_equal expected_params.size, parameters.size
        expected_params.each_with_index do |expected_param, i|
          test_literal_expression(parameters[i], expected_param)
        end
      end
    end

    it "call expression parsing" do
      input = "add(1, 2 * 3, 4+5)"
      program = create_program(input)
      count_statements(1, program)
      call_expression = program.statements[0].expression
      test_identifier(call_expression.function, "add")
      arguments = call_expression.arguments
      test_literal_expression(arguments[0], 1)
      test_infix_expression(arguments[1], 2, "*", 3)
      test_infix_expression(arguments[2], 4, "+", 5)
    end

    it "string literal expression" do
      input = %("hello world";)
      program = create_program(input)
      count_statements(1, program)
      assert_equal "hello world", program.statements[0].expression.value
    end

    it "parsing literal array" do
      input = "[1, 2 * 2, 3 + 3]"
      program = create_program(input)
      elements = program.statements[0].expression.elements
      test_literal_expression(elements[0], 1)
      test_infix_expression(elements[1], 2, "*", 2)
      test_infix_expression(elements[2], 3, "+", 3)
    end

    it "parsing index expression" do
      input = "myArray[1 + 1]"
      program = create_program(input)
      index_expression = program.statements[0].expression
      test_identifier(index_expression.left, "myArray")
      test_infix_expression(index_expression.index, 1, "+", 1)
    end

    it "hash literal string keys" do
      input = %({"one": 1, "two": 2, "three": 3})
      program = create_program(input)
      hash_literal = program.statements[0].expression
      assert_equal 3, hash_literal.pairs.size
      expected = { "one" => 1, "two" => 2, "three" => 3 }
      hash_literal.pairs.each do |key, value|
        expected_value = expected[key.to_s]
        test_literal_expression(value, expected_value)
      end
    end
  end
end
