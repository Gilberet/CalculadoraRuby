#!/usr/bin/ruby
require 'stringio'
require 'set'

class Token
  attr_reader :type, :line, :col
  
  def initialize(type,lineNum,colNum)
    @type = type
    @line = lineNum
    @col = colNum
  end
end

class LexicalToken < Token
  attr_reader :lex
  
  def initialize(type,lex,lineNum,colNum)
    super(type,lineNum,colNum)
    
    @lex = lex
  end
end

class Scanner
  def initialize(inStream)
    @istream = inStream
    @keywords = Set.new(["S","R"])
    @lineCount = 1
    @colCount = -1
    @needToken = true
    @lastToken = nil
  end
  
  def putBackToken()
    @needToken = false
  end
  
  def getToken()
    if !@needToken
      @needToken = true
      return @lastToken
    end
    
    state = 0
    foundOne = false
    c = @istream.getc()
    
    if @istream.eof() then
      @lastToken = Token.new(:eof,@lineCount,@colCount)
      return @lastToken
    end
    
    while !foundOne
      @colCount = @colCount + 1
      case state
      when 0
        lex = ""
        column = @colCount
        line = @lineCount
        if isLetter(c) then state=1
        elsif isDigit(c) then state=2
        elsif c == ?+ then state = 3
        elsif c == ?- then state = 4
        elsif c == ?* then state = 5
        elsif c == ?/ then state = 6
        elsif c == ?( then state = 7
        elsif c == ?) then state = 8
        elsif c == ?% then state = 9
        elsif c == ?\n then
          @colCount = -1
          @lineCount = @lineCount+1
        elsif isWhiteSpace(c) then state = state #ignore whitespace
        elsif @istream.eof() then
          @foundOne = true
          type = :eof
        else
          puts "Unrecognized Token found at line ",line," and column ",column,"\n"
         # raise "Unrecognized Token"
        end
      when 1
        if isLetter(c) or isDigit(c) then state = 1
        else
          if @keywords.include?(lex) then
            foundOne = true
            type = :keyword
          else
            foundOne = true
            type = :identifier
          end
        end
      when 2
        if isDigit(c) then state = 2
        else
          type = :number
          foundOne = true
        end
      when 3
        type = :add
        foundOne = true
      when 4
        type = :sub
        foundOne = true
      when 5
        type = :times
        foundOne = true
      when 6
        type = :divide
        foundOne = true
      when 7
        type = :lparen
        foundOne = true
      when 8
        type = :rparen
        foundOne = true
      when 9
        type = :mod
        foundOne = true
      end
      
      if !foundOne then
        lex.concat(c)
        c = @istream.getc()
      end
      
    end
    
    @istream.ungetc(c)   
    @colCount = @colCount - 1
    if type == :number or type == :identifier or type == :keyword then
      t = LexicalToken.new(type,lex,line,column)
    else
      t = Token.new(type,line,column)
    end
    
    @lastToken = t
    return t 
  end
  
  private
  def isLetter(c) 
    return ((?a <= c and c <= ?z) or (?A <= c and c <= ?Z))
  end
  
  def isDigit(c)
    return (?0 <= c and c <= ?9)
  end
  
  def isWhiteSpace(c)
    return (c == ?\  or c == ?\n or c == ?\t)
  end
end

class BinaryNode
  attr_reader :left, :right
  
  def initialize(left,right)
    @left = left
    @right = right
  end
end

class UnaryNode
  attr_reader :subTree
  
  def initialize(subTree)
    @subTree = subTree
  end
end

class AddNode < BinaryNode
  def initialize(left, right)
    super(left,right)
  end
  
  def evaluate() 
    return @left.evaluate() + @right.evaluate()
  end
  def toEWE()
    return "#Start AddNode \n     sp := sp + tres \n#Calling node left child \n" + @left.toEWE() + "#Calling node rigth child \n     sp := sp - tres \n     tmp := M[sp+3] \n     M[sp+1] := tmp \n     sp := sp + tres \n#Calling node rigth child \n" + @right.toEWE() + "#Ending calling rigth child \n     sp := sp -tres \n     tmp := M[sp+3] \n     M[sp+2] := tmp \n     tmp := M[sp+1] \n     tmp2 := M[sp+2] \n     tmp := tmp + tmp2 \n     M[sp+0] := tmp \n#End AddNode\n"
  end
end

class SubNode < BinaryNode
  def initialize(left, right)
    super(left,right)
  end
  
  def evaluate() 
    return @left.evaluate() - @right.evaluate()
  end
  def toEWE()
    return "#Start SubNode \n     sp := sp + tres \n#Calling node left child \n" + @left.toEWE() + "#Calling node rigth child \n     sp := sp - tres \n     tmp := M[sp+3] \n     M[sp+1] := tmp \n     sp := sp + tres \n#Calling node rigth child \n" + @right.toEWE() + "#Ending calling rigth child \n   sp := sp -tres \n     tmp := M[sp+3] \n     M[sp+2] := tmp \n     tmp := M[sp+1] \n     tmp2 := M[sp+2] \n     tmp := tmp - tmp2 \n     M[sp+0] := tmp \n#End SubNode\n"
  end
end

class MulNode < BinaryNode
  def initialize(left, right)
    super(left,right)
  end
  
  def evaluate()
    return @left.evaluate() * @right.evaluate()
  end
  def toEWE()
    return "#Start MulNode \n     sp := sp + tres \n#Calling node left child \n" + @left.toEWE() + "#Calling node rigth child \n     sp := sp - tres \n     tmp := M[sp+3] \n     M[sp+1] := tmp \n     sp := sp + tres \n#Calling node rigth child \n" + @right.toEWE() + "#Ending calling rigth child \n    sp := sp -tres \n     tmp := M[sp+3] \n     M[sp+2] := tmp \n     tmp := M[sp+1] \n     tmp2 := M[sp+2] \n     tmp := tmp * tmp2 \n     M[sp+0] := tmp \n#End MulNode\n"
  end
end
class DivNode < BinaryNode
  def initialize(left, right)
    super(left,right)
  end
  def evaluate()
    return @left.evaluate() / @right.evaluate()
  end
  def toEWE()
    return "#Start DivNode \n     sp := sp + tres \n#Calling node left child \n" + @left.toEWE() + "#Calling node rigth child \n     sp := sp - tres \n     tmp := M[sp+3] \n     M[sp+1] := tmp \n     sp := sp + tres \n#Calling node rigth child \n" + @right.toEWE() + "#Ending calling rigth child \n   sp := sp -tres \n     tmp := M[sp+3] \n     M[sp+2] := tmp \n     tmp := M[sp+1] \n     tmp2 := M[sp+2] \n     tmp := tmp / tmp2 \n     M[sp+0] := tmp \n#End DivNode\n"
  end
end
class ModNode < BinaryNode
  def initialize(left, right)
    super(left,right)
  end
  def evaluate()
    return @left.evaluate() % @right.evaluate()
  end
  def toEWE()
    return "#Start ModNode \n     sp := sp + tres \n#Calling node left child \n" + @left.toEWE() + "#Calling node rigth child \n     sp := sp - tres \n     tmp := M[sp+3] \n     M[sp+1] := tmp \n     sp := sp + tres \n#Calling node rigth child \n" + @right.toEWE() + "#Ending calling rigth child \n   sp := sp -tres \n     tmp := M[sp+3] \n     M[sp+2] := tmp \n     tmp := M[sp+1] \n     tmp2 := M[sp+2] \n     tmp := tmp % tmp2 \n     M[sp+0] := tmp \n#End ModNode\n"
  end
end

class NumNode 
  def initialize(num)
    @num = num
  end
  
  def evaluate() 
    return @num
  end
  def toEWE()
    return "#Start NumNode \n     tmp := " + @num.to_s + "\n     M[sp+0] := tmp \n#End NumNode\n"
  end
end   

class StoreNode < UnaryNode
  
  def initialize(subTree)
    super(subTree)
  end
  def evaluate()
    $calc.memory = @subTree.evaluate()
    return $calc.memory
  end
  def toEWE()
    return "#Start StoreNode \n     sp := sp + uno \n#Calling StoreNode child \n" + @subTree.toEWE() + "#Ending Calling StoreNode child \n     sp := sp - uno \n    tmp := M[sp+1] \n     M[sp+0] := tmp \n     mem := tmp \n#End StoreNode\n"
  end
end

class NegateNode < UnaryNode

  def negate(subTree)
    super(subTree)
  end
  def evaluate()
    @subTree.evaluate()*-1
  end
   def toEWE()
     return "#Start NegateNode \n     sp := sp + uno \n#Start Calling NegateNode Child \n" + @subTree.toEWE() + "     sp := sp - uno\n     tmp := M[sp+1]\n     tmp := negateNum - tmp\n     M[sp+0] := tmp\n#Ending Calling NegateNode Child\n"
   end
end

class RecallNode
  
  def initialize() ; end
  
  def evaluate()
    return $calc.memory
  end
  def toEWE()
    return "#Start RecallNode \n     M[sp+0] := mem \n#End RecallNode\n"
  end
end

class Parser
  def initialize(istream)
    @scan = Scanner.new(istream)
  end
  
  def parse()
    return Prog()
  end
  
  private
  def Prog()
    result = Expr()
    t = @scan.getToken()
    
    if t.type != :eof then
      print "Expected EOF. Found ", t.type, ".\n"
      raise "Parse Error"
    end
    
    return result
  end
  
  def Expr() 
    return RestExpr(Term())
  end
  
  def RestExpr(e) 
    t = @scan.getToken()
    
    if t.type == :add then
      return RestExpr(AddNode.new(e,Term()))
    end
    
    if t.type == :sub then
      return RestExpr(SubNode.new(e,Term()))
    end
    
    @scan.putBackToken()
    
    return e
  end
  
  def Term()
    return RestTerm(Storable())
  end
    # Write your Term() code here. This code is just temporary
    # so you can try the calculator out before finishing it.
  def RestTerm(e)
    t = @scan.getToken()

    if t.type == :times then
      return RestTerm(MulNode.new(e,Storable()))
    end
    
    if t.type == :divide then
      return RestTerm(DivNode.new(e,Storable()))
    end
    
    if t.type == :mod then
      return RestTerm(ModNode.new(e,Storable()))
    end

    @scan.putBackToken()
    return e
  end
  
  def Storable()
    ast = Negate()
    t = @scan.getToken()
    if t.type == :keyword then
      if t.lex == "S" then
        return StoreNode.new(ast)
      else
        raise "Expected S"
      end
    else
      @scan.putBackToken()
    end
    return ast
  end

  def Negate()
    t = @scan.getToken()
    if t.type == :sub then
      return NegateNode.new(Factor())
    else
      @scan.putBackToken()
    end
    return Factor()
  end
  
  def Factor() 
    t = @scan.getToken()
    if t.type == :number then
      return NumNode.new(t.lex.to_i)
    else if t.type == :keyword then 
           if t.lex == "R" then
             return RecallNode.new()
           else
             raise "Expected R"
           end
         else if t.type == :lparen then
                ast = Expr()
                t = @scan.getToken()
                if t.type != :rparen then
                  raise "Expected )"
                end
                return ast
              else
                raise "Expected Number, R, ("
              end
         end                     
    end
  end
end
class Calculator
  attr_reader :memory
  attr_writer :memory

  def initialize()
    @memory = 0
  end

  if ARGV.size == 0
    option="no"
  elsif ARGV.size == 1
    option=ARGV.shift
  end

  def eval(expr)
    parser = Parser.new(StringIO.new(expr))
    ast = parser.parse()
    return ast.evaluate()
  end

  def codigoEWE(expr)
    parser = Parser.new(StringIO.new(expr))
    ast = parser.parse()
    return ast.toEWE()
  end
  
  if option == "-i"
    puts "Iterativo"
    print ">"
    while text = gets
      begin
        if text == :eof
          break
        else
          $calc = Calculator.new()
          puts "= " + $calc.eval(text).to_s
          print ">"
        end
      rescue
        puts "Parse Error"
        print ">"
      end
    end
  elsif option == "-c"
    puts "compilador de EWE"
    print ">"
    text = gets
    $calc = Calculator.new()
    File.open("a.ewe","w") do |m1|
      m1.puts "#The result is:\n#Start root tree\nmain: sp := 7 \n     negateNum := 0\n     uno := 1\n      tres := 3 \n      sp := sp + uno \n" << $calc.codigoEWE(text).to_s << "\n#End call subtree root \n     sp:= sp - uno \n     tmp := M[sp+1] \nwriteInt(tmp) \nhalt \nequ tmp       M[0] \nequ tmp2      M[1] \nequ negateNum M[2] \nequ uno       M[3] \nequ tres      M[4] \nequ mem       M[5]\nequ sp        M[6] \nequ stack     M[7]"
    end
  else
    print "Ingrese Expresion: "
    text = gets
    $calc = Calculator.new()
    puts "The result is " + $calc.eval(text).to_s
  end
end
