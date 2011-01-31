dep 'LaunchBar.app' do
  source 'http://www.obdev.at/downloads/launchbar/LaunchBar-5.0.3.dmg'
end

dep 'Dropbox.app' do
  source 'http://cdn.dropbox.com/Dropbox%201.0.20.dmg'
end

dep 'SizeUp.app' do
  source 'http://irradiatedsoftware.com/download/SizeUp.zip'
end

dep 'Cinch.app' do
  source 'http://irradiatedsoftware.com/download/Cinch.zip'
end

dep 'Fluid.app' do
  source 'http://fluidapp.com/dist/Fluid_0.9.6.zip'
end

dep 'RubyMine.app' do
  source 'http://download-ln.jetbrains.com/ruby/rubymine-2.0.2.dmg'
end

dep 'Google Chrome.app' do
  source 'https://dl-ssl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
end

dep 'Chromium.app' do
  requires_when_unmet "Chromium.app download cleared"
  source L{
    "http://build.chromium.org/buildbot/snapshots/chromium-rel-mac/#{version}/chrome-mac.zip"
  }
  latest_version {
    shell "curl http://build.chromium.org/buildbot/snapshots/chromium-rel-mac/LATEST"
  }
  current_version {|path|
    IO.read(path / 'Contents/Info.plist').xml_val_for('SVNRevision')
  }
end

# TODO better version handling will make this unnecessary.
dep "Chromium.app download cleared" do
  met? { in_download_dir { !'chrome-mac.zip'.p.exists? } }
  meet { in_download_dir { 'chrome-mac.zip'.p.rm } }
end

dep 'Skype.app' do
  source 'http://download.skype.com/macosx/Skype_2.8.0.851.dmg'
end

dep 'Coda.app' do
  source 'http://www.panic.com/coda/d/Coda 1.6.10.zip'
end

dep 'Transmit.app' do
  source 'http://www.panic.com/transmit/d/Transmit 4.0.zip'
end

dep 'Opera.app' do
  source 'http://mirror.aarnet.edu.au/pub/opera/mac/1052/Opera_10.52_Setup_Intel.dmg'
end

dep 'pomodoro.app' do
  source L { "http://pomodoro.ugolandini.com/pages/downloads_files/pomodoro-#{version}.zip" }
  latest_version { from_page 'http://www.apple.com/downloads/macosx/development_tools/pomodoro.html', /<h2>Pomodoro\s*(\S*)</ }
  current_version { |path| bundle_version(path, 'CFBundleVersion') }
end

dep 'Firefox.app' do
  source 'http://download.mozilla.org/?product=firefox-3.6.10&os=osx&lang=en-US'
end

dep 'Airfoil.app' do
  source 'http://www.rogueamoeba.com/airfoil/download/Airfoil.zip'
end
