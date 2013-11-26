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
  deprecated! "2013-12-12", :method_name => "'benhoskings:set.locale'", :callpoint => false, :instead => "'common:set.locale'"
  locale_name.default!('en_AU')
  requires 'exists.locale'.with(locale_name)
  met? {
    shell('locale').val_for('LANG')[locale_regex(locale_name)]
  }
  meet {
    if Babushka.host.matches?(:arch)
      sudo("echo 'LANG=#{local_locale(locale_name)}' > /etc/locale.conf")
    elsif Babushka.host.matches?(:apt)
      sudo("echo 'LANG=#{local_locale(locale_name)}' > /etc/default/locale")
    elsif Babushka.host.matches?(:bsd)
      sudo("echo 'LANG=#{local_locale(locale_name)}' > /etc/profile")
    end
  }
  after {
    log "Setting the locale doesn't take effect until you log out and back in."
  }
end

dep 'exists.locale', :locale_name do
  deprecated! "2013-12-12", :method_name => "'benhoskings:exists.locale'", :callpoint => false, :instead => "'common:exists.locale'"
  met? {
    local_locale(locale_name)
  }
  meet {
    shell "locale-gen #{locale_name}.UTF-8", :log => true
  }
end
