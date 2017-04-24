require 'pry'

STDOUT.sync = true

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

APPLICATIONS = [
  {
    name: 'Chrome',
    desktop_file_name: 'google-chrome',
  },
  {
    name: 'TeamViewer',
    desktop_file_name: 'com.teamviewer.TeamViewer',
  },
  {
    name: 'Emacs',
    desktop_file_name: 'emacs',
  },
  {
    name: 'Telegram',
    desktop_file_name: 'telegramdesktop',
  },
  {
    name: 'Nylas Mail',
    desktop_file_name: 'nylas-mail',
  },
  {
    name: 'Slack',
    desktop_file_name: 'slack',
  },
  {
    name: 'Tilix',
    desktop_file_name: 'com.gexperts.Tilix',
  },
  {
    name: 'RubyMine',
    desktop_file_name: 'rubymine',
  },
].map { |application| OpenStruct.new(application) }

class Performer
  def initialize
    @desktop_environment = GnomeShell.new
  end

  def perform(command)
    puts command
    @desktop_environment.show_notification(capitalize(command))
    perform_internal(command)
  end

  private

  def perform_internal(command)
    case command
    when /\Aclose current window\z/i
      @desktop_environment.close_current_window
    when /\Ashow abbreviations\z/i
      show_abbreviations
    when /\Aopen (.+)\z/i
      openable = $1
      application = APPLICATIONS.find { |application| application.name == openable }
      if application
        @desktop_environment.open_application(application)
      elsif openable.start_with?('~/dev')
        @desktop_environment.open_project(openable)
      elsif openable.start_with?('http')
        perform_internal('open Chrome')
        sleep 0.3
        perform_internal('press ctrl+t')
        sleep 0.3
        perform_internal("type #{openable}")
        perform_internal('press Return')
      end
    when /\Atype (.+)\z/i
      @desktop_environment.type($1)
    when /\Apress (.+)\z/i
      @desktop_environment.press($1)
    when /\Aexecute (.+)\z/i
      @desktop_environment.execute($1)
    when /\Aslack (.+)\z/i
      perform_internal('open Slack')
      perform_internal('press ctrl+2')
      perform_internal('press ctrl+k')
      @desktop_environment.type($1)
      perform_internal('press Return')
    when /\A([a-z]+) is not defined\z/i
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

  def open_application(application)
    if window_with_class_is_open(application)
      shell_eval("Main.activateWindow(Shell.AppSystem.get_default().lookup_desktop_wmclass('#{application.desktop_file_name}').get_windows()[0])")
    else
      shell_eval("Shell.AppSystem.get_default().lookup_desktop_wmclass('#{application.desktop_file_name}').activate()")
    end
  end

  def open_project(title)
    result = shell_eval("global.screen.get_workspace_by_index(0).list_windows().find(w => w.title.contains('[#{title}]'))")

    if result == ''
      `nohup rubymine #{title} &`
    else
      shell_eval("Main.activateWindow(global.screen.get_workspace_by_index(0).list_windows().find(w => w.title.contains('[#{title}]')))")
    end
  end

  def close_current_window
    shell_eval("global.display.focus_window.delete(0)")
  end

  def type(string)
    `xdotool type --delay 0 -- "#{escape_double_quotes(string)}"`
  end

  def press(key)
    `xdotool key #{key}`
  end

  def execute(command)
    `#{command}`
  end

  private

  def shell_eval(js_code)
    raw_result = `gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "#{js_code}"`
    _was_successful, quoted_result = raw_result.strip[1..-2].split(',').map(&:strip)
    quoted_result[1..-2]
  end

  def window_with_class_is_open(application)
    result = shell_eval("Shell.AppSystem.get_default().lookup_desktop_wmclass('#{application.desktop_file_name}').get_windows().length")

    result != '0'
  end
end

if __FILE__ == $PROGRAM_NAME
  performer = Performer.new
  performer.perform($stdin.gets.chomp) while true
end
