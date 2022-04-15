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
  end
end
