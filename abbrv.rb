require_relative 'capture'
require_relative 'expand'
require_relative 'perform'

language_file_path = ARGV.first
expander = Expander.new(language_file_path)
performer = Performer.new

Capturer.new.on_abbreviation do |abbreviation|
  performer.perform(expander.expand(abbreviation))
end
