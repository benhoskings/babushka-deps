dep 'blank'

dep 'long' do
  met? { sleep 100 }
end

dep "top" do
  requires "left", "right"
end

dep "left" do
  requires 'benhoskings:nodejs.src'
end

dep "right" do
  requires 'benhoskings:nodejs.src'
end

dep 'uptime' do
end

dep 'test user setup' do
  requires 'test dot files', 'test passwordless ssh logins'.with(:username => shell('whoami')), 'public key', 'zsh'
end

dep 'test dot files' do
  requires 'user exists', 'git', 'curl.managed', 'git-smart.gem'
  met? { File.exists?(ENV['HOME'] / ".dot-files/.git") }
  meet { shell %Q{curl -L "http://github.com/#{var :github_user, :default => 'benhoskings'}/#{var :dot_files_repo, :default => 'dot-files'}/raw/master/clone_and_link.sh" | bash} }
end

dep 'test passwordless ssh logins' do
  def ssh_dir
    "~#{var(:username)}" / '.ssh'
  end
  def group
    shell "id -gn #{var(:username)}"
  end
  met? {
    sudo "grep '#{var(:your_ssh_public_key)}' '#{ssh_dir / 'authorized_keys'}'"
  }
end


dep 'cmddirs.src', :template => 'benhoskings:nonexistent' do
  provides 'ruby == 1.9.2p136', 'zsh'
end

dep 'hello.task' do
  run {
    log "hello!"
  }
end

dep 'unmet' do
  met? { false }
end

dep 'a task' do
  met? {
    if @run
      # met "Blah is up to date."
      true
    else
      unmet "Blah is outdated."
    end
  }
  meet {
    log 'Downloading... done.'
    log 'Installing... done.'
    @run = true
  }
end

meta 'wat' do
  def srsly
    log ":?"
  end
end

dep 'wait.wat' do |basename, lol|
  met? {
    srsly # if confirm('rly?')
  }
  meet {
    log local_variables.inspect
    log basename.inspect
    log lol.inspect
  }
end

# puts Dep('wait.wat').block.arity

dep 'def a' do
  def test_a
    log_ok "yes!"
  end
  met? { test_a }
end

dep 'def b' do
  met? { test_a }
end

dep 'faily' do
  met? { in_path? ['ruby', 'bash'] }
end

dep 'raisey' do
  met? { false }
  meet { log 'raising'; raise UnmeetableDep }
end

dep 'wtf' do
  met? { raise }
end


dep 'lol.gem' do
  installs 'lol 0.3.beta'
end

dep 'omg!' do
  met? { babushka_config? "omg" }
  meet { render_erb "omg.erb", :to => "omg" }
end

dep 'MockSmtp.app' do
  source 'http://mocksmtpapp.com/download'
  met? { lol }
end

meta :simbl, :for => :osx do
  accepts_list_for :source
  accepts_list_for :extra_source

  def path
    "/Library/Application Support/SIMBL/Plugins" / name
  end
  
  template {
    # requires 'SIMBL'
    prepare { setup_source_uris }
    
    met? {
      path.exists? or ("~" / path).exists?
    }
  
    before { shell "mkdir -p \"#{path.parent}\"" }
    meet {
      process_sources {|archive|
        Dir.glob("*.bundle").map {|entry|
          log_shell "Installing #{entry}", %Q{ls -l}
        }
      }
    }
  }
end

dep 'Blurminal.simbl' do
  source 'http://github.com/timmfin/Blurminal/raw/master/Blurminal-SL-64bit.bundle.zip'
end

meta 'flargle' do
  accepts_value_for :package
end

dep 'blargle.flargle' do
  package 'lol'
  met? { log "#{package.inspect}!" }
end

dep 'test' do
  requires 'test2'
  met? {
    VersionOf(basename).tapp
    log @met.inspect
    sleep 1
    var(:test).empty?
  }
end

dep 'test2' do
  met? {
    log @met.inspect
    @met
  }
  meet {
    sleep 1
    @met = true
  }
end

# dep 'omg.conf' do
#   render "omg.conf.erb" => "omg.conf"
# end
# 
# meta :a do
#   accepts_list_for :a
# end
# 
# meta :b do
#   def b
#     log "b!"
#   end
# end
# 
# dep 'hai.a.b' do
#   a "test"
#   met? { b }
# end

dep 'one' do
  requires 'two', 'three'
  setup {
    Dep('two').tapp.context.payload[:requires].delete('should_go')
    dep('two').tapp
    Dep('three').context.requires('failtown')
  }
end

dep 'two' do
  requires 'should_stay', 'should_go'
end

dep 'should_stay'
dep 'should_go'

dep 'three' do
  requires 'four'
end

dep 'four'

dep 'failtown' do
  met? { false }
end

dep 'rakey rake.task' do
  run {
    rake "-T"
  }
end
