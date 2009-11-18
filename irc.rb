pkg 'ngircd' do
  installs { via :apt, 'ngircd' }
  cfg '/etc/ngircd/ngircd.conf'
end
