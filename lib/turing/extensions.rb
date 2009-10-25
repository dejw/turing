=begin
  Autor: Dawid Fatyga
  Ruby standard library extensions.
=end

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end

class Time
  def self.diff_in_ms(start)
    ((Time.now - start) * 1000).to_i
  end
end

class String
	def skip!(pattern)
		self.slice!(pattern) or raise Turing::SyntaxError.new("zla skladnia '#{self.to_s}'")
	end

	def is_terminal?
	  Turing::FinalStates.include?(self)
	end

	def is_accepted?
		Turing::AcceptingStates.include?(self)
	end
end

