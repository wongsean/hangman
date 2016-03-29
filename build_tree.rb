require 'json'

def build_tree chars, words, depth=1
	## debug
	#puts "=>"*depth + "#{chars.size}, #{words.size}"
	#print "=>" * depth
	#print words
	#print "\n"
	
	# 如果选项中只有一个单词了则表示已猜出
	if words.size == 1
		word = words.first
		return {
			:message => :found,
			:optimun => chars.reject {|char| !word.include? char}
		}
	end

	# 从可能单词中选出猜中几率最大的字母
	optimum_c = chars.max_by do |char|
		words.count do |word|
			word.include? char
		end
	end
	chars -= [optimum_c] # 不要用Array#delete
	#puts optimum_c # debug

	reg = Regexp.new("[^#{optimum_c}]")
	tree = words.group_by do |word|
		word.gsub reg, '*'
	end

	# 递归构建子树
	tree.keys.each do |key|
		tree[key] = build_tree(chars, tree[key], depth+1)
	end

	# 返回最优解和子树
	{
		:message => :continue,
		:optimun => optimum_c,
		:subtree => tree
	}
end

words = File.read("./data/en.txt").strip.split
tree = words.group_by(&:length) #{2=>{words}, 3=>{words} ...}
tree.keys.each do |key|
	tree[key] = build_tree(('a'..'z').to_a, tree[key])
end

puts JSON.generate(tree)