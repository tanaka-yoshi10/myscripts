require 'csv'

def usage
  puts 'usage : cmd <file>'
  puts 'make the settlement csv from money forward csv'
  exit
end

# Main process
usage if ARGV.size < 1
infilename = ARGV[0]
exit unless FileTest.exist?( infilename )

outfilename = File.expand_path("../#{File.basename(infilename, '.*')}_rslt.csv", infilename)

File.open(outfilename, 'w' ) do |out_file|
  out_file.puts 'date,content,amount,account,major_category,minor_category,memo,check,HT,M,Y,W,HT,M,Y,W'
  CSV.foreach(infilename, headers: :first_row, encoding: 'Shift_JIS:UTF-8') do |a_word|
    next if a_word['計算対象'] == '0'
    next if a_word[3].to_i > 0  # income

    output = []
    for i in 1..7 ; output << a_word[i] ; end
    output << '' # output[7] for check

    # Rules for Investiment
    case a_word[4] # account
      when /^ht_/ ; output += [1.0, 0.0, 0.0, 0.0]
      when /^m_/  ; output += [0.0, 1.0, 0.0, 0.0]
      when /^y_/  ; output += [0.0, 0.0, 1.0, 0.0]
      when /^w_/  ; output += [0.0, 0.0, 0.0, 1.0]
      else
        output += [0.0,0.0,0.0,0.0] ; output[7] << 'unknown_account;'
    end

    # Rules for Expenses
    major = a_word[5].encode('UTF-8') ; minor = a_word[6].encode('UTF-8')
    content = a_word[2].encode('UTF-8')

    if minor[0] != '['
      output += [0.0,0.0,0.0,0.0] ; output[7] << 'unknown_category;'
    elsif major == '通信費' ; output += [0.25, 0.0, 0.5, 0.25]
    elsif content == 'FeBe'; output += [0.0, 0.0, 1.0, 0.0]
    elsif content =~ /ブリアン/ ; output += [0.0, 0.0, 1.0, 0.0]
    elsif minor =~ /NT\]$/ ; output += [0.25, 0.0, 0.5, 0.25]
    elsif minor =~ /MY\]$/ ; output += [0.0, 0.0, 1.0, 0.0]
    elsif minor =~ /MW\]$/ ; output += [0.0, 0.5, 0.0, 0.5]
    elsif minor =~ /HT\]$/ ; output += [1.0, 0.0, 0.0, 0.0]
    elsif minor =~ /M\]$/  ; output += [0.0, 1.0, 0.0, 0.0]
    elsif minor =~ /Y\]$/  ; output += [0.0, 0.0, 1.0, 0.0]
    elsif minor =~ /W\]$/  ; output += [0.0, 0.0, 0.0, 1.0]
    else
      output += [0.0,0.0,0.0,0.0] ; output[7] << 'need to input;'
    end

    output.each { |a| out_file.print "\"#{a}\"," }
    out_file.puts
  end
end
