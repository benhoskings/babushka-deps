app 'TextMate.app' do
  source 'http://download-b.macromates.com/TextMate_1.5.9.dmg'
end

app 'Fluid.app' do
  source 'http://fluidapp.com/dist/Fluid_0.9.6.zip'
end

app 'RubyMine.app' do
  source 'http://download.jetbrains.com/ruby/rubymine-2.0.1.dmg'
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
