require 'pry'

STDOUT.sync = true

def close_current_window
  `xdotool getactivewindow windowkill`
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
    case command.downcase
    when 'close current window'
      close_current_window
    when 'show abbreviations'
      show_abbreviations
    when /\Aopen (.+)\z/
      @desktop_environment.focus_or_launch($1)
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
  APPLICATIONS = [
    {
      name: 'Chrome',
      wm_class: 'Google-chrome',
      desktop_file_name: 'google-chrome',
    },
    {
      name: 'TeamViewer',
      wm_class: 'TeamViewer',
      desktop_file_name: 'com.teamviewer.TeamViewer',
    },
    {
      name: 'Emacs',
      wm_class: 'Emacs',
      desktop_file_name: 'emacs',
    },
    {
      name: 'Telegram',
      wm_class: 'TelegramDesktop',
      desktop_file_name: 'telegramdesktop',
    },
    {
      name: 'Nylas Mail',
      wm_class: 'Nylas Mail',
      desktop_file_name: 'nylas-mail',
    },
    {
      name: 'Slack',
      wm_class: 'Slack',
      desktop_file_name: 'slack',
    },
    {
      name: 'Tilix',
      wm_class: 'Tilix',
      desktop_file_name: 'com.gexperts.Tilix',
    },
    {
      name: 'RubyMine',
      wm_class: 'jetbrains-rubymine',
      desktop_file_name: 'rubymine',
    },
  ].map { |application| OpenStruct.new(application) }

  def initialize
    prepared_shell_code = escape_double_quotes(File.read('osd.js')).gsub("\n", "\\\n")
    shell_eval(prepared_shell_code)
  end

  def show_notification(message)
    prepared_command = escape_double_quotes(message).gsub("\n", "\\\n")
    shell_eval("new OsdWindow('#{prepared_command}').show();")
  end

  def focus_or_launch(window)
    application = APPLICATIONS.find { |application| application.name.downcase == window }
    if application
      if window_with_class_is_open(application.wm_class)
        shell_eval("Main.activateWindow(global.screen.get_workspace_by_index(0).list_windows().find(w => w.get_wm_class() == '#{application.wm_class}'))")
      else
        shell_eval("Shell.AppSystem.get_default().lookup_desktop_wmclass('#{application.desktop_file_name}').activate()")
      end
    elsif window.start_with?('~/dev')
      _was_successful, result = shell_eval("global.screen.get_workspace_by_index(0).list_windows().find(w => w.title.contains('[#{window}]'))").strip[1..-2].split(',').map(&:strip)

      if result == "''"
        `nohup rubymine #{window} &`
      else
        shell_eval("Main.activateWindow(global.screen.get_workspace_by_index(0).list_windows().find(w => w.title.contains('[#{window}]')))")
      end
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

  def window_with_class_is_open(window_class)
    _was_successful, result = shell_eval("global.screen.get_workspace_by_index(0).list_windows().find(w => w.get_wm_class() == '#{window_class}')").strip[1..-2].split(',').map(&:strip)

    result != "''"
  end
end

if __FILE__ == $PROGRAM_NAME
  performer = Performer.new
  performer.perform($stdin.gets.chomp) while true
end
