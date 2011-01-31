dep 'Xerox C3290.installer' do
  source 'http://files.droplr.com/files/8046732/uVNW.Xerox%20C3290%20driver.dmg'
  met? {
    [
      '/Library/Printers/PPDs/Contents/Resources/FX DocuPrint C3290 FS PS.gz',
      '/Library/Printers/FujiXerox/PDEs/FXPSACJHAccount.plugin',
      '/Library/Printers/FujiXerox/PDEs/FXPSACJHAccount.plugin'
    ].all? {|f|
      f.p.exists?
    }
  }
end
