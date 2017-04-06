require 'json'
STDOUT.sync = true
language_file_path = ARGV.first

while true
  abbreviation = $stdin.gets.chomp
  language = JSON.parse(File.read(language_file_path))
  puts language[abbreviation] || "#{abbreviation} is not defined"
end
