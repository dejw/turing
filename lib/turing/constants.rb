=begin
  Autor: Dawid Fatyga
  Constants and exception classes definition
=end

module Turing
  STATE_REGEXP = /^[[:alnum:]]+|-$/
  SYMBOL_REGEXP = /^[[:alnum:]\-#]$/
  DIRECTION_REGEXP = /^[<>-]$/

  True, False     = "T", "F"
  AcceptingStates = ["True", True]
  FinalStates     = ["False", False] + AcceptingStates


  class SyntaxError < Exception
  end
end

