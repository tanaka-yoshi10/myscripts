def usage
	puts "usage : cmd <file>"
	puts "make the settlement csv from money forward csv"
	exit
end


# Main process
usage if ARGV.size < 1
infilename = ARGV[0]
exit unless FileTest.exist?( infilename )
outfilename = File.dirname(infilename) + "\\" + File.basename(infilename, ".*") + "_rslt.csv"
h_files = {
  'IN'  => open(  infilename, "r" ),
  'OUT' => open( outfilename, "w" )
}

# line 1
line =  h_files['IN'].gets
h_files['OUT'].puts "date,content,amount,account,major_category,minor_category,memo,check,HT,M,Y,W,HT,M,Y,W,C"

while line =  h_files['IN'].gets

  line.chomp! unless line==nil
  a_word = line.split("\"\,\"")

	next if a_word[0]=="\"0"    # don't calculate
	next if a_word[3].to_i > 0  # income

	output = []
	for i in 1..7 ; output << a_word[i] ; end
	output << "" # output[7] for check

  # Rules for Investiment
	case a_word[4] # account
	when /^ht_/ ; output += [1.0, 0.0, 0.0, 0.0]
  when /^m_/  ; output += [0.0, 1.0, 0.0, 0.0]
  when /^y_/  ; output += [0.0, 0.0, 1.0, 0.0]
  when /^w_/  ; output += [0.0, 0.0, 0.0, 1.0]
  else
		output += [0.0,0.0,0.0,0.0] ; output[7] << "unknown_account;"
  end

  # Rules for Expenses
	major = a_word[5].encode("UTF-8") ; minor = a_word[6].encode("UTF-8")
	content = a_word[2].encode("UTF-8")

  if minor[0] != "["
		output += [0.0,0.0,0.0,0.0,0.0] ; output[7] << "unknown_category;"
	elsif major == "通信費" ; output += [0.25, 0.0, 0.5, 0.25, 0.0]
	elsif content == "FeBe"; output += [0.0, 0.0, 1.0, 0.0, 0.0]
	elsif content =~ /ブリアン/ ; output += [0.0, 0.0, 1.0, 0.0, 0.0]
	elsif minor =~ /NT\]$/ ; output += [0.25, 0.0, 0.5, 0.25, 0.0]
	elsif minor =~ /MY\]$/ ; output += [0.0, 0.0, 1.0, 0.0, 0.0]
  elsif minor =~ /MW\]$/ ; output += [0.0, 0.5, 0.0, 0.5, 0.0]
	elsif minor =~ /HT\]$/ ; output += [1.0, 0.0, 0.0, 0.0, 0.0]
	elsif minor =~ /M\]$/  ; output += [0.0, 1.0, 0.0, 0.0, 0.0]
	elsif minor =~ /Y\]$/  ; output += [0.0, 0.0, 1.0, 0.0, 0.0]
	elsif minor =~ /W\]$/  ; output += [0.0, 0.0, 0.0, 1.0, 0.0]
	elsif minor =~ /C\]$/ ; output += [0.0, 0.0, 0.0, 0.0, 1.0]
	else
		output += [0.0,0.0,0.0,0.0,0.0] ; output[7] << "need to input;"
  end

	output.each { |a| ; h_files['OUT'].print "\"#{a}\"," }
  h_files['OUT'].puts

end


### close output files
h_files.each_value { |f| ; unless f.closed? ; f.close ; end }
