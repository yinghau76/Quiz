class Parser
  
  class Lexer
    
    TokenMatch = Struct.new(:name, :pattern, :eval)
    
    attr_accessor :pos
    attr_reader :matches
    
    def initialize
      @matches = []
    end
    
    def add_match(name, pattern, eval)
      @matches << TokenMatch.new(name, pattern, eval)
    end
    
    def next_token
      @pos += 1
      return @tokens[@pos - 1]
    end
  
    def lex(code)
      @tokens = []
      code = code.gsub(/\s/, "")
      loop do 
        break unless extract_token(code) do |token, remaining| 
          @tokens << token
          code = remaining
        end
      end
      
      @pos = 0      
    end
    
    def extract_token(code)
      @matches.each do |match|
        if match.pattern =~ code
          token = match.eval.call($~[0])
          yield(token, $~.post_match) if block_given?
          return token
        end
      end
      nil
    end    
    
  end

  class Production
    
    DerivationMatch = Struct.new(:pattern, :eval)
    
    def initialize(name, parser)
      @name = name
      @parser = parser
      @matches = []
      @lrmatches = []
    end
    
    def match(*pattern, &eval)
      match = DerivationMatch.new(pattern, eval)
      if pattern[0] == @name
        pattern.shift
        @lrmatches << match
      else
        @matches << match
      end
    end
    
    def parse(indent = 0)
      # print " " * indent, "parse #{@name}\n"
      match_result = try_matches(@matches, nil, indent + 1)
      return nil unless match_result
      
      loop do
        result = try_matches(@lrmatches, match_result, indent + 1)
        unless result
          # print " " * indent, "result is #{match_result}\n"
          return match_result
        end
        match_result = result
      end
      return match_result
    end
    
    def try_matches(matches, pre_result, indent)
      start = @parser.lexer.pos
      matches.each do |match|
        results = pre_result ? [pre_result] : []
        # print " " * indent, "try #{match.pattern.inspect}\n"
        match.pattern.each do |expected|
          if Symbol === expected
            result = @parser.productions[expected].parse(indent + 1)
            results << result
            unless results.last
              results.clear
              break
            end
          else
            result = @parser.lexer.next_token
            if not expected === result
              # print " " * (indent + 1), "'#{expected}' rather than '#{result}' is expected. backtrack!\n"
              results = []
              break
            else
              results << result
            end
          end
        end
        
        if results.empty?
          @parser.lexer.pos = start
        elsif match.eval.nil?
          return results.first
        else
          # print " " * indent, "eval #{results.inspect}\n"
          return match.eval.call(*results)
        end
      end
      nil
    end
    
  end

  attr_reader :lexer
  attr_reader :productions
  
  def initialize(&block)
    @lexer = Lexer.new
    @productions = {}
    instance_eval(&block)
  end
  
  def token(name, pattern, &eval)
    @lexer.add_match(name, pattern, eval)
  end

  def production(name, &block)
    prod = Production.new(name, self)
    prod.instance_eval(&block)
    @productions[name] = prod
  end
  
  def start(name, &block)
    @start = production(name, &block)
  end
    
  def parse(code)
    @lexer.lex(code)
    @start.parse(0)
  end

end

require 'test/unit'

class TestCompiler < Test::Unit::TestCase
  
  def setup
    @parser = Parser.new do
      
      # lexer here
      token(:literal, /^\d+/) { |l| l.to_i }
      token(:op, /^(\*\*|[\+\-\*\/\%\(|)])/) { |op| op }

      # grammar here
      start :expr do
        match(:expr, '+', :term) {|a, op, b| a + b}
        match(:expr, '-', :term) {|a, op, b| a - b}
        match(:term)
      end
      production :term do
        match(:term, '*', :pow) {|a, op, b| a * b}
        match(:term, '/', :pow) {|a, op, b| a / b}
        match(:term, '%', :pow) {|a, op, b| a % b}
        match(:pow)
      end
      production :pow do
        match(:pow, '**', :primary)  {|a, op, b| a ** b}
        match(:primary)
      end
      production :primary do
        match(Integer)
        match('-', Integer) {|minus, i| 0 - i}
        match('(', :expr, ')') {|lp, expr, rp| expr}
      end
      
    end
  end
  
  def test_01
    assert_equal 2+2, @parser.parse('2+2')
    assert_equal 2-2, @parser.parse('2-2')
    assert_equal 2*2, @parser.parse('2*2')
    assert_equal 2**2, @parser.parse('2**2')
    assert_equal 2/2, @parser.parse('2/2')
    assert_equal 2%2, @parser.parse('2%2')
    assert_equal 3%2, @parser.parse('3%2')
  end

  def test_02
    assert_equal 2+2+2, @parser.parse('2+2+2')
    assert_equal 2-2-2, @parser.parse('2-2-2')
    assert_equal 2*2*2, @parser.parse('2*2*2')
    assert_equal 2**2**2, @parser.parse('2**2**2')
    assert_equal 4/2/2, @parser.parse('4/2/2')
    assert_equal 7%2%1, @parser.parse('7%2%1')
  end

  def test_03
    assert_equal 2+2-2, @parser.parse('2+2-2')
    assert_equal 2-2+2, @parser.parse('2-2+2')
    assert_equal 2*2+2, @parser.parse('2*2+2')
    assert_equal 2**2+2, @parser.parse('2**2+2')
    assert_equal 4/2+2, @parser.parse('4/2+2')
    assert_equal 7%2+1, @parser.parse('7%2+1')
  end
  
  def test_04
    assert_equal 2+(2-2), @parser.parse('2+(2-2)')
    assert_equal 2-(2+2), @parser.parse('2-(2+2)')
    assert_equal 2+(2*2), @parser.parse('2+(2*2)')
    assert_equal 2*(2+2), @parser.parse('2*(2+2)')
    assert_equal 2**(2+2), @parser.parse('2**(2+2)')
    assert_equal 4/(2+2), @parser.parse('4/(2+2)')
    assert_equal 7%(2+1), @parser.parse('7%(2+1)')
  end
  
  def test_05
    assert_equal -2+(2-2), @parser.parse('-2+(2-2)')
    assert_equal 2-(-2+2), @parser.parse('2-(-2+2)')
    assert_equal 2+(2*-2), @parser.parse('2+(2*-2)')
  end
  
  def test_06
    assert_equal (3/3)+(8-2), @parser.parse('(3/3)+(8-2)')
    assert_equal (1+3)/(2/2)*(10-8), @parser.parse('(1+3)/(2/2)*(10-8)')
    assert_equal (1*3)*4*(5*6), @parser.parse('(1*3)*4*(5*6)')
    assert_equal (10%3)*(2+2), @parser.parse('(10%3)*(2+2)')
    assert_equal 2**(2+(3/2)**2), @parser.parse('2**(2+(3/2)**2)')
    assert_equal (10/(2+3)*4), @parser.parse('(10/(2+3)*4)')
    assert_equal 5+((5*4)%(2+1)), @parser.parse('5+((5*4)%(2+1))')
  end
  
end