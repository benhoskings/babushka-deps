dep 'ngircd', :template => 'managed' do
  installs { via :apt, 'ngircd' }
  cfg '/etc/ngircd/ngircd.conf'
end
