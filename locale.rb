meta :locale do
  def locale_regex
    /en_(AU|US)\.utf-?8/i
  end
  def local_locale
    shell('locale -a').split("\n").detect {|l|
      l[locale_regex]
    }
  end
end

dep 'set.locale' do
  requires 'exists.locale'
  met? {
    shell('locale').val_for('LANG')[locale_regex]
  }
  on :apt do
    meet {
      sudo("echo 'LANG=#{local_locale}' > /etc/default/locale")
    }
    after {
      log "Setting the locale doesn't take effect until you log out and back in."
    }
  end
end

dep 'exists.locale' do
  met? { local_locale }
end
