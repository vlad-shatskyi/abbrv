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

def show_gnome_shell_notification(command)
  `gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'global.stage.remove_actor(text); text = new imports.gi.St.Label({ style_class: "helloworld-label", text: "#{command}" }); global.stage.add_actor(text); text.set_position(2500, 10); imports.mainloop.timeout_add(2000, () => global.stage.remove_actor(text))'`
end

while true
  command = $stdin.gets.chomp

  puts command
  show_gnome_shell_notification(command)
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
