# frozen_string_literal: true

require_relative "pepa/version"
require_relative "evaluator"
require_relative "lexers"
require_relative "parsers"

module Pepa
  class Error < StandardError; end
  PROMPT = ">>>"
  def self.main
    environment = Evaluator::Environment.new
    puts PROMPT
    loop do
      code = gets.chomp
      lexer = Lexers::Lexer.new(code)
      parser = Parsers::Parser.new(lexer)
      program = parser.parse_program

      unless parser.errors.empty?
        puts "Whoops! we ran into some monkey business here!"
        puts " parser errors:"
        parser.errors.each { |error| puts "\t#{error}" }
        next
      end

      evaluated = Evaluator.evaluate(program, environment)
      puts evaluated.inspect unless evaluated.nil?

      puts PROMPT
    end
  end
end
