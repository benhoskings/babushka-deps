dep 'npm mirrored' do
  define_var :npm_mirror_root, :default => '/srv/http/registry.npmjs.org'
  registry = "http://registry.npmjs.org/"
  met? {
    require 'json'
    JSON.parse(`curl #{registry} 2>/dev/null`).each_pair {|pkg,details|
      details['versions'].each_pair {|version,url|
        src = JSON.parse(`curl #{url} 2>/dev/null`)['dist']['tarball']
        # destdir = File.dirname(src.sub(/^[a-z]+:\/\/[^\/]+\//, ''))
        Babushka::Resource.download src
      }
    }
  }
end
