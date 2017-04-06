require 'json'
STDOUT.sync = true

while true
  abbreviation = $stdin.gets.chomp
  language = JSON.parse(File.read('language.json'))
  puts language[abbreviation] || "#{abbreviation} is not defined"
end
