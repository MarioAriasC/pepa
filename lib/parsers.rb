# frozen_string_literal: true

require_relative "tokens"
require_relative "ast"

module Parsers
  module Precedence
    LOWEST = 0
    EQUALS = 1
    LESS_GREATER = 2
    SUM = 3
    PRODUCT = 4
    PREFIX = 5
    CALL = 6
    INDEX = 7
  end

  PRECEDENCES = {
    Tokens::EQ => Precedence::EQUALS,
    Tokens::NOT_EQ => Precedence::EQUALS,
    Tokens::LT => Precedence::LESS_GREATER,
    Tokens::GT => Precedence::LESS_GREATER,
    Tokens::PLUS => Precedence::SUM,
    Tokens::MINUS => Precedence::SUM,
    Tokens::SLASH => Precedence::PRODUCT,
    Tokens::ASTERISK => Precedence::PRODUCT,
    Tokens::LPAREN => Precedence::CALL,
    Tokens::LBRACKET => Precedence::INDEX
  }.freeze

  class Parser
    attr_reader :errors

    def initialize(lexer)
      @lexer = lexer
      @cur_token = Tokens::Token.new(Tokens::ILLEGAL, "")
      @peek_token = Tokens::Token.new(Tokens::ILLEGAL, "")
      @errors = []
      @m_parse_integer_literal = method(:parse_integer_literal).freeze
      @m_parse_boolean_literal = method(:parse_boolean_literal).freeze
      @m_parse_identifier = method(:parse_identifier).freeze
      @m_parse_prefix_expression = method(:parse_prefix_expression).freeze
      @m_parse_prefix_expression = method(:parse_prefix_expression).freeze
      @m_parse_group_expression = method(:parse_group_expression).freeze
      @m_parse_array_literal = method(:parse_array_literal).freeze
      @m_parse_if_expression = method(:parse_if_expression).freeze
      @m_parse_function_literal = method(:parse_function_literal).freeze
      @m_parse_string_literal = method(:parse_string_literal).freeze
      @m_parse_hash_literal = method(:parse_hash_literal).freeze
      @m_parse_infix_expression = method(:parse_infix_expression).freeze
      @m_parse_call_expression = method(:parse_call_expression).freeze
      @m_parse_index_expression = method(:parse_index_expression).freeze
      next_token
      next_token
    end

    def prefix_parsers(token_type)
      case token_type
      when Tokens::INT
        @m_parse_integer_literal
      when Tokens::TRUE
        @m_parse_boolean_literal
      when Tokens::FALSE
        @m_parse_boolean_literal
      when Tokens::IDENT
        @m_parse_identifier
      when Tokens::BANG
        @m_parse_prefix_expression
      when Tokens::MINUS
        @m_parse_prefix_expression
      when Tokens::LPAREN
        @m_parse_group_expression
      when Tokens::LBRACKET
        @m_parse_array_literal
      when Tokens::IF
        @m_parse_if_expression
      when Tokens::FUNCTION
        @m_parse_function_literal
      when Tokens::STRING
        @m_parse_string_literal
      when Tokens::LBRACE
        @m_parse_hash_literal
      end
    end

    def infix_parsers(token_type)
      case token_type
      when Tokens::PLUS
        @m_parse_infix_expression
      when Tokens::MINUS
        @m_parse_infix_expression
      when Tokens::SLASH
        @m_parse_infix_expression
      when Tokens::ASTERISK
        @m_parse_infix_expression
      when Tokens::EQ
        @m_parse_infix_expression
      when Tokens::NOT_EQ
        @m_parse_infix_expression
      when Tokens::LT
        @m_parse_infix_expression
      when Tokens::GT
        @m_parse_infix_expression
      when Tokens::LPAREN
        @m_parse_call_expression
      when Tokens::LBRACKET
        @m_parse_index_expression
      end
    end

    def parse_program
      statements = []
      while @cur_token.type != Tokens::EOF
        statement = parse_statement
        statements << statement if statement
        next_token
      end
      Ast::Program.new(statements)
    end

    private

    def parse_string_literal
      Ast::StringLiteral.new(@cur_token, @cur_token.literal)
    end

    def next_token
      @cur_token = @peek_token
      @peek_token = @lexer.next_token
    end

    def parse_let_statement
      token = @cur_token
      return nil unless expect_peek?(Tokens::IDENT)

      name = Ast::Identifier.new(@cur_token, @cur_token.literal)
      return nil unless expect_peek?(Tokens::ASSIGN)

      next_token
      value = parse_expression(Precedence::LOWEST)

      value.name = name if value.is_a? Ast::FunctionLiteral

      next_token if peek_token_is?(Tokens::SEMICOLON)
      Ast::LetStatement.new(token, name, value)
    end

    def parse_statement
      case @cur_token.type
      when Tokens::LET
        parse_let_statement
      when Tokens::RETURN
        parse_return_statement
      else
        parse_expression_statement
      end
    end

    def parse_expression(precedence)
      prefix = prefix_parsers(@cur_token.type)
      if prefix.nil?
        no_prefix_parse_error(@cur_token.type)
        return nil
      end
      left = prefix.call
      while !peek_token_is?(Tokens::SEMICOLON) && precedence < peek_precedence
        infix = infix_parsers(@peek_token.type)
        return left if infix.nil?

        next_token
        left = infix.call(left)
      end
      left
    end

    def parse_expression_statement
      token = @cur_token
      expression = parse_expression(Precedence::LOWEST)
      next_token if peek_token_is?(Tokens::SEMICOLON)
      Ast::ExpressionStatement.new(token, expression)
    end

    def parse_return_statement
      token = @cur_token
      next_token
      return_value = parse_expression(Precedence::LOWEST)
      next_token while peek_token_is?(Tokens::SEMICOLON)
      Ast::ReturnStatement.new(token, return_value)
    end

    def parse_integer_literal
      token = @cur_token
      value = token.literal.to_i
      Ast::IntegerLiteral.new(token, value)
    end

    def parse_boolean_literal
      Ast::BooleanLiteral.new(@cur_token, cur_token_is(Tokens::TRUE))
    end

    def parse_identifier
      Ast::Identifier.new(@cur_token, @cur_token.literal)
    end

    def parse_prefix_expression
      token = @cur_token
      operator = token.literal
      next_token
      right = parse_expression(Precedence::PREFIX)
      Ast::PrefixExpression.new(token, operator, right)
    end

    def parse_infix_expression(left)
      token = @cur_token
      operator = token.literal
      precedence = cur_precedence
      next_token
      right = parse_expression(precedence)
      Ast::InfixExpression.new(token, left, operator, right)
    end

    def parse_group_expression
      next_token
      exp = parse_expression(Precedence::LOWEST)
      return nil unless expect_peek?(Tokens::RPAREN)

      exp
    end

    def parse_call_expression(expression)
      token = @cur_token
      arguments = parse_expression_list(Tokens::RPAREN)
      Ast::CallExpression.new(token, expression, arguments)
    end

    def parse_expression_list(end_type)
      arguments = []
      if peek_token_is? end_type
        next_token
        return arguments
      end

      next_token
      arguments << parse_expression(Precedence::LOWEST)
      while peek_token_is? Tokens::COMMA
        next_token
        next_token

        arguments << parse_expression(Precedence::LOWEST)
      end
      return nil unless expect_peek?(end_type)

      arguments
    end

    def parse_array_literal
      token = @cur_token
      Ast::ArrayLiteral.new(token, parse_expression_list(Tokens::RBRACKET))
    end

    def parse_index_expression(left)
      token = @cur_token
      next_token

      index = parse_expression(Precedence::LOWEST)
      return nil unless expect_peek?(Tokens::RBRACKET)

      Ast::IndexExpression.new(token, left, index)
    end

    def parse_if_expression
      token = @cur_token

      return nil unless expect_peek?(Tokens::LPAREN)

      next_token
      condition = parse_expression(Precedence::LOWEST)
      return nil unless expect_peek?(Tokens::RPAREN)

      return nil unless expect_peek?(Tokens::LBRACE)

      consequence = parse_block_statement

      alternative = if peek_token_is?(Tokens::ELSE)
                      next_token
                      return nil unless expect_peek?(Tokens::LBRACE)

                      parse_block_statement
                    end

      Ast::IfExpression.new(token, condition, consequence, alternative)
    end

    def parse_block_statement
      token = @cur_token
      statements = []
      next_token

      while !cur_token_is(Tokens::RBRACE) && !cur_token_is(Tokens::EOF)
        statement = parse_statement
        statements << statement unless statement.nil?

        next_token
      end

      Ast::BlockStatement.new(token, statements)
    end

    def parse_function_literal
      token = @cur_token
      return nil unless expect_peek?(Tokens::LPAREN)

      parameters = parse_function_parameters
      return nil unless expect_peek?(Tokens::LBRACE)

      body = parse_block_statement
      Ast::FunctionLiteral.new(token, parameters, body)
    end

    def parse_function_parameters
      parameters = []
      if peek_token_is?(Tokens::RPAREN)
        next_token
        return parameters
      end

      next_token
      token = @cur_token
      parameters << Ast::Identifier.new(token, token.literal)

      while peek_token_is?(Tokens::COMMA)
        next_token
        next_token
        inner_token = @cur_token
        parameters << Ast::Identifier.new(inner_token, inner_token.literal)
      end

      return nil unless expect_peek?(Tokens::RPAREN)

      parameters
    end

    def parse_hash_literal
      token = @cur_token
      pairs = {}
      until peek_token_is?(Tokens::RBRACE)
        next_token
        key = parse_expression(Precedence::LOWEST)
        return nil unless expect_peek?(Tokens::COLON)

        next_token
        value = parse_expression(Precedence::LOWEST)
        pairs[key] = value

        return nil if !peek_token_is?(Tokens::RBRACE) && !expect_peek?(Tokens::COMMA)

      end

      return nil unless expect_peek?(Tokens::RBRACE)

      Ast::HashLiteral.new(token, pairs)
    end

    def expect_peek?(token_type)
      if peek_token_is?(token_type)
        next_token
        true
      else
        peek_error(token_type)
        false
      end
    end

    def peek_token_is?(token_type)
      @peek_token.type == token_type
    end

    def no_prefix_parse_error(token_type)
      @errors << "no prefix parsers for '#{token_type}' function"
    end

    def peek_error(token_type)
      @errors << "Expected next token to be #{token_type}, got #{@peek_token.type} instead"
    end

    def cur_token_is(token_type)
      @cur_token.type == token_type
    end

    def peek_precedence
      find_precedence(@peek_token.type)
    end

    def find_precedence(token_type)
      PRECEDENCES[token_type].or_else(Precedence::LOWEST)
    end

    def cur_precedence
      find_precedence(@cur_token.type)
    end
  end
end
