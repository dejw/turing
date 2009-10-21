#!/usr/bin/env ruby
=begin
  Autor: Dawid Fatyga
  Interpreter Maszyny Turinga

  TODO:
    sprawdzanie istnienia stanu poczatkowego
    sprawdzanie granic tasmy
    rysowanie / obliczanie w osobnym watku
    krokowe przetwarzanie
    interaktywnosc
    funkcje!!
=end

STATE_REGEXP = /^[[:alnum:]]+|-$/
SYMBOL_REGEXP = /^[[:alnum:]\-#]$/
DIRECTION_REGEXP = /^[<>-]$/

FALSE_STATE = "F"
TRUE_STATE = "T"
FALSE_STATES = ["False", FALSE_STATE]
TRUE_STATES = ["True", TRUE_STATE]

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
	  FALSE_STATES.include?(self) or is_accepted?
	end

	def is_accepted?
	  TRUE_STATES.include?(self)
	end
end

# Komendy to bloki, ktore powinny pobierac referencje na maszyne, program i inne parametry
module Commands
  class Error < Exception
  end

  def self.list
    @@commands ||= Hash.new(Proc.new { raise "nie znana komenda!" })
  end

  def self.declare(symbol = nil, arguments = nil, help = nil, &block)
    unless symbol
      self.instance_eval &block
    else
      help = [":#{symbol.to_s}#{arguments ? " " + arguments : ""}", help].compact.join(' - ')
      list[symbol.to_s] = [help, block]
    end
  end

  def self.method_missing(symbol, arguments = nil, help = nil, &block)
    declare(symbol, arguments, help, &block)
  end

  def self.call(name, *params)
    if params.empty?
      puts list[name.to_s].first
    else
      list[name.to_s].last.call(*params)
    end
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

  def for_state(name)
    rules[name] ||= {}
  end

  def shift(state, symbol)
    if symbol.to_s != "-"
      for_state(state)[symbol.to_s] ||= shift(state, "-")
    else
      for_state(state)["-"] ||= [FALSE_STATE, '-', '-']
    end
  end

  def add_shift(current_state, tape_symbol, next_state, write_symbol, direction)
    @initial_state ||= current_state
    for_state(current_state)[tape_symbol] = [next_state, write_symbol, direction]
  end
end

class Machine
  attr_accessor :inputs, :time, :syntax_check

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
    start_time = Time.now
    until @state.is_terminal?
      action = program.shift(@state, current_symbol)
      @state = action[0] if action[0] != '-'
      current_symbol = action[1] if action[1] != '-'
      (action[2] == '<' ? @head -= 1 : @head += 1) if action[2] != '-'
      raise "maszyna wpadla w petle czasu i poluje na mamuty" if @time and Time.diff_in_ms(start_time) > @time
    end
    @state.is_accepted?
  end

  def to_s
    span = (" " * @head)
    @tape.join + "\n" + span + "^" + "\n" + span + @state
  end
end

Commands.declare do
  help nil, "listuje wszystkie dostepne komendy" do
    Commands.call(:version, true)
    puts "sposob uzycia: turing plik [opcje]"
    Commands.list.each do |key, value|
      Commands.call(key)
    end
  end

  version nil, "podaje wersje interpretera" do |*params|
    puts "Interpreter Maszyny Turinga - turing 0.0.2"
    puts "Copyright (C) 2009 Dawid Fatyga"
  end

  input "ciag_znakow [ciag_znakow...]", "podaje slowa wejsciowe do maszyny" do |machine, program, *inputs|
    machine.inputs = inputs
  end

  program "pytanie", "ustawia pytanie, na ktore odpowiada program" do |machine, program, *question|
    program.question = question.join(" ")
  end

  time "czas", "ustawia czas w ms. po jakim koncza sie obliczenia" do |machine, program, time|
    machine.time = time.to_i
  end

  declare("syntax-check", nil, "nie przeprowadza obliczen tylko sprawdza skladnie") do |machine|
    machine.syntax_check = true
  end
end

program = Program.new
machine = Machine.new

def is_option?(o)
  ARGV.include?(":#{o.to_s}") or ARGV.include?("--#{o.to_s}")
end

def option_value(o)
  i = ARGV.index(":#{o.to_s}") || ARGV.index("--#{o.to_s}")
  raise "parametr '#{o}' byl ostatni" if ARGV.length == (i-1)
  ARGV[i+1]
end

[:version, :help].each do |cmd|
  if is_option?(cmd)
    Commands.call(cmd, true)
    exit
  end
end

Commands.call("syntax-check", machine) if is_option? "syntax-check"
Commands.call :time, machine, program, option_value(:time) if is_option? :time

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

  unless machine.syntax_check
    raise "nie podano zadnego wejscia" unless machine.inputs

    machine.inputs.each do |input|
      puts (program.question % input.to_s) + " #{machine.execute(input, program) ? "Tak" : "Nie"}"
    end
  else
    puts "skladnia ok"
  end
rescue Interrupt
  puts "\ndo widzenia"
end

