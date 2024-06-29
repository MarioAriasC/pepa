# frozen_string_literal: true

module Transpiler
  def self.transpile(program)
    program.to_rb
  end
end

module Kernel
  def self.len(param)
    case param
    when String
      param.size
    when Array
      param.length
    else
      "argument to `len` not supported, got #{param.class}"
    end
  end

  def self.push(array, element)
    _on_array(array, __method__) { |a| a.append(element) }
  end

  def self.first(array)
    _on_array(array, __method__) { |a| a[0] }
  end

  def self.last(array)
    _on_array(array, __method__) { |a| a[-1] }
  end

  def self.rest(array)
    _on_array(array, __method__) do |a|
      _, *tail = a
      if tail == []
        nil
      else
        tail
      end
    end
  end

  def self._on_array(array, name, &)
    case array
    when Array
      yield array
    else
      "argument to `#{name}` must be ARRAY, got #{array.class}"
    end
  end
end
