require 'csv'

def usage
  puts 'usage : cmd <file>'
  puts 'make the settlement csv from money forward csv'
  exit
end

# Main process
usage if ARGV.empty?
infilename = ARGV[0]
exit unless FileTest.exist?(infilename)

outfilename = File.expand_path("../#{File.basename(infilename, '.*')}_rslt.csv", infilename)

File.open(outfilename, 'w') do |out_file|
  out_file.puts 'date,content,amount,account,major_category,minor_category,memo,check,HT,M,Y,W,HT,M,Y,W,C'
  CSV.foreach(infilename, headers: :first_row, encoding: 'Shift_JIS:UTF-8') do |input_row|
    next if input_row['計算対象'] == '0'
    next if input_row['金額（円）'].to_i > 0 # 収入は見ない

    output = input_row[1..7]
    output << '' # output[7] for check

    # Rules for Investiment
    case input_row['保有金融機関']
    when /^ht_/
      output += [1.0, 0.0, 0.0, 0.0]
    when /^m_/
      output += [0.0, 1.0, 0.0, 0.0]
    when /^y_/
      output += [0.0, 0.0, 1.0, 0.0]
    when /^w_/
      output += [0.0, 0.0, 0.0, 1.0]
    else
      output += [0.0, 0.0, 0.0, 0.0]
      output[7] << 'unknown_account;'
    end

    # Rules for Expenses
    major = input_row['大項目'].encode('UTF-8')
    minor = input_row['中項目'].encode('UTF-8')
    content = input_row['内容'].encode('UTF-8')

    if minor[0] != '[' # MoneyForwardで自動で振り分けられた場合
      output += [0.0, 0.0, 0.0, 0.0, 0.0]
      output[7] << 'unknown_category;'
    elsif major == '通信費'
      output += [0.25, 0.0, 0.5, 0.25, 0.0]
    elsif content == 'FeBe'
      output += [0.0, 0.0, 1.0, 0.0, 0.0]
    elsif content =~ /ブリアン/
      output += [0.0, 0.0, 1.0, 0.0, 0.0]
    elsif minor =~ /NT\]$/
      output += [0.25, 0.0, 0.5, 0.25, 0.0]
    elsif minor =~ /MY\]$/
      output += [0.0, 0.0, 1.0, 0.0, 0.0]
    elsif minor =~ /MW\]$/
      output += [0.0, 0.5, 0.0, 0.5, 0.0]
    elsif minor =~ /HT\]$/
      output += [1.0, 0.0, 0.0, 0.0, 0.0]
    elsif minor =~ /M\]$/
      output += [0.0, 1.0, 0.0, 0.0, 0.0]
    elsif minor =~ /Y\]$/
      output += [0.0, 0.0, 1.0, 0.0, 0.0]
    elsif minor =~ /W\]$/
      output += [0.0, 0.0, 0.0, 1.0, 0.0]
    elsif minor =~ /C\]$/
      output += [0.0, 0.0, 0.0, 0.0, 1.0]
    else
      output += [0.0, 0.0, 0.0, 0.0, 0.0]
      output[7] << 'need to input;'
    end

    out_file.puts output.map { |e| %("#{e}") }.join(',')
  end
end
