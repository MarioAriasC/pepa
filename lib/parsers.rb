require 'tokens'
require 'ast'

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
    Tokens::LBRACKET => Precedence::INDEX,
  }

  class Parser
    attr_reader :errors

    def initialize(lexer)
      @lexer = lexer
      @cur_token = Tokens::Token.new(Tokens::ILLEGAL, "")
      @peek_token = Tokens::Token.new(Tokens::ILLEGAL, "")
      @errors = []

      @prefix_parsers = {
        Tokens::INT => method(:parse_integer_literal),
        Tokens::TRUE => method(:parse_boolean_literal),
        Tokens::FALSE => method(:parse_boolean_literal),
        Tokens::IDENT => method(:parse_identifier),
      }
      next_token
      next_token
    end

    def parse_program
      statements = []
      while @cur_token.type != Tokens::EOF
        statement = parse_statement
        if statement
          statements << statement
        end
        next_token
      end
      Ast::Program.new(statements)
    end

    private

    def next_token
      @cur_token = @peek_token
      @peek_token = @lexer.next_token
    end

    def parse_let_statement
      token = @cur_token
      unless expect_peek?(Tokens::IDENT)
        return nil
      end
      name = Ast::Identifier.new(@cur_token, @cur_token.literal)
      unless expect_peek?(Tokens::ASSIGN)
        return nil
      end
      next_token
      value = parse_expression(Precedence::LOWEST)
      if peek_token_is?(Tokens::SEMICOLON)
        next_token
      end
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
      prefix = @prefix_parsers[@cur_token.type]
      if prefix == nil
        no_prefix_parse_error(@cur_token.type)
        return nil
      end
      left = prefix.call
      while !peek_token_is?(Tokens::SEMICOLON) && precedence < peek_precedence
        infix = @infix_parsers[@peek_token.type]
        if infix == nil
          return left
        end
        next_token
        left = infix.call(left)
      end
      left
    end

    def parse_expression_statement
      token = @cur_token
      expression = parse_expression(Precedence::LOWEST)
      if peek_token_is?(Tokens::SEMICOLON)
        next_token
      end
      Ast::ExpressionStatement.new(token, expression)
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

    def expect_peek?(token_type)
      if peek_token_is?(token_type)
        next_token
        true
      else
        peek_error(type)
        false
      end
    end

    def peek_token_is?(token_type)
      @peek_token.type == token_type
    end

    def no_prefix_parse_error(token_type)
      @errors << "no prefix parsers for '#{token_type}' function"
    end

    def cur_token_is(token_type)
      @cur_token.type == token_type
    end
  end
end
