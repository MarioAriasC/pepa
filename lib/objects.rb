# frozen_string_literal: true

module Objects
  class MObject
    def type_desc
      self.class.to_s
    end

    def if_not_error(&)
      case self
      when MError
        self
      else
        yield self
      end
    end

    def is_truthy?
      case self
      when MBoolean
        value
      when MNull
        false
      else
        true
      end
    end

    def is_error?
      is_a?(MError)
    end
  end

  module HashType
    INTEGER = 1
    BOOLEAN = 2
    STRING = 4
  end

  class MValue < MObject
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def inspect
      @value.to_s
    end

    def hash_type; end

    def hash_key; end
  end

  class MInteger < MValue
    def -@
      MInteger.new(-@value)
    end

    def +(other)
      MInteger.new(@value + other.value)
    end

    def -(other)
      MInteger.new(@value - other.value)
    end

    def *(other)
      MInteger.new(@value * other.value)
    end

    def /(other)
      MInteger.new((@value / other.value))
    end

    def <(other)
      @value < other.value
    end

    def >(other)
      @value > other.value
    end

    def ==(other)
      @value == other.value
    end

    def hash_type
      HashType::INTEGER
    end

    def hash_key
      HashKey.new(hash_type, @value)
    end
  end

  class MReturnValue < MObject
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def inspect
      @value.inspect
    end
  end

  class MError < MObject
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def inspect
      "ERROR: #{@message}"
    end

    def to_s
      "MError(message=#{@message})"
    end
  end

  class MBoolean < MValue
    def ==(other)
      @value == other.value
    end

    def hash_type
      HashType::BOOLEAN
    end

    def hash_key
      HashKey.new(hash_type, (@value ? 1 : 0))
    end
  end

  class MNull < MObject
    def to_s
      "null"
    end
  end

  class MFunction < MObject
    attr_reader :environment, :body, :parameters

    def initialize(parameters, body, environment)
      @parameters = parameters
      @body = body
      @environment = environment
    end

    def inspect
      parameters = ""
      parameters = @parameters.map(&:to_s).join(", ") unless @parameters.nil?
      "fn(#{parameters}) {\n\t#{body}\n}"
    end
  end

  class MString < MValue
    def +(other)
      MString.new(value + other.value)
    end

    def hash_type
      HashType::STRING
    end

    def hash_key
      HashKey.new(hash_type, @value.to_sym)
    end
  end

  class MArray < MObject
    attr_reader :elements

    def initialize(elements)
      @elements = elements
    end

    def inspect
      "[#{elements.join(", ")}]"
    end
  end

  class MHash < MObject
    attr_reader :pairs

    def initialize(pairs)
      @pairs = pairs
    end

    def inspect
      "{#{@pairs.values.map { |pair| "#{pair.key.inspect}: #{pair.value.inspect}" }}}"
    end
  end

  class HashPair
    attr_reader :value, :key

    def initialize(key, value)
      @key = key
      @value = value
    end
  end

  class HashKey
    attr_reader :value, :hash_type

    def initialize(hash_type, value)
      @hash_type = hash_type
      @value = value
    end

    def eql?(other)
      if is_a?(HashKey)
        @hash_type == other.hash_type && @value == other.value
      else
        false
      end
    end

    alias == eql?

    def hash
      @hash_type.hash ^ @value.hash
    end
  end

  class MBuiltinFunction < MObject
    attr_reader :fn

    def initialize(fn)
      @fn = fn
    end

    def inspect
      "builtin function"
    end
  end

  def self.arg_size_check(expected_size, args, &)
    length = args.size
    if length == expected_size
      yield args
    else
      MError.new("wrong number of arguments. got=#{length}, want=#{expected_size}")
    end
  end

  def self.array_check(builtin_name, args, &)
    if args[0].is_a?(MArray)
      array = args[0]
      yield array, array.elements.size
    else
      MError.new("argument to `#{builtin_name}` must be ARRAY, got #{args[0].type_desc}")
    end
  end

  def self.len(args)
    arg_size_check(1, args) do |arguments|
      arg = arguments[0]
      case arg
      when MString
        MInteger.new(arg.value.size)
      when MArray
        MInteger.new(arg.elements.size)
      else
        MError.new("argument to `len` not supported, got #{arg.type_desc}")
      end
    end
  end

  def self.push(args)
    arg_size_check(2, args) do |arguments|
      array_check(PUSH_NAME, arguments) do |array, _|
        MArray.new(array.elements << args[1])
      end
    end
  end

  def self.first(args)
    arg_size_check(1, args) do |arguments|
      array_check(FIRST_NAME, arguments) do |array, length|
        array.elements[0] if length.positive?
      end
    end
  end

  def self.last(args)
    arg_size_check(1, args) do |arguments|
      array_check(LAST_NAME, arguments) do |array, length|
        array.elements.last if length.positive?
      end
    end
  end

  def self.rest(args)
    arg_size_check(1, args) do |arguments|
      array_check(REST_NAME, arguments) do |array, length|
        if length.positive?
          array.elements.delete_at(0)
          MArray.new(array.elements)
        end
      end
    end
  end

  M_NULL = MNull.new

  LEN_NAME = "len"
  LEN_BUILTIN = MBuiltinFunction.new(method(:len))
  PUSH_NAME = "push"
  PUSH_BUILTIN = MBuiltinFunction.new(method(:push))
  FIRST_NAME = "first"
  FIRST_BUILTIN = MBuiltinFunction.new(method(:first))
  LAST_NAME = "last"
  LAST_BUILTIN = MBuiltinFunction.new(method(:last))
  REST_NAME = "rest"
  REST_BUILTIN = MBuiltinFunction.new(method(:rest))
end
