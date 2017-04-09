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

def show_abbreviations
  `gedit language.json`
end

def escape_double_quotes(string)
  string.gsub('"', '\\"')
end

def error(message)
  `notify-send  --hint=int:transient:1 --hint=string:sound-name:bell "#{escape_double_quotes(message)}"`
end

def show_gnome_shell_notification(command)
  prepared_command = escape_double_quotes(command).gsub("\n", "\\\n")
  `gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "new OsdWindow('#{prepared_command}').show();"`
end

def capitalize(sentence)
  sentence.split(' ').map(&:capitalize).join(' ')
end

prepared_shell_code = escape_double_quotes(File.read('osd.js')).gsub("\n", "\\\n")
`gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "#{prepared_shell_code}"`

while true
  command = $stdin.gets.chomp

  puts command
  show_gnome_shell_notification(capitalize(command))
  case command
  when 'close current window'
    close_current_window
  when 'show abbreviations'
    show_abbreviations
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
