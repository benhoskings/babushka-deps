app 'Fluid.app' do
  source 'http://fluidapp.com/dist/Fluid_0.9.6.zip'
end

app 'RubyMine.app' do
  source 'http://download-ln.jetbrains.com/ruby/rubymine-2.0.2.dmg'
end

app 'Chromium.app' do
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

app 'Skype.app' do
  source 'http://download.skype.com/macosx/Skype_2.8.0.851.dmg'
end

app 'Coda.app' do
  source 'http://www.panic.com/coda/d/Coda 1.6.10.zip'
end

app 'Opera.app' do
  source 'http://mirror.aarnet.edu.au/pub/opera/mac/1052/Opera_10.52_Setup_Intel.dmg'
end
