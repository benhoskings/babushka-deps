dep 'ree' do
  def source
    "http://rubyforge.org/frs/download.php/71098/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb"
  end
  met? { shell("ruby --version")["ruby 1.8.7 (2010-04-19 patchlevel 253) [x86_64-linux], MBARI 0x6770, Ruby Enterprise Edition 2010.02"] }
  meet {
    Babushka::Resource.get(source) {|path|
      sudo("dpkg -i #{path}")
    }
  }
end
