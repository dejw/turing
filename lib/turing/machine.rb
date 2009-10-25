=begin
  Autor: Dawid Fatyga
  Machine definition
=end

module Turing
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
end

