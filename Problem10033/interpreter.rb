# PC/UVa IDs: 110106/10033

class Computer
  
  def initialize(file)
    @regs = Array.new(10, 0)
    @ram = Array.new(1000, 0)
    load_inst(file)
  end
  
  def load_inst(file)
    pc = 0
    file.each_line do |line|
      line.chomp!
      line.strip!
      if line.length > 0 then
        @ram[pc] = line
        pc += 1
      elsif pc > 0
        break
      end        
    end
  end
  
  MAX_INST = 1000
  
  def execute
    executed = 0
    pc = 0
    
    opcodes =
    {
      '1' => Proc.new { return executed },
      '2' => Proc.new { |d,n| @regs[d]  = n; @regs[d] %= MAX_INST },
      '3' => Proc.new { |d,n| @regs[d] += n; @regs[d] %= MAX_INST },
      '4' => Proc.new { |d,n| @regs[d] *= n; @regs[d] %= MAX_INST },
      '5' => Proc.new { |d,s| @regs[d]  = @regs[s]; @regs[d] %= MAX_INST },
      '6' => Proc.new { |d,s| @regs[d] += @regs[s]; @regs[d] %= MAX_INST },
      '7' => Proc.new { |d,s| @regs[d] *= @regs[s]; @regs[d] %= MAX_INST },
      '8' => Proc.new { |d,a| @regs[d]  = @ram[@regs[a]] },
      '9' => Proc.new { |s,a| @ram[@regs[a]] = @regs[s] },
      '0' => Proc.new { |d,s| pc = @regs[d] if @regs[s] != 0 },
    }
    
    loop do
      break unless /(\d)(\d)(\d)/ =~ @ram[pc]
      pc += 1
      executed += 1
      opcodes[$1][$2.to_i, $3.to_i]
    end
  end
    
end

fail "No input is given" if ARGV.length < 1

File.open(ARGV[0], "r") do |file|
  cases = 0
  file.each_line do |line|
    cases = line.chomp.strip.to_i
    break if cases > 0
  end
  cases.times { puts Computer.new(file).execute }
end