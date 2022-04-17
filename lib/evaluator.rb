# frozen_string_literal: true

module Evaluator
  class Environment
    attr_reader :store, :outer

    def initialize(store = {}, outer = nil)
      @store = store
      @outer = outer
    end

    def []=(name, value)
      @store[name] = value
    end

    def [](name)
      obj = @store[name]
      if obj.nil? && !@outer.nil?
        @outer[name]
      else
        obj
      end
    end
  end

  def self.evaluate(node, environment)
    case node
    when Ast::Program
      eval_program(node.statements, environment)
    when Ast::ExpressionStatement
      evaluate(node.expression, environment)
    when Ast::IntegerLiteral
      Objects::MInteger.new(node.value)
    when Ast::PrefixExpression
      evaluate(node.right, environment).if_not_error do |right|
        eval_prefix_expression(node.operator, right)
      end
    when Ast::InfixExpression
      evaluate(node.left, environment).if_not_error do |left|
        evaluate(node.right, environment).if_not_error do |right|
          eval_infix_expression(node.operator, left, right)
        end
      end
    else
      p node
      nil
    end
  end

  def self.eval_program(statements, environment)
    result = nil
    statements.each do |statement|
      result = evaluate(statement, environment)
      case result
      when Objects::MReturnValue
        return result.value
      when Objects::MError
        return result
      end
    end
    result
  end

  def self.eval_minus_prefix_operator_expression(right)
    if right.nil?
      nil
    else
      case right
      when Objects::MInteger
        -right
      else
        Objects::MError.new("unknown operator: -#{right.type_desc}")
      end
    end
  end

  def self.eval_prefix_expression(operator, right)
    case operator
    when "!"
      eval_bang_operator_expression(right)
    when "-"
      eval_minus_prefix_operator_expression(right)
    else
      Objects::MError.new("Unknown operator : #{operator}#{right.type_desc}")
    end
  end

  def self.eval_integer_infix_expression(operator, left, right)
    case operator
    when "+"
      left + right
    when "-"
      left - right
    when "*"
      left * right
    when "/"
      left / right
    when "<"
      (left < right).to_m
    when ">"
      (left > right).to_m
    when "=="
      (left == right).to_m
    when "!="
      (left != right).to_m
    else
      Objects::MError.new("unknown operator: #{left.type_desc} #{operator} #{right.type_desc}")
    end
  end

  def self.eval_infix_expression(operator, left, right)
    if left.is_a?(Objects::MInteger) && right.is_a?(Objects::MInteger)
      eval_integer_infix_expression(operator, left, right)
    end
  end
end
