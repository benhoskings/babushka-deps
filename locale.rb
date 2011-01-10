meta :locale do
  def locale_regex
    # TODO: would be nice to not hardcode to en_US.
    /en_AU\.utf-?8/i
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
    login_shell('locale').val_for('LANG')[locale_regex]
  }
  on :apt do
    meet {
      sudo("echo 'LANG=#{local_locale}' > /etc/default/locale")
    }
  end
end

dep 'exists.locale' do
  met? { local_locale }
end
