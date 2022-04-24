# frozen_string_literal: true

module Tokens
  # TokenType
  class TokenType
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def eql?(other)
      @value == other.value
    end

    def to_s
      @value
    end
  end

  ILLEGAL = TokenType.new("ILLEGAL")
  EOF = TokenType.new("EOF")
  ASSIGN = TokenType.new("=")
  EQ = TokenType.new("==")
  NOT_EQ = TokenType.new("!=")
  IDENT = TokenType.new("IDENT")
  INT = TokenType.new("INT")

  PLUS = TokenType.new("+")
  COMMA = TokenType.new(",")
  SEMICOLON = TokenType.new(";")
  COLON = TokenType.new(":")
  MINUS = TokenType.new("-")
  BANG = TokenType.new("!")
  SLASH = TokenType.new("/")
  ASTERISK = TokenType.new("*")

  LT = TokenType.new("<")
  GT = TokenType.new(">")

  LPAREN = TokenType.new("(")
  RPAREN = TokenType.new(")")
  LBRACE = TokenType.new("{")
  RBRACE = TokenType.new("}")
  LBRACKET = TokenType.new("[")
  RBRACKET = TokenType.new("]")

  FUNCTION = TokenType.new("FUNCTION")
  LET = TokenType.new("LET")
  TRUE = TokenType.new("TRUE")
  FALSE = TokenType.new("FALSE")
  IF = TokenType.new("IF")
  ELSE = TokenType.new("ELSE")
  RETURN = TokenType.new("RETURN")
  STRING = TokenType.new("STRING")

  KEYBOARDS = {
    "fn" => FUNCTION,
    "let" => LET,
    "true" => TRUE,
    "false" => FALSE,
    "if" => IF,
    "else" => ELSE,
    "return" => RETURN
  }.freeze

  class Token
    attr_reader :literal, :type

    def initialize(type, literal)
      @type = type
      @literal = literal
    end
  end
end

class String
  def lookup_ident
    # puts "lookup_ident = '#{self}'"
    token = Tokens::KEYBOARDS[self]
    token || Tokens::IDENT
  end
end
