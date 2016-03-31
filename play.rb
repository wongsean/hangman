require_relative 'hangman'

if Dir.glob('tree.json').empty?
  puts 'building decision tree, please waiting...(will take several minutes)'
  time = Time.now
  json = Hangman.build_decision_tree('./data/en.txt').to_json
  File.open('./tree.json', 'w') { |file| file.write json }
  duration = Time.now - time
  puts "took #{duration} seconds"
end


game = Hangman::Game.new

Hangman.play game