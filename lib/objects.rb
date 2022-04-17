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
end
