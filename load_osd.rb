def escape_double_quotes(string)
  string.gsub('"', '\\"')
end

prepared_shell_code = escape_double_quotes(File.read('osd.js')).gsub("\n", "\\\n")


command = %Q(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "#{prepared_shell_code}")
output = `#{command}`
puts output
