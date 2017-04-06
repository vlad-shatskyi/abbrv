STDOUT.sync = true

def close_current_window
  `xdotool getactivewindow windowkill`
end

def launch_or_focus(window_name)
  `wmctrl -a #{window_name}`
end

def open(openable)
  `gio open #{openable}`
end

def error(message)
  escaped_message = message.gsub('"', '\\"')
  `notify-send  --hint=int:transient:1 --hint=string:sound-name:bell "#{escaped_message}"`
end

while true
  command = $stdin.gets.chomp

  puts command
  case command
  when 'close current window'
    close_current_window
  when /^focus ([a-z]+)$/
    launch_or_focus($1)
  when /^open ([^ ]+)$/
    open($1)
  when /^([a-z]+) is not defined$/
    error %Q(Shortcut '#{$1}' is not defined. Ignoring...)
  else
    error %Q(Don't know how to handle '#{command}'. Ignoring...)
  end
end
