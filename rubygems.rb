dep 'rubygems' do
  requires 'rubygems installed', 'github source', 'gemcutter source'
  setup {
    shell('ruby --version')['ruby 1.9'].nil? || definer.requires('fake json gem')
  }
end

dep 'fake json gem' do
  met? { Babushka::GemHelper.has? 'json' }
  meet {
    log "json is now included in ruby core, and when gems try to install the"
    log "gem, it fails to build. So, let's install a fake version of json-1.1.9."
    in_build_dir {
      log_block "Generating fake json-1.1.9 gem" do
        File.open 'fake_json.gemspec', 'w' do |f|
          f << %Q{
            spec = Gem::Specification.new do |s|
              s.name = "json"
              s.version = "1.1.9"
              s.summary = "this fakes json (which is now included in stdlib)"
              s.homepage = "http://gist.github.com/gists/58071"
              s.has_rdoc = false
              s.required_ruby_version = '>= 1.9.1'
            end
          }
        end
        shell "gem build fake_json.gemspec"
      end
      Babushka::GemHelper.install! 'json-1.1.9.gem', '--no-ri --no-rdoc'
    }
  }
end

dep 'gemcutter source' do
  requires 'rubygems installed'
  met? { shell("gem sources")["http://gemcutter.org"] }
  meet { shell "gem sources -a http://gemcutter.org", :sudo => !File.writable?(which('ruby')) }
end

dep 'github source' do
  requires 'rubygems installed'
  met? { shell("gem sources")["http://gems.github.com"] }
  meet { shell "gem sources -a http://gems.github.com", :sudo => !File.writable?(which('ruby')) }
end

dep 'rubygems installed' do
  requires 'ruby', 'curl'
  merge :versions, :rubygems => '1.3.5'
  met? { cmds_in_path? 'gem', cmd_dir('ruby') }
  meet {
    in_build_dir {
      get_source("http://rubyforge.org/frs/download.php/60718/rubygems-#{var(:versions)[:rubygems]}.tgz") and

      in_dir "rubygems-#{var(:versions)[:rubygems]}" do
        shell "ruby setup.rb", :sudo => !File.writable?(which('ruby'))
      end
    }
  }
  after {
    in_dir cmd_dir('ruby') do
      if File.exists? 'gem1.8'
        shell "ln -sf gem1.8 gem", :sudo => !File.writable?(which('ruby'))
      end
    end
  }
end
