#!/usr/bin/env ruby
=begin
  Autor: Dawid Fatyga
  Interpreter Maszyny Turinga

  TODO:
    domyslne parametry deklaracji przejscia np. a T == a T - -
    :input moze brac kilka elementow i sprawdza je wszystkie
    mozliwosc podania "-" jako znaku na tasmie -> najpierw szukamy siebie potem "-"
    sprawdzanie istnienia stanu poczatkowego
    sprawdzanie granicz tasmy
    po jakims czasie ubijac algo.
    komendy:
      :program
      :input
      :time
    rysowanie / obliczanie w osobnym watku
    krokowe przetwarzanie
    iteraktywnosc
    funkcje!!
=end

# alfabet jest generowany

=begin
  Przykladowy program
    :program czy ciag %s sklada sie z samych jedynek?
    q0 # q1 - >
    q1 => 1 - - > || # True - - || 0 False - -
    :input 111 110
=end

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

# Komendy to bloki, ktore powinny pobierac referencje na maszyne, program i inne parametry
module Commands
  class Error < Exception
  end

  def self.list
    @@commands ||= Hash.new(Proc.new { raise "nie znana komenda!" })
  end

  def self.method_missing(symbol, &block)
    list[symbol.to_s] = block
  end

  def self.call(name, *params)
    list[name.to_s].call(*params)
  end
end

class Program
  attr_reader :initial_state
  attr_accessor :question

  def initialize
    @question = "Czy %s spełnia warunek?"
  end

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
  attr_accessor :inputs

  def initialize
    @head = 0
  end

  def current_symbol
    @tape[@head]
  end

  def current_symbol=(symbol)
    @tape[@head] = symbol
  end

  def execute(input, program)
    @tape = ['#'] + input.split('') + ['#']
    @state = program.initial_state
    @head = 0
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

Commands.help do |*params|
  if params.empty?
    puts ":help - wszystkie dostepne komendy"
  else
    Commands.call(:version, true)
    Commands.list.each_value(&:call)
  end
end

Commands.version { |*params|
  if params.empty?
    puts ":version - podaje wersje interpretera"
  else
    puts "Interpreter Maszyny Turinga - turing 0.0.2"
    puts "Copyright (C) 2009 Dawid Fatyga"
  end
}

Commands.input do |machine, program, *inputs|
  if inputs.empty?
    puts ":input ciag_znakow [ciag_znakow...] - podaje slowa wejsciowe do maszyny"
  else
    machine.inputs = inputs
  end
end

Commands.program do |machine, program, *question|
  if question.empty?
    puts ":program pytanie - ustawia pytanie, na ktore odpowiada program"
  else
    program.question = question.join(" ")
  end
end


program = Program.new
machine = Machine.new

def is_option?(o)
  ARGV.include?(":#{o.to_s}") or ARGV.include?("--#{o.to_s}")
end

[:version, :help].each do |cmd|
  if is_option?(cmd)
    Commands.call(cmd, true)
    exit
  end
end

begin
  while (line = gets) and (line = line.strip) != ""
    if line.start_with?(":") and line.skip!(":")
      params = line.split(" ")
      name = params.shift
      Commands.call(name, machine, program, *params)
    else
      state, shifts = line.split("=>").collect(&:strip)
      unless shifts then
        shifts = state
        state = nil
      end

      shifts.split("||").collect(&:strip).each do |tuple|
        tuple = tuple.collect { |shift| shift.split(' ') }
        tuple.each do |s|
          state ||= s.shift.skip!(STATE_REGEXP)
          symbol = s.shift.skip!(SYMBOL_REGEXP)
          next_state = s.shift.skip!(STATE_REGEXP)
          write_symbol = (s.shift or "-").skip!(SYMBOL_REGEXP)
          direction = (s.shift or "-").skip!(DIRECTION_REGEXP)
          program.add_shift(state, symbol, next_state, write_symbol, direction)
        end
      end
    end
  end

  raise "nie podano zadnego wejscia" unless machine.inputs

  machine.inputs.each do |input|
    puts (program.question % input.to_s) + " #{machine.execute(input, program) ? "Tak" : "Nie"}"
  end
rescue Exception => e
  puts "blad: #{e.message}"
end

