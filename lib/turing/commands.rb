=begin
  Autor: Dawid Fatyga
  Commands system
=end

# Komendy to bloki, ktore powinny pobierac referencje na maszyne, program i inne parametry
module Commands
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

# Deklaracja komend w systemi
Commands.declare do
  help nil, "listuje wszystkie dostepne komendy" do
    Commands.call(:version, true)
    puts "sposob uzycia: turing plik [opcje]"
    Commands.list.each do |key, value|
      Commands.call(key)
    end
  end

  version nil, "podaje wersje interpretera" do |*params|
    puts "Interpreter Maszyny Turinga - turing #{Turing::Version.to_s}"
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

