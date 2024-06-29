# frozen_string_literal: true

module Ast
  class Node
    def token_literal; end
  end

  class Expression < Node
    def eql?(other)
      to_s == other.to_s
    end

    def to_rb; end
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

    def to_rb
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

    def to_rb
      @statements.map(&:to_rb).join("\n")
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

    def to_rb
      @value
    end
  end

  class LetStatement < Expression
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

    def to_rb
      case @value
      when FunctionLiteral
        "def #{@name}#{@value.to_rb}"
      else
        "#{@name} = #{@value.to_rb.or_else("")}"
      end
    end
  end

  class ExpressionStatement < Expression
    include TokenHolder
    attr_reader :expression

    def initialize(token, expression)
      @token = token
      @expression = expression
    end

    def to_s
      @expression.or_else("").to_s
    end

    def to_rb
      @expression.to_rb
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

  class ReturnStatement < Expression
    include TokenHolder
    attr_reader :return_value

    def initialize(token, return_value)
      @token = token
      @return_value = return_value
    end

    def to_s
      "#{token_literal} #{@return_value.or_else("")}"
    end

    def to_rb
      "return #{@return_value.to_rb.or_else("")}"
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

    def to_rb
      "(#{@operator}#{@right.to_rb})"
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

    def to_rb
      "(#{@left.to_rb} #{operator} #{@right.to_rb})"
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

    def to_rb
      parenthesis = "(#{@arguments.or_else([]).map(&:to_rb).join(", ")})"
      case @function
      when FunctionLiteral
        # is the function a ruby lambda?
        if @function.name == ""
          "#{@function.to_rb}.call#{parenthesis}"
        else
          "#{@function.to_rb}#{parenthesis}"
        end
      else
        "#{@function.to_rb}#{parenthesis}"
      end
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

    def to_rb
      "[#{@elements.or_else([]).map(&:to_rb).join(", ")}]"
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

    def to_rb
      "#{@left.to_rb}[#{@index.to_rb}]"
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

    def to_rb
      if @alternative.nil?
        "#{@consequence.to_rb} if #{@condition.to_rb}"
      else
        "if #{@condition.to_rb}
            #{@consequence.to_rb}
          else
            #{@alternative.to_rb}
          end
        "
      end
    end
  end

  class BlockStatement < Expression
    include TokenHolder
    attr_reader :statements

    def initialize(token, statements)
      @token = token
      @statements = statements
    end

    def to_s
      @statements.or_else([]).join
    end

    def to_rb
      @statements.map(&:to_rb).join("\n")
    end
  end

  class FunctionLiteral < Expression
    include TokenHolder
    attr_accessor :name
    attr_reader :parameters, :body

    def initialize(token, parameters, body, name = "")
      @token = token
      @parameters = parameters
      @body = body
      @name = name
    end

    def to_s
      "#{token_literal}(#{@parameters.or_else([]).join(", ")}) {#{@body}}"
    end

    def to_rb
      if @name == ""
        # is anonymous
        "->(#{@parameters.or_else([]).map(&:to_rb).join(", ")}) { #{@body.to_rb} }"
      else
        "(#{@parameters.or_else([]).map(&:to_rb).join(", ")})
          #{@body.to_rb}
         end
"
      end
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

    def to_rb
      %("#{@value}")
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

    def to_rb
      "({#{@pairs.map { |key, value| "#{key.to_rb} => #{value.to_rb}" }.join(", ")}}.freeze)"
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
