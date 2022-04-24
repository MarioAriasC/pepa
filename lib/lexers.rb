# frozen_string_literal: true

require_relative "tokens"

module Lexers
  WHITE_SPACES = [" ", "\t", "\n", "\r"].freeze
  ZERO = ""

  class Lexer
    def initialize(input)
      @position = 0
      @read_position = 0
      @ch = ZERO
      @input = input
      read_char
    end

    def next_token
      skip_whitespace
      r = nil
      case @ch
      when "="
        r = ends_with_equal(Tokens::ASSIGN, Tokens::EQ)
      when ";"
        r = token(Tokens::SEMICOLON)
      when "("
        r = token(Tokens::LPAREN)
      when ","
        r = token(Tokens::COMMA)
      when ")"
        r = token(Tokens::RPAREN)
      when "{"
        r = token(Tokens::LBRACE)
      when "+"
        r = token(Tokens::PLUS)
      when "}"
        r = token(Tokens::RBRACE)
      when "!"
        r = ends_with_equal(Tokens::BANG, Tokens::NOT_EQ, duplicate_chars: false)
      when "-"
        r = token(Tokens::MINUS)
      when "/"
        r = token(Tokens::SLASH)
      when "*"
        r = token(Tokens::ASTERISK)
      when "<"
        r = token(Tokens::LT)
      when ">"
        r = token(Tokens::GT)
      when "\""
        r = Tokens::Token.new(Tokens::STRING, read_string)
      when "["
        r = token(Tokens::LBRACKET)
      when "]"
        r = token(Tokens::RBRACKET)
      when ":"
        r = token(Tokens::COLON)
      when ZERO
        r = token(Tokens::EOF)
      else
        case
        when @ch.identifier?
          identifier = read_identifier
          return Tokens::Token.new(identifier.lookup_ident, identifier)
        when @ch.number?
          return Tokens::Token.new(Tokens::INT, read_number)
        else
          r = Tokens::Token.new(Tokens::ILLEGAL, @ch)
        end
      end
      read_char
      r
    end

    private

    def read_string
      start = @position + 1
      loop do
        read_char
        ch = @ch
        break if ["\"", ZERO].include?(ch)
      end
      @input[start..(@position - 1)]
    end

    def read_value(&block)
      current_position = @position
      read_char while block.call @ch
      @input[current_position..(@position - 1)]
    end

    def read_identifier
      read_value(&:identifier?)
    end

    def read_number
      read_value(&:number?)
    end

    def ends_with_equal(one_char, two_chars, duplicate_chars: true)
      if peak_char == "="
        current_char = @ch
        read_char
        value = if duplicate_chars
                  "#{current_char}#{current_char}"
                else
                  "#{current_char}#{@ch}"
                end
        Tokens::Token.new(two_chars, value)
      else
        token(one_char)
      end
    end

    def token(token_type)
      Tokens::Token.new(token_type, @ch)
    end

    def skip_whitespace
      read_char while WHITE_SPACES.any? { |wp| wp == @ch }
    end

    def read_char
      @ch = peak_char
      @position = @read_position
      @read_position += 1
    end

    def peak_char
      if @read_position >= @input.length
        ZERO
      else
        @input[@read_position]
      end
    end
  end
end

class String
  def identifier?
    letter? || self == "_"
  end

  def letter?
    if length > 1
      false
    else
      match(/[A-Za-z]/) ? true : false
    end
  end

  def number?
    self =~ /\A\d+\Z/
  end
end
