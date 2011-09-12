# dep 'rubycocoa' do
#   requires 'ruby'
#   merge :versions, :rubycocoa => '0.13.2'
#   source "http://sourceforge.net/projects/rubycocoa/files/RubyCocoa/#{var(:versions)[:rubycocoa]}/RubyCocoa-#{var(:versions)[:rubycocoa]}.tgz/download"
#   source_filename "RubyCocoa-#{var(:versions)[:rubycocoa]}"
# 
#   preconfigure { change_line '<string>&gt;=</string>', '<string>=</string>', 'package/tmpl/Info.plist' }
#   configure { shell "ruby install.rb config --build-universal=no" }
#   build { shell "ruby install.rb setup" }
#   install { sudo "ruby install.rb install" }
# end
