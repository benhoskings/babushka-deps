dep 'mirror has assets' do
  define_var :mirror_prefix, :default => '/srv/http' #L{ "http://#{var(:mirror_path).p.basename}" }
  define_var :local_path, :default => :mirror_domain
  helper :scanned_urls do
    (var(:mirror_prefix) / var(:local_path)).glob("**/*").select {|f|
      f[/\.(html?|css)$/i]
    }.map {|f|
      f.p.read.scan(/url\(['"]?([^)'"]+)['"]?\)/).flatten
    }.flatten.uniq
  end
  helper :asset_map do
    scanned_urls.group_by {|url|
      url[/^(http\:)?\/\//] ? url.scan(/^[http\:]*\/\/([^\/]+)/).flatten.first : var(:mirror_domain)
    }.map_values {|domain,urls|
      urls.map {|url| url.sub(/^(http\:)?\/\/[^\/]+\//, '') }
    }
  end
  helper :nonexistent_asset_map do
    asset_map.map_values {|domain,assets|
      assets.reject {|asset|
        path = var(:mirror_prefix) / domain / asset
        path.exists? && !path.empty?
      }
    }
  end
  met? { nonexistent_asset_map.values.all? &:empty? }
  meet {
    nonexistent_asset_map.each_pair {|domain,assets|
      assets.each {|asset|
        shell "mkdir -p '#{var(:mirror_prefix) / domain / File.dirname(asset)}'"
        log_shell "Downloading http://#{domain}/#{asset}", "wget -O '#{var(:mirror_prefix) / domain / asset}' '#{File.join "http://#{domain}", asset}'"
      }
    }
  }
end

dep 'twitter avatars mirrored' do
  define_var :twitter_pass, :default => L{ 'secret' }
  helper :users do
    "~/Desktop/rc7/campers.txt".p.read.split(/\n+/).uniq.map {|name| name.sub(/^@/, '') }
  end
  helper :missing_avatars do
    users.reject {|user|
      path = "~/Desktop/rc7/avatars/#{user}".p
      path.exists? && !path.empty?
    }
  end
  met? { missing_avatars.empty? }
  meet {
    require 'rubygems'
    require 'twitter'
    client = Twitter::Base.new(Twitter::HTTPAuth.new(var(:twitter_username), var(:twitter_pass)))
    in_dir "~/Desktop/rc7/avatars", :create => true do
      missing_avatars.each {|name|
        url = client.user(name)['profile_image_url'].sub(/_normal(\.[a-zA-Z]+)$/) { $1 }
        Babushka::Archive.download url, name
      }
    end
  }
end

dep 'gravatars mirrored' do
  helper :users do
    "~/Desktop/rc7/emails.txt".p.read.split(/\n+/).uniq
  end
  helper :missing_avatars do
    users.reject {|user| "~/Desktop/rc7/gravatars/#{user}.jpg".p.exists? }
  end
  met? { missing_avatars.empty? }
  meet {
    require 'digest/md5'
    in_dir "~/Desktop/rc7/gravatars", :create => true do
      missing_avatars.each {|email|
        Babushka::Archive.download "http://gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?s=512&d=404", "#{email}.jpg"
      }
    end
  }
end

dep 'google ajax libs mirrored' do
  define_var :mirror_root, :default => '/srv/http/ajax.googleapis.com'
  helper :search_libstate do |doc,key|
    doc.search("dd.al-libstate[text()*='#{key}:']").text.gsub("#{key}:", '').strip
  end
  helper :urls do
    require 'rubygems'
    require 'hpricot'
    require 'net/http'
    Hpricot(Net::HTTP.get(URI.parse('http://code.google.com/apis/ajaxlibs/documentation/'))).search('.al-liblist').map {|lib|
      lib_name = search_libstate(lib, 'name')
      versions = search_libstate(lib, 'versions').split(/[, ]+/)
      [search_libstate(lib, 'path'), search_libstate(lib, 'path(u)')].squash.map {|path_template|
        versions.map {|version|
          URI.parse path_template.gsub versions.last, version
        }
      }
    }.flatten
  end
  helper :missing_urls do
    urls.reject {|url| (var(:mirror_root) / url.path).exists? }
  end
  met? { missing_urls.empty? }
  meet {
    missing_urls.each {|url|
      in_dir var(:mirror_root) / url.path.p.dirname, :create => true do
        Babushka::Archive.download url
      end
    }
  }
end
