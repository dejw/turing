=begin
  Autor: Dawid Fatyga
  Program definition

  TODO:
    possibility to define programs inside ruby code
=end

module Turing
  class Program
    attr_reader :initial_state
    attr_accessor :question

    def initialize(question = "Czy %s spełnia warunek?")
      @question = question
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
        for_state(state)["-"] ||= [Turing::False, '-', '-']
      end
    end

    def add_shift(current_state, tape_symbol, next_state, write_symbol, direction)
      @initial_state ||= current_state
      for_state(current_state)[tape_symbol] = [next_state, write_symbol, direction]
    end
  end
end

