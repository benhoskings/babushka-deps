dep 'chrome trolled' do
  def troll cmd
    shell "#{cmd} ~/Pictures/trollface.icns '/Applications/Google Chrome.app/Contents/Resources/app.icns'"
  end
  met? { troll 'cmp' }
  meet { troll 'cp' }
end
