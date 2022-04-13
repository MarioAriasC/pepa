require 'lexers'
require 'parsers'

def check_parser_errors(parser)
  errors = parser.errors
  unless errors.empty?
    raise "parser has #{errors.size} errors \n#{errors.join("\n")}"
  end
end

def create_program(input)
  lexer = Lexers::Lexer.new(input)
  parser = Parsers::Parser.new(lexer)
  program = parser.parse_program
  check_parser_errors(parser)
  program
end

def count_statements(i, program)
  assert_equal program.statements.size, i
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
