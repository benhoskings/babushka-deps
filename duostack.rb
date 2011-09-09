dep 'duostack' do
  requires 'ruby', 'git', 'curl', 'expect'
  met? { in_path? 'duostack' }
  meet {
    Babushka::Resource.extract 'http://www.duostack.com/duostack-client.latest.tgz' do
      shell 'cp duostack /usr/local/bin', :sudo => !'/usr/local/bin'.p.writable?
    end
  }
end
