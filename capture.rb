require 'pty'
STDOUT.sync = true

cmd = "stdbuf -oL -- libinput-debug-events --show-keycodes --device /dev/input/event0 | awk -F' ' '{ print $4, $6}'"

is_alt_pressed = false
abbreviation = ''

PTY.spawn( cmd ) do |stdout, stdin, pid|
  # Do stuff with the output here. Just printing to show it works
  stdout.each do |line| 
    key, action = line.split(' ')

    if is_alt_pressed
      if action == 'pressed' && key != 'KEY_TAB'
        abbreviation += key.chars.last.downcase
      elsif action == 'released' && key == 'KEY_LEFTALT'
        if abbreviation.size > 0
          puts abbreviation 
          #exit
        end

        is_alt_pressed = false
        abbreviation = ''
      end
    else
      if action == 'pressed' && key == 'KEY_LEFTALT'
        is_alt_pressed = true
      end
    end
  end
end
