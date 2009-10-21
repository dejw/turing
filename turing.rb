#!/usr/bin/env ruby
=begin
  Autor: Dawid Fatyga
  Interpreter Maszyny Turinga

  TODO:
    sprawdzanie istnienia stanu poczatkowego
    sprawdzanie granicz tasmy
    rysowanie / obliczanie w osobnym watku
    krokowe przetwarzanie
    iteraktywnosc
    funkcje!!
=end

# alfabet jest generowany


STATE_REGEXP = /^[[:alnum:]]+|-$/
SYMBOL_REGEXP = /^[[:alnum:]\-#]$/
DIRECTION_REGEXP = /^[<>-]$/

FALSE_STATE = "False"
TRUE_STATE = "True"

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end

class TuringSyntaxError < Exception
  def initialize(line)
    @line = line
  end

  def to_str
    "blad skladniowy: '#{@line}'"
  end
end

class String
	def skip!(pattern)
		self.slice!(pattern) or raise TuringSyntaxError(self)
	end

	def is_terminal?
	  self == FALSE_STATE or self == TRUE_STATE
	end

	def is_accepted?
	  self == TRUE_STATE
	end
end


class Program
  attr_reader :initial_state

  def rules
    @rules ||= {}
  end

  def shift(state, symbol)
    (rules[state] ||= {})[symbol] ||= [FALSE_STATE, '-', '-']
  end

  def add_shift(current_state, tape_symbol, next_state, write_symbol, direction)
    @initial_state ||= current_state
    (rules[current_state] ||= {})[tape_symbol] = [next_state, write_symbol, direction]
  end
end

class Machine
  def initialize(input, state, head = 0)
    @tape = ['#'] + input.split('') + ['#']
    @head = head
    @state = state
  end

  def current_symbol
    @tape[@head]
  end

  def current_symbol=(symbol)
    @tape[@head] = symbol
  end

  def execute(program)
    until @state.is_terminal?
      action = program.shift(@state, current_symbol)
      @state = action[0] if action[0] != '-'
      current_symbol = action[1] if action[1] != '-'
      (action[2] == '<' ? @head -= 1 : @head += 1) if action[2] != '-'
    end
    @state.is_accepted?
  end

  def to_s
    span = (" " * @head)
    @tape.join + "\n" + span + "^" + "\n" + span + @state
  end
end

input = nil
program = Program.new

while line = gets
  line.strip!
  if line.start_with?(":input")
    cmd, input = line.split(' ')
    raise "blad w :input!" unless input
  else
    state, shifts = line.split(":").collect(&:strip)
    unless shifts then  #q0 a q1 b >
      shifts = state.split("|").collect(&:strip)
      shifts = shifts.collect { |shift| shift.split(' ') }
      shifts.each do |shift|
        from_state = shift[0].skip!(STATE_REGEXP)
        from_char = shift[1].skip!(SYMBOL_REGEXP)
        to_state = shift[2].skip!(STATE_REGEXP)
        to_char = shift[3].skip!(SYMBOL_REGEXP)
        direction = shift[4].skip!(DIRECTION_REGEXP)

        program.add_shift(from_state, from_char, to_state, to_char, direction)
      end
    else                  #q0 : a q1 b > |
      shifts = shifts.split("|").collect(&:strip)
      raise "nie ma jeszcze!"
    end
  end
end
raise "nie ma slowa poczatkowego" unless input
puts Machine.new(input, program.initial_state).execute(program)

