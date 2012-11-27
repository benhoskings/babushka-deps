dep 'Sublime Text.app' do
  source 'http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.1.dmg'
  version '>= 2.0.1'
end

dep 'Alfred.app' do
  sparkle 'http://media.alfredapp.com/update/appcast.xml'
end

dep 'Vim.app' do
  source 'http://macvim.org/OSX/files/binaries/OSX10_4/Vim7.0-univ.tar.bz2'
end

dep 'LaunchBar.app' do
  source 'http://www.obdev.at/downloads/launchbar/LaunchBar-5.1.3.dmg'
end

dep 'Dropbox.app' do
  source 'http://cdn.dropbox.com/Dropbox%201.2.49.dmg'
end

dep 'SizeUp.app' do
  source 'http://irradiatedsoftware.com/download/SizeUp.zip'
end

dep 'Google Chrome.app' do
  source 'https://dl-ssl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
end

dep 'Skitch.app' do
  source 'http://get.skitch.com/skitch.zip'
end

dep 'Skype.app' do
  source 'http://download.skype.com/macosx/Skype_2.8.0.851.dmg'
end

dep 'Transmit.app' do
  source 'http://www.panic.com/transmit/d/Transmit 4.0.zip'
end

dep 'Firefox.app' do
  source 'http://download.mozilla.org/?product=firefox-3.6.10&os=osx&lang=en-US'
end

dep 'Microsoft Office', :template => 'installer' do
  source 'http://ci.local/Office Installer.zip'
  prefix '/Applications/Microsoft Office 2011'
  provides %w[Excel Word PowerPoint Outlook].map {|i| "Microsoft #{i}.app" }
end
