dep 'ree.src' do
  source "http://rubyforge.org/frs/download.php/71098/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb"
  process_source {
    sudo("dpkg -i ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb")
  }
  met? { shell("ruby --version") =~ /#{Regexp.escape("ruby 1.8.7 (2010-04-19 patchlevel 253) [x86_64-linux], MBARI 0x6770, Ruby Enterprise Edition 2010.02")}/ }
end

dep 'ree' do
  met? { shell("ruby --version") =~ /#{Regexp.escape("ruby 1.8.7 (2010-04-19 patchlevel 253) [x86_64-linux], MBARI 0x6770, Ruby Enterprise Edition 2010.02")}/ }
  meet {
    get "http://rubyforge.org/frs/download.php/71098/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb" do |deb|
      sudo "dpkg -i '#{deb}'"
    end
  }
end
