meta :locale do
  template {
    helper :locale_regex do
      /[\w]+\.utf8/
    end
    helper :local_locale do
      shell('locale -a').split("\n").detect {|l|
        l[locale_regex]
      }
    end
  }
end

dep 'set.locale' do
  requires 'locale exists'
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
