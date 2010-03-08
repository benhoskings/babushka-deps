dep 'textmate' do
  requires 'TextMate.app', 'textmate helper'
end

dep 'textmate helper' do
  requires 'TextMate.app'
  met? { which 'mate' }
  meet { shell "ln -sf '#{app_dir('TextMate.app') / 'Contents/SharedSupport/Support/bin/mate'}' /usr/local/bin/mate" }
end

app 'TextMate.app' do
  source 'http://download-b.macromates.com/TextMate_1.5.9.dmg'
end
