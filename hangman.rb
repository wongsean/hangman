require 'json'

module Hangman
	class << self
		private
			def build_tree(chars, words, belongs_to_key)
				# No more guess needed if key doesn't contain any unknown letter
				unless belongs_to_key.include? '*'
					return {
						:message => 'completed',
						:value => belongs_to_key
					}
				end

				# 从可能单词中选出猜中几率最大的字母
				optimal_c = chars.max_by do |char|
					words.count { |word| word.include? char }
				end
				chars -= [optimal_c] # Do NOT ues Array#delete


				reg = Regexp.new("[#{chars.join}]")
				tree = words.group_by { |word| word.gsub reg, '*' }

				# build sub tree
				tree.each do |key, value|
					tree[key] = build_tree chars, value, key
				end

				# Return optimal solution and sub tree
				{
					:message => 'continue',
					:optimum => optimal_c,
					:value => tree
				}
			end
	end

	def self.build_decision_tree(word_list_file)
		words = File.read("./data/en.txt").upcase.strip.split
		tree = words.group_by do |word|
			'*' * word.size
		end
		tree.each do |key, value|
			tree[key] = build_tree ('A'..'Z').to_a, value, key
		end
	end

	def self.play(game)
		game.play
	end
end

time = Time.now
json = Hangman.build_decision_tree("./data/en.txt").to_json
File.open("./tree.json", "w") { |file| file.write json }
duration = Time.now - time
puts duration
