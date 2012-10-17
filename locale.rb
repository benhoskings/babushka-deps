meta :locale do
  def locale_regex locale_name
    /#{locale_name}\.utf-?8/i
  end
  def local_locale locale_name
    shell('locale -a').split("\n").detect {|l|
      l[locale_regex(locale_name)]
    }
  end
end

dep 'set.locale', :locale_name do
  locale_name.default!('en_AU')
  requires 'exists.locale'.with(locale_name)
  met? {
    shell('locale').val_for('LANG')[locale_regex(locale_name)]
  }
  on :apt do
    meet {
      sudo("echo 'LANG=#{local_locale(locale_name)}' > /etc/default/locale")
    }
    after {
      log "Setting the locale doesn't take effect until you log out and back in."
    }
  end
end

dep 'exists.locale', :locale_name do
  met? {
    local_locale(locale_name)
  }
  meet {
    shell "locale-gen #{locale_name}.UTF-8", :log => true
  }
end
