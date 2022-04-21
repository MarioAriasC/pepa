# frozen_string_literal: true

require "lexers"
require "parsers"
require "evaluator"

def check_parser_errors(parser)
  errors = parser.errors
  raise "parser has #{errors.size} errors \n#{errors.join("\n")}" unless errors.empty?
end

def create_program(input)
  lexer = Lexers::Lexer.new(input)
  parser = Parsers::Parser.new(lexer)
  program = parser.parse_program
  check_parser_errors(parser)
  program
end

def count_statements(count, program)
  assert_equal count, program.statements.size
end

def test_let_statement(statement, expected_identifier)
  assert_equal statement.token_literal, "let"
  name = statement.name
  assert_equal name.value, expected_identifier
  assert_equal name.token_literal, expected_identifier
end

def test_literal(expected_value, value)
  assert_equal value.value, expected_value
  assert_equal value.token_literal, expected_value.to_s
end

def test_literal_expression(value, expected_value)
  case expected_value
  when Integer
    test_literal(expected_value, value)
  when true
    test_literal(expected_value, value)
  when false
    test_literal(expected_value, value)
  when String
    assert_equal value.value, expected_value
    assert_equal value.token_literal, expected_value
  else
    raise "type of value not handled. got=#{expected_value}"
  end
end

def test_infix_expression(expression, left_value, operator, right_value)
  test_literal_expression(expression.left, left_value)
  assert_equal expression.operator, operator
  test_literal_expression(expression.right, right_value)
end

def test_identifier(expression, string)
  assert_equal string, expression.value
  assert_equal string, expression.token_literal
end

def test_branch(branch, value)
  statements = branch.statements
  assert_equal 1, statements.size
  test_identifier(statements[0].expression, value)
end

def test_eval(input)
  program = create_program(input)
  Evaluator.evaluate(program, Evaluator::Environment.new)
end

def test_integer(input, expected)
  evaluated = test_eval(input)
  test_integer_object(evaluated, expected)
end

def test_integer_object(evaluated, expected)
  case evaluated
  when Objects::MInteger
    assert_equal expected, evaluated.value
  else
    raise "obj is not MInteger, got #{evaluated.class}, #{evaluated}"
  end
end

def test_boolean(input, expected)
  # p input
  evaluated = test_eval(input)
  case evaluated
  when Objects::MBoolean
    assert_equal expected, evaluated.value
  else
    raise "obj is not MBoolean, got #{evaluated.class}, #{evaluated}"
  end
end

def test_nil_object(obj)
  assert_equal Objects::M_NULL, obj
end
