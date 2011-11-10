class MadLib

  def ask(word)
    print "Give me #{word}: "
    $stdin.gets.chomp
  end

  def play(file)
    keywords = {}
    story = file.read.gsub(/\(\((.+?)\)\)/) do
      word = $1
      if word =~ /(.+):(.+)/
        keywords[$1] = ask($2)
      elsif keywords.include?(word)
        keywords[word]
      else
        ask(word)
      end
    end
    
    puts
    print story
  end
  
end

raise "No template is given!" if ARGV.length < 1

File.open(ARGV[0]) do |file|
  MadLib.new.play(file)
end
