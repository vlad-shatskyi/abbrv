require 'pty'
STDOUT.sync = true

class Capturer
  CAPTURE_COMMAND = "stdbuf -oL -- libinput-debug-events --show-keycodes --device /dev/input/event0 | awk -F' ' '{ print $4, $6}'"

  def initialize
    @is_alt_pressed = false
    @abbreviation = ''
  end

  def on_abbreviation
    PTY.spawn(CAPTURE_COMMAND) do |stdout, _, _|
      stdout.each do |line|
        key, action = line.split(' ')

        if @is_alt_pressed
          letter = to_letter(key)
          if action == 'pressed' && allowed_letter?(letter)
            @abbreviation += letter
          elsif action == 'released' && alt?(key)
            if @abbreviation.size > 0
              yield @abbreviation
            end

            @is_alt_pressed = false
            @abbreviation = ''
          end
        elsif action == 'pressed' && alt?(key)
          @is_alt_pressed = true
        end
      end
    end
  end

  def alt?(key)
    key == 'KEY_LEFTALT' || key == 'KEY_RIGHTALT'
  end

  def allowed_letter?(key)
    '-=qwertyuiop[]asdfghjkl;\'zxcvbnm,./'.include?(key)
  end

  def to_letter(libnotify_key_name)
    key_name = libnotify_key_name.split('_').last.downcase
    case key_name
    when 'equal'
      '='
    when 'minus'
      '-'
    when 'semicolon'
      ';'
    else
      key_name
    end
  end
end

Capturer.new.on_abbreviation do |abbreviation|
  puts abbreviation
end
