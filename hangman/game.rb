require 'httparty'
require 'json'

module Hangman
  class Game
    URL = 'https://strikingly-hangman.herokuapp.com/game/on'
    attr_accessor :score, :highest_score
    def initialize(player_id = nil) 
      time = Time.now
      @player_id = player_id || `git config --global user.email`.strip
      @tree = JSON.parse(File.read('./tree.json'))
      @highest_score = File.read('./scores.txt').strip.split.max { |a, b| a.to_i <=> b.to_i }.to_i
      duration = Time.now - time
      puts "took #{duration} seconds to load tree and highest score"
    end

    def play
      init_game
      puts '========= new game ========='
      puts "highest score: #{@highest_score}"
      until @total_word_count == 80
        next_word
        guess_word
        get_result

        # uncomment to get high score
        # return unless @total_word_count - @total_correct <= 1
      end
      submit_result if @score > @highest_score
    end

    def init_game
      data = {
        'playerId' => @player_id,
        'action' => 'startGame'
      }
      resp_body = post data
      @session_id = resp_body['sessionId']
      @total_word_count = 0
      @total_correct = 0
      @total_wrong = 0
      @score = 0
    end

    def next_word
      data = {
        'sessionId' => @session_id,
        'action' => 'nextWord'
      }
      resp_body = post data
      @word = resp_body['data']['word']
      @total_word_count = resp_body['data']['totalWordCount']
      puts '-' * 15 + " #{@total_word_count} #{@word} " + '-' * 15
    end

    def guess_word
      @tree_node = @tree
      @current_wrong = 0
      while @word.include? Hangman::UNKNOWN_LETTER
        guess @tree_node[@word]['c']
        break if @current_wrong == 10
        break if @tree_node[@word].nil?
      end

      case
      when !@word.include?(Hangman::UNKNOWN_LETTER)
        puts "CORRECT! it's #{@word}"
      when @current_wrong == 10
        puts 'WRONG 10 times'
      when @tree_node[@word].nil?
        puts "#{@word} cannot be found in word list, skipping this word..."
      else
        puts "unknown situation: #{@tree_node[@word]}, #{@word}"
      end
    end

    def guess(char)
      data = {
        'sessionId' => @session_id,
        'action' => 'guessWord',
        'guess' => char
      }
      resp_body = post data
      puts "guess #{@tree_node[@word]['c']}, return #{resp_body['data']['word']}, wrong count: #{resp_body['data']['wrongGuessCountOfCurrentWord']}"

      @tree_node = @tree_node[@word]['t']
      @word = resp_body['data']['word']
      @current_wrong = resp_body['data']['wrongGuessCountOfCurrentWord']
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
      puts <<-EOB.gsub(/^\s+\|/, '')
        |result:
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
      resp_body = post data
      puts <<-EOB.gsub(/^\s+\|/, '')
        |
        |-----------------------------------------------------
        |submitted!
        |totalWordCount: #{resp_body['data']['totalWordCount']} 
        |correctWordCount: #{resp_body['data']['correctWordCount']}
        |totalWrongGuessCount: #{resp_body['data']['totalWrongGuessCount']}
        |score: #{resp_body['data']['score']}
      EOB
      File.open('./scores.txt', 'a') { |file| file.puts @score }
      #File.open('./submit.txt', "a") do |file|  
      # file.puts <<-EOB.gsub(/^\s+\|/, '')
      #   |-----------------------------------------------------
      #   |submitted!
      #   |totalWordCount: #{resp_body['data']['totalWordCount']} 
      #   |correctWordCount: #{resp_body['data']['correctWordCount']}
      #   |totalWrongGuessCount: #{resp_body['data']['totalWrongGuessCount']}
      #   |score: #{resp_body['data']['score']}
      # EOB
      #end

    end

    def post data
      option = {
        headers: { 'Content-Type' => 'application/json' },
        body: data.to_json
      }
      resp = nil
      loop do
        begin
          resp = HTTParty.post URL, option 
          break if resp && resp.success?
          puts "post action not success, try again"
        rescue Net::ReadTimeout, Net::OpenTimeout
          puts "post action timeout, try again"
          sleep 3
          next
        end
      end
      resp_body = JSON.parse(resp.body)
    end

    private :init_game, :next_word, :guess_word, :guess, :get_result, :submit_result, :post
  end
end