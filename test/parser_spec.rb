require 'minitest/autorun'
require 'spec_helper'

describe 'Parsers::Parser' do
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
        ["let foobar = y;", "foobar", "y"],
      ].each do |input, expected_identifier, expected_value|
        program = create_program(input)
        count_statements(1, program)

        statement = program.statements[0]
        test_let_statement(statement, expected_identifier)

        value = statement.value
        test_literal_expression(value, expected_value)
      end
    end
  end
end
