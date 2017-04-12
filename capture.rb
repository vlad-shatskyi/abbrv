require 'pty'
STDOUT.sync = true

class Capturer
  CAPTURE_COMMAND = "stdbuf -oL -- libinput-debug-events --show-keycodes --device /dev/input/event0 | awk -F' ' '{ print $4, $6}'"
  LETTERS_TO_CAPTURE = '-=qwertyuiop[]asdfghjkl;\'zxcvbnm,./'

  KEYS_MAPPING = {
    'grave' => '`',
    'equal' => '=',
    'minus' => '-',
    'semicolon' => ';'
  }

  def initialize
    @should_capture = false
    @captured = ''
  end

  def on_abbreviation
    PTY.spawn(CAPTURE_COMMAND) do |stdout, _, _|
      stdout.each do |line|
        key, action = line.split(' ')
        letter = to_letter(key)

        if alt?(key)
          if action == 'pressed'
            @should_capture = true
          elsif action == 'released'
            yield @captured unless @captured.empty?

            @should_capture = false
            @captured = ''
          end
        elsif @should_capture && LETTERS_TO_CAPTURE.include?(letter) && action == 'pressed'
          @captured += letter
        end
      end
    end
  end

  private

  def alt?(key)
    key == 'KEY_LEFTALT' || key == 'KEY_RIGHTALT'
  end

  def to_letter(libnotify_key_name)
    key_name = libnotify_key_name.split('_').last.downcase
    KEYS_MAPPING.fetch(key_name, key_name)
  end
end

if __FILE__ == $PROGRAM_NAME
  Capturer.new.on_abbreviation do |abbreviation|
    puts abbreviation
  end
end
