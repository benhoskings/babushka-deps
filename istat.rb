dep 'istat.src' do
  requires 'libxml.managed'
  source 'http://istatd.googlecode.com/files/istatd-0.5.4.tar.gz'
  provides 'istatd'
end

