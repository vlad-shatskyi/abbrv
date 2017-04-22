require 'pry'

STDOUT.sync = true

def close_current_window
  `xdotool getactivewindow windowkill`
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

def capitalize(sentence)
  sentence.split(' ').map(&:capitalize).join(' ')
end

class Performer
  def initialize
    @desktop_environment = GnomeShell.new
  end

  def perform(command)
    puts command
    @desktop_environment.show_notification(capitalize(command))
    case command
    when 'close current window'
      close_current_window
    when 'show abbreviations'
      show_abbreviations
    when /\Afocus ([^ ]+)\z/
      @desktop_environment.focus_or_launch($1)
    when /\Aopen ([^ ]+)\z/
      open($1)
    when /\Atype (.+)\z/
      @desktop_environment.type($1)
    when /\Aexecute (.+)\z/
      @desktop_environment.execute($1)
    when /\A([a-z]+) is not defined\z/
      error %Q(Shortcut '#{$1}' is not defined. Ignoring...)
    else
      error %Q(Don't know how to handle '#{command}'. Ignoring...)
    end
  end
end

class DesktopEnvironment
  def show_notification(message)
    fail NotImplementedError
  end

  def launch_or_focus(window)
    fail NotImplementedError
  end

  def type(string)
    fail NotImplementedError
  end

  def execute(command)
    fail NotImplementedError
  end
end

class GnomeShell < DesktopEnvironment
  def initialize
    prepared_shell_code = escape_double_quotes(File.read('osd.js')).gsub("\n", "\\\n")
    shell_eval(prepared_shell_code)
  end

  def show_notification(message)
    prepared_command = escape_double_quotes(message).gsub("\n", "\\\n")
    shell_eval("new OsdWindow('#{prepared_command}').show();")
  end

  def focus_or_launch(window)
    if window.start_with?('~/dev')
      _was_successful, result = shell_eval("global.screen.get_workspace_by_index(0).list_windows().find(w => w.title.contains('[#{window}]'))").strip[1..-2].split(',').map(&:strip)

      if result == "''"
        `nohup rubymine #{window} &`
      else
        shell_eval("Main.activateWindow(global.screen.get_workspace_by_index(0).list_windows().find(w => w.title.contains('[#{window}]')))")
      end
    else
      shell_eval("Main.activateWindow(global.screen.get_workspace_by_index(0).list_windows().find(w => w.get_wm_class() == '#{window}'))")
    end
  end

  def type(string)
    `xdotool type --clearmodifiers --delay 0 -- "#{string}"`
  end

  def execute(command)
    `#{command}`
  end

  private

  def shell_eval(js_code)
    `gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "#{js_code}"`
  end
end

if __FILE__ == $PROGRAM_NAME
  performer = Performer.new
  performer.perform($stdin.gets.chomp) while true
end
