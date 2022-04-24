# frozen_string_literal: true

require_relative "evaluator"
require_relative "lexers"
require_relative "parsers"

module Benchmarks
  def self.measure(&)
    start = Time.now
    result = yield
    diff = Time.now - start
    puts "#{result.value.inspect}, duration=#{diff}"
  end

  def self.fast_input(size)
    %(
let fibonacci = fn(x) {
    if (x < 2) {
    	return x;
    } else {
    	fibonacci(x - 1) + fibonacci(x - 2);
    }
};
fibonacci(#{size});)
  end

  def self.eval
    environment = Evaluator::Environment.new
    measure do
      Evaluator.evaluate(parse(fast_input(35)), environment)
    end
  end

  def self.parse(input)
    lexer = Lexers::Lexer.new(input)
    parser = Parsers::Parser.new(lexer)
    parser.parse_program
  end
end
