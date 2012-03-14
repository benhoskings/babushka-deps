dep 'www user and group' do
  www_name = Babushka.host.osx? ? '_www' : 'www'
  met? {
    '/etc/passwd'.p.grep(/^#{www_name}\:/) and
    '/etc/group'.p.grep(/^#{www_name}\:/)
  }
  meet {
    sudo "groupadd #{www_name}"
    sudo "useradd -g #{www_name} #{www_name} -s /bin/false"
  }
end
