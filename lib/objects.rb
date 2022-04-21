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

  M_NULL = MNull.new
end
