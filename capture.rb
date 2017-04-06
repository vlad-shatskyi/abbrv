require 'pty'
STDOUT.sync = true

cmd = "stdbuf -oL -- libinput-debug-events --show-keycodes --device /dev/input/event0 | awk -F' ' '{ print $4, $6}'"

is_alt_pressed = false
abbreviation = ''

def alt?(key)
  key == 'KEY_LEFTALT' || key == 'KEY_RIGHTALT'
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

PTY.spawn( cmd ) do |stdout, stdin, pid|
  # Do stuff with the output here. Just printing to show it works
  stdout.each do |line| 
    key, action = line.split(' ')

    if is_alt_pressed
      if action == 'pressed' && key != 'KEY_TAB'
        abbreviation += to_letter(key)
      elsif action == 'released' && alt?(key)
        if abbreviation.size > 0
          puts abbreviation 
          #exit
        end

        is_alt_pressed = false
        abbreviation = ''
      end
    else
      if action == 'pressed' && alt?(key)
        is_alt_pressed = true
      end
    end
  end
end
