require 'httparty'
require 'json'

module Hangman
	class game
		def initialize
			time = Time.now
			@tree = JSON.parse(File.read('./tree.json'))
			@highest_score = File.read('./scores.txt').strip.split.max { |a, b| a.to_i <=> b.to_i }
			duration = Time.now - time
			puts "took #{duration} seconds to load tree and highest_score"
		end

		def play
			init_game
			until @total_word_count == 80
				next_word
				guess_word
				get_result
			end
			submit_result if @score > @highest_score
		end

		private :init_game, :next_word, :guess_word, :guess, :get_result, :submit_result, :post

		def init_game
			data = {
				'playerId' => `git config --global user.email`.strip,
			  'action' => 'startGame'
			}
			rbody = post data
			@tree_node = @tree
			@session_id = rbody['sessionId']
			@total_word_count = 0
			@total_correct = 0
			@total_wrong = 0
			@current_wrong = 0
			@score = 0
		end

		def next_word
			data = {
				'sessionId' => @session_id,
				'action' => 'nextWord'
			}
			resp_body = post data
			@word = rbody['data']['word']
			@total_word_count = resp_body['data']['totalWordCount']
			puts '-' * 15 + " #{@total_word_count} #{@word} " + '-' * 15
		end

		def guess_word
			until @current_wrong == 10 || @tree_node[@word]['message'] == 'found'
				guess @tree_node[@word]['optimum']
				@tree_node = @tree_node[@word]['value']
			end
			puts @current_wrong == 10 ? 'WRONG!' : "CORRECT! it's #{@word}"
			return @current_wrong == 10 ? false : true
		end

		def guess(char)
			data = {
				'sessionId' => @session_id,
				'action' => 'guessWord',
				'guess' => char
			}
			resp_body = post data
			puts "guess #{tree[@word]['optimum']}, return #{rbody['data']['word']}, wrong count: #{rbody['data']['wrongGuessCountOfCurrentWord']}"

			@word = resp_body['data']['word']
			@current_wrong = rbody['data']['wrongGuessCountOfCurrentWord']
		end

		def get_result
			data = {
			  'sessionId' => @session_id,
			  'action' => 'getResult'	
			}
			resp_body = post data
			@total_word_count = resp_body['data']['totalWordCount']
			@total_correct = resp_body['data']['correctWordCount']
			@total_wrong = resp_body['data']['totalWrongGuessCount']
			@score = resp_body['data']['score']
			puts <<-EOB.gsub(/^\s+\|/, "\n")
				|totalWordCount: #{@total_word_count} 
				|correctWordCount: #{@total_correct}
				|totalWrongGuessCount: #{@total_wrong}
				|score: #{@score}
				|
			EOB
		end

		def submit_result
			data = {
				'sessionId' => @session_id,
				'action' => 'submitResult'
			}
			rbody = post data
			puts <<-EOB.gsub(/^\s+\|/, "\n")
				|
				|-----------------------------------------------------
				|submitted!
				|totalWordCount: #{rbody['data']['totalWordCount']} 
				|correctWordCount: #{rbody['data']['correctWordCount']}
				|totalWrongGuessCount: #{rbody['data']['totalWrongGuessCount']}
				|score: #{rbody['data']['score']}
			EOB
			File.open('./scores.txt', 'a') { |file| file.puts @score }
		end

		def post data
			url = 'https://strikingly-hangman.herokuapp.com/game/on'
			option = {
				headers: { 'Content-Type' => 'application/json' },
				body: data.to_json
			}
			resp = nil
			loop do
				begin
					resp = HTTParty.post url, option	
					break if resp && resp.success?
					puts "post action not success, try again"
				rescue Net::ReadTimeout
					puts "post action timeout, try again"
					sleep 3
					next
				end
			end
			rbody = JSON.parse(resp.body)
		end
	end
end

h = Hangman.new
while true
	h.next_word
	h.guess_word
	h.get_result
end
