words = File.read("./en.txt").strip.split
words = words.group_by(&:length)
count = {}
words.each do |len, list|
	count[len] = Hash.new(0)
	list.each do |word|
		word.chars.uniq.each do |c|
			count[len][c.to_sym] += 1
		end
	end
	rate = count[len].sort_by { |e| e.last }
	puts "#{len}个字母的单词："
	rate.each do |c, n|
		puts "\t#{c}:出现#{n}次"
	end
end