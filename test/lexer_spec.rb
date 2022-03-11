# frozen_string_literal: true

require "minitest/autorun"
require "lexers"
require "tokens"

describe "Lexers::Lexer" do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  describe "String" do
    it "knows if is an identifier" do
      assert_equal false, " ".identifier?
    end
  end

  describe "Lexer" do
    it "validate lexer" do
      code = <<END
    let five = 5;
    let ten = 10;

    let add = fn(x, y) {
        x + y;
    }

    let result = add(five, ten);
    !-/*5;
    5 < 10 > 5;

    if (5 < 10) {
        return true;
    } else {
        return false;
    }

    10 == 10;
    10 != 9;
    "foobar"
    "foo bar"
    [1,2];
    {"foo":"bar"}
END
      lexer = Lexers::Lexer.new(code)
      [
        [Tokens::LET, "let"],
        [Tokens::IDENT, "five"],
        [Tokens::ASSIGN, "="],
        [Tokens::INT, "5"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::LET, "let"],
        [Tokens::IDENT, "ten"],
        [Tokens::ASSIGN, "="],
        [Tokens::INT, "10"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::LET, "let"],
        [Tokens::IDENT, "add"],
        [Tokens::ASSIGN, "="],
        [Tokens::FUNCTION, "fn"],
        [Tokens::LPAREN, "("],
        [Tokens::IDENT, "x"],
        [Tokens::COMMA, ","],
        [Tokens::IDENT, "y"],
        [Tokens::RPAREN, ")"],
        [Tokens::LBRACE, "{"],
        [Tokens::IDENT, "x"],
        [Tokens::PLUS, "+"],
        [Tokens::IDENT, "y"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::RBRACE, "}"],
        [Tokens::LET, "let"],
        [Tokens::IDENT, "result"],
        [Tokens::ASSIGN, "="],
        [Tokens::IDENT, "add"],
        [Tokens::LPAREN, "("],
        [Tokens::IDENT, "five"],
        [Tokens::COMMA, ","],
        [Tokens::IDENT, "ten"],
        [Tokens::RPAREN, ")"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::BANG, "!"],
        [Tokens::MINUS, "-"],
        [Tokens::SLASH, "/"],
        [Tokens::ASTERISK, "*"],
        [Tokens::INT, "5"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::INT, "5"],
        [Tokens::LT, "<"],
        [Tokens::INT, "10"],
        [Tokens::GT, ">"],
        [Tokens::INT, "5"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::IF, "if"],
        [Tokens::LPAREN, "("],
        [Tokens::INT, "5"],
        [Tokens::LT, "<"],
        [Tokens::INT, "10"],
        [Tokens::RPAREN, ")"],
        [Tokens::LBRACE, "{"],
        [Tokens::RETURN, "return"],
        [Tokens::TRUE, "true"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::RBRACE, "}"],
        [Tokens::ELSE, "else"],
        [Tokens::LBRACE, "{"],
        [Tokens::RETURN, "return"],
        [Tokens::FALSE, "false"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::RBRACE, "}"],
        [Tokens::INT, "10"],
        [Tokens::EQ, "=="],
        [Tokens::INT, "10"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::INT, "10"],
        [Tokens::NOT_EQ, "!="],
        [Tokens::INT, "9"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::STRING, "foobar"],
        [Tokens::STRING, "foo bar"],
        [Tokens::LBRACKET, "["],
        [Tokens::INT, "1"],
        [Tokens::COMMA, ","],
        [Tokens::INT, "2"],
        [Tokens::RBRACKET, "]"],
        [Tokens::SEMICOLON, ";"],
        [Tokens::LBRACE, "{"],
        [Tokens::STRING, "foo"],
        [Tokens::COLON, ":"],
        [Tokens::STRING, "bar"],
        [Tokens::RBRACE, "}"],
        [Tokens::EOF, ""]
      ].each do |(type, literal)|
        token = lexer.next_token
        assert_equal type, token.type
        assert_equal literal, token.literal
      end
    end
  end


end
