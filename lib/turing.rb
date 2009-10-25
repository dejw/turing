$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

['constants', 'extensions', 'commands', 'program', 'machine'].each do |name|
  require "turing/#{name}"
end

module Turing
  module Version
    MAJOR = 0
    MINOR = 0
    TINY  = 2

    STRING = [MAJOR, MINOR, TINY].join('.')

    class << self
      def to_s
        STRING
      end

      def ==(arg)
        STRING == arg
      end
    end
  end
end

