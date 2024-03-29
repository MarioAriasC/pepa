# frozen_string_literal: true

module Ast
  class Node
    def token_literal; end
  end

  class Expression < Node
    def eql?(other)
      to_s == other.to_s
    end
  end

  Statement = Expression
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

  class Program
    attr_reader :statements

    def initialize(statements)
      @statements = statements
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

  class PrefixExpression < Expression
    include TokenHolder
    attr_reader :operator, :right

    def initialize(token, operator, right)
      @token = token
      @operator = operator
      @right = right
    end

    def to_s
      "(#{@operator}#{@right})"
    end
  end

  class InfixExpression < Expression
    include TokenHolder
    attr_reader :left, :operator, :right

    def initialize(token, left, operator, right)
      @token = token
      @left = left
      @operator = operator
      @right = right
    end

    def to_s
      "(#{@left} #{operator} #{@right})"
    end
  end

  class CallExpression < Expression
    include TokenHolder
    attr_reader :function, :arguments

    def initialize(token, function, arguments)
      @token = token
      @function = function
      @arguments = arguments
    end

    def to_s
      "#{@function}(#{@arguments.or_else([]).join(", ")})"
    end
  end

  class ArrayLiteral < Expression
    include TokenHolder
    attr_reader :elements

    def initialize(token, elements)
      @token = token
      @elements = elements
    end

    def to_s
      "[#{@elements.or_else([]).join(", ")}]"
    end
  end

  class IndexExpression < Expression
    include TokenHolder
    attr_reader :left, :index

    def initialize(token, left, index)
      @token = token
      @left = left
      @index = index
    end

    def to_s
      "(#{@left}[#{@index}])"
    end
  end

  class IfExpression < Expression
    include TokenHolder
    attr_reader :condition, :consequence, :alternative

    def initialize(token, condition, consequence, alternative)
      @token = token
      @condition = condition
      @consequence = consequence
      @alternative = alternative
    end

    def to_s
      "if(#{@condition}) #{@consequence} #{@alternative ? "else #{@alternative}" : ""}"
    end
  end

  class BlockStatement < Statement
    include TokenHolder
    attr_reader :statements

    def initialize(token, statements)
      @token = token
      @statements = statements
    end

    def to_s
      @statements.or_else([]).join
    end
  end

  class FunctionLiteral < Expression
    include TokenHolder
    attr_reader :parameters, :body

    def initialize(token, parameters, body)
      @token = token
      @parameters = parameters
      @body = body
    end

    def to_s
      "#{token_literal}(#{@parameters.or_else([]).join(", ")}) {#{@body}}"
    end
  end

  class StringLiteral < Expression
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

  class HashLiteral < Expression
    include TokenHolder
    attr_reader :pairs

    def initialize(token, pairs)
      @token = token
      @pairs = pairs
    end

    def to_s
      "{#{@pairs.map { |key, value| "#{key}:#{value}" }.join(", ")}}"
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
