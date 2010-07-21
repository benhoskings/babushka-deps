dep 'ngircd.managed' do
  installs { via :apt, 'ngircd' }
  cfg '/etc/ngircd/ngircd.conf'
end
