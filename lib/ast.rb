# frozen_string_literal: true

module Ast
  class Node
    def token_literal; end
  end

  class Statement < Node
  end

  class Expression < Node
    def eql?(other)
      to_s == other.to_s
    end
  end

  module TokenHolder
    attr_reader :token

    def token_literal
      @token.literal
    end
  end

  module LiteralExpression
    def to_s
      @token.literal
    end
  end

  class Program < Node
    attr_reader :statements

    def initialize(statements)
      @statements = statements
    end

    def token_literal
      if @statements.empty?
        ""
      else
        @statements[1].token_literal
      end
    end

    def to_s
      @statements.join
    end
  end

  class Identifier < Expression
    include TokenHolder
    attr_reader :value

    def initialize(token, value)
      @token = token
      @value = value
    end

    def to_s
      @value
    end
  end

  class LetStatement < Statement
    include TokenHolder
    attr_reader :name, :value

    def initialize(token, name, value)
      @token = token
      @name = name
      @value = value
    end

    def to_s
      "#{token_literal} #{@name} = #{@value.or_else("")}"
    end
  end

  class ExpressionStatement < Statement
    include TokenHolder
    attr_reader :expression

    def initialize(token, expression)
      @token = token
      @expression = expression
    end

    def to_s
      @expression.or_else("").to_s
    end
  end

  class IntegerLiteral < Expression
    include TokenHolder
    include LiteralExpression
    attr_reader :value

    def initialize(token, value)
      @token = token
      @value = value
    end
  end

  class BooleanLiteral < Expression
    include TokenHolder
    include LiteralExpression
    attr_reader :value

    def initialize(token, value)
      @token = token
      @value = value
    end
  end

  class ReturnStatement < Statement
    include TokenHolder
    attr_reader :return_value

    def initialize(token, return_value)
      @token = token
      @return_value = return_value
    end

    def to_s
      "#{token_literal} #{@return_value.or_else("")}"
    end
  end
end

class Object
  def or_else(alternative)
    if nil?
      alternative
    else
      self
    end
  end
end
