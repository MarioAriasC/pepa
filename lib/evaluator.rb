# frozen_string_literal: true

require_relative "objects"
module Evaluator
  M_TRUE = Objects::MBoolean.new(true)
  M_FALSE = Objects::MBoolean.new(false)

  BUILTINS = {
    Objects::LEN_NAME => Objects::LEN_BUILTIN,
    Objects::PUSH_NAME => Objects::PUSH_BUILTIN,
    Objects::FIRST_NAME => Objects::FIRST_BUILTIN,
    Objects::LAST_NAME => Objects::LAST_BUILTIN,
    Objects::REST_NAME => Objects::REST_BUILTIN
  }.freeze

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

  def self.evaluate(program, environment)
    result = nil
    program.statements.each do |statement|
      result = inner_eval(statement, environment)
      case result
      when Objects::MReturnValue
        return result.value
      when Objects::MError
        return result
      end
    end
    result
  end

  def self.inner_eval(node, environment)
    case node
    when Ast::Identifier
      eval_identifier(node, environment)
    when Ast::IntegerLiteral
      Objects::MInteger.new(node.value)
    when Ast::InfixExpression
      inner_eval(node.left, environment).if_not_error do |left|
        inner_eval(node.right, environment).if_not_error do |right|
          eval_infix_expression(node.operator, left, right)
        end
      end
    when Ast::BlockStatement
      eval_block_statement(node, environment)
    when Ast::ExpressionStatement
      inner_eval(node.expression, environment)
    when Ast::IfExpression
      eval_if_expression(node, environment)
    when Ast::CallExpression
      inner_eval(node.function, environment).if_not_error do |function|
        args = eval_expressions(node.arguments, environment)
        if args.size == 1 && args[0].error?
          args[0]
        else
          apply_function(function, args)
        end
      end
    when Ast::ReturnStatement
      inner_eval(node.return_value, environment).if_not_error do |value|
        Objects::MReturnValue.new(value)
      end
    when Ast::PrefixExpression
      inner_eval(node.right, environment).if_not_error do |right|
        eval_prefix_expression(node.operator, right)
      end
    when Ast::BooleanLiteral
      node.value.to_m
    when Ast::LetStatement
      inner_eval(node.value, environment).if_not_error do |value|
        environment[node.name.value] = value
      end
    when Ast::FunctionLiteral
      Objects::MFunction.new(node.parameters, node.body, environment)
    when Ast::StringLiteral
      Objects::MString.new(node.value)
    when Ast::IndexExpression
      left = inner_eval(node.left, environment)
      return left if left.error?

      index = inner_eval(node.index, environment)
      return index if index.error?

      eval_index_expression(left, index)
    when Ast::HashLiteral
      eval_hash_literal(node, environment)
    when Ast::ArrayLiteral
      elements = eval_expressions(node.elements, environment)
      if elements.size == 1 && elements[0].error?
        elements[0]
      else
        Objects::MArray.new(elements)
      end
    else
      p node
      nil
    end
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

  def self.eval_index_expression(left, index)
    if left.is_a?(Objects::MArray) && index.is_a?(Objects::MInteger)
      eval_array_index_expression(left, index)
    elsif left.is_a?(Objects::MHash)
      eval_hash_index_expression(left, index)
    else
      Objects::MError.new("index operator not supported: #{left.type_desc}")
    end
  end

  def self.eval_array_index_expression(array, index)
    elements = array.elements
    i = index.value
    max = elements.size - 1
    return Objects::M_NULL if i.negative? || i > max

    elements[i]
  end

  def self.eval_hash_index_expression(hash, index)
    case index
    when Objects::MValue
      pair = hash.pairs[index.hash_key]
      if pair.nil?
        Objects::M_NULL
      else
        pair.value
      end
    else
      Objects::MError.new("unusable as a hash key: #{index.type_desc}")
    end
  end

  def self.eval_hash_literal(hash_literal, environment)
    pairs = {}
    hash_literal.pairs.each do |key_node, value_node|
      key = inner_eval(key_node, environment)
      return key if key.error?

      case key
      when Objects::MValue
        value = inner_eval(value_node, environment)
        return value if value.error?

        pairs[key.hash_key] = Objects::HashPair.new(key, value)
      else
        return Objects::MError.new("unusable as hash key: #{key.type_desc}")
      end
    end

    Objects::MHash.new(pairs)
  end

  def self.eval_bang_operator_expression(right)
    case right
    when M_TRUE
      M_FALSE
    when M_FALSE
      M_TRUE
    when Objects::M_NULL
      M_TRUE
    else
      M_FALSE
    end
  end

  def self.eval_expressions(arguments, environment)
    arguments.map do |argument|
      evaluated = inner_eval(argument, environment)
      return [evaluated] if evaluated.error?

      evaluated
    end
  end

  def self.apply_function(function, args)
    case function
    when Objects::MFunction
      extend_env = extend_function_env(function, args)
      evaluated = inner_eval(function.body, extend_env)
      unwrap_return_value(evaluated)
    when Objects::MBuiltinFunction
      result = function.fn.call(args)
      if result.nil?
        Objects::M_NULL
      else
        result
      end
    else
      Objects::MError.new("not a function: #{function.type_desc}")
    end
  end

  def self.extend_function_env(function, args)
    env = Environment.new({}, function.environment)
    function.parameters&.each_with_index do |identifier, i|
      env[identifier.value] = args[i]
    end
    env
  end

  def self.unwrap_return_value(obj)
    case obj
    when Objects::MReturnValue
      obj.value
    else
      obj
    end
  end

  def self.eval_identifier(identifier, environment)
    value = environment[identifier.value]
    if value.nil?
      builtin = BUILTINS[identifier.value]
      if builtin.nil?
        Objects::MError.new("identifier not found: #{identifier.value}")
      else
        builtin
      end
    else
      value
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
    elsif operator == "=="
      (left == right).to_m
    elsif operator == "!="
      (left != right).to_m
    elsif left.type_desc != right.type_desc
      Objects::MError.new("type mismatch: #{left.type_desc} #{operator} #{right.type_desc}")
    elsif left.is_a?(Objects::MString) && right.is_a?(Objects::MString)
      eval_string_infix_expression(operator, left, right)
    else
      Objects::MError.new("unknown operator: #{left.class} #{operator} #{right.class}")
    end
  end

  def self.eval_string_infix_expression(operator, left, right)
    if operator == "+"
      left + right
    else
      Objects::MError.new("unknown operator: #{left.class} #{operator} #{right.class}")
    end
  end

  def self.eval_if_expression(if_expression, environment)
    inner_eval(if_expression.condition, environment).if_not_error do |condition|
      if condition.truthy?
        inner_eval(if_expression.consequence, environment)
      elsif !if_expression.alternative.nil?
        inner_eval(if_expression.alternative, environment)
      else
        Objects::M_NULL
      end
    end
  end

  def self.eval_block_statement(block_statement, environment)
    result = nil
    block_statement.statements.each do |statement|
      result = inner_eval(statement, environment)
      return result if result.is_a?(Objects::MReturnValue) || result.is_a?(Objects::MError)
    end
    result
  end
end

class TrueClass
  def to_m
    Objects::MBoolean.new(true)
  end
end

class FalseClass
  def to_m
    Objects::MBoolean.new(false)
  end
end

class NilClass
  def if_not_error(&)
    self
  end

  def error?
    false
  end

  def type_desc
    "nil"
  end
end
