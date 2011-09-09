dep 'mirror has assets' do
  define_var :mirror_prefix, :default => '/srv/http' #L{ "http://#{var(:mirror_path).p.basename}" }
  define_var :local_path, :default => :mirror_domain
  def scanned_urls
    (var(:mirror_prefix) / var(:local_path)).glob("**/*").select {|f|
      f[/\.(html?|css)$/i]
    }.map {|f|
      f.p.read.scan(/url\(['"]?([^)'"]+)['"]?\)/).flatten
    }.flatten.uniq
  end
  def asset_map
    scanned_urls.group_by {|url|
      url[/^(http\:)?\/\//] ? url.scan(/^[htp\:]*\/\/([^\/]+)/).flatten.first : var(:mirror_domain)
    }.map_values {|domain,urls|
      urls.map {|url| url.sub(/^(http\:)?\/\/[^\/]+\//, '') }
    }
  end
  def nonexistent_asset_map
    asset_map.map_values {|domain,assets|
      assets.reject {|asset|
        path = var(:mirror_prefix) / domain / asset
        path.exists? && !path.empty?
      }
    }
  end
  met? { nonexistent_asset_map.values.all?(&:empty?) }
  meet {
    nonexistent_asset_map.each_pair {|domain,assets|
      assets.each {|asset|
        shell "mkdir -p '#{var(:mirror_prefix) / domain / File.dirname(asset)}'"
        log_shell "Downloading http://#{domain}/#{asset}", "wget -O '#{var(:mirror_prefix) / domain / asset}' '#{File.join "http://#{domain}", asset}'"
      }
    }
  }
end

meta :twitter do
  def users
    "~/Desktop/rc7/campers.txt".p.read.split(/\n+/).uniq.map {|name| name.sub(/^@/, '') }
  end
  def avatars
    users.map {|user|
      path = "~/Desktop/rc7/avatars/".p.glob("#{user}.*").first
      path.p unless path.nil?
    }.compact
  end
  def missing_avatars
    avatars.reject {|avatar|
      avatar.exists? && !avatar.empty?
    }
  end
end

dep 'avatars mirrored.twitter' do
  define_var :twitter_pass, :default => L{ 'secret' }
  met? { missing_avatars.empty? }
  meet {
    require 'rubygems'
    require 'twitter'
    client = Twitter::Base.new(Twitter::HTTPAuth.new(var(:twitter_username), var(:twitter_pass)))
    cd "~/Desktop/rc7/avatars", :create => true do
      missing_avatars.each {|name|
        begin
          url = client.user(name)['profile_image_url'].sub(/_normal(\.[a-zA-Z]+)$/) { $1 }
          Babushka::Archive.download url, name
        rescue Twitter::NotFound
          log_error "#{name}: 404."
        rescue Twitter::InformTwitter
          log_error "#{name}: Fail whale!"
        rescue JSON::ParserError
          log_error "#{name}: Bad JSON."
        end
      }
    end
  }
end

dep 'avatars renamed.twitter' do
  # requires 'twitter avatars mirrored'
  met? { (avatars - missing_avatars).all? {|avatar| avatar.to_s[/\.[jpengif]{3,4}$/] } }
  meet {
    (avatars - missing_avatars).each {|avatar|
      type = shell("file '#{avatar}'").scan(/([A-Z]+) image/).flatten.first
      unless type.nil?
        ext = type.downcase
        shell "mv '#{avatar}' '#{avatar}.#{ext}'"
      end
    }
  }
  after {
    log "These ones are broken:"
    log avatars.reject {|avatar| avatar.to_s[/\.[jpengif]{3,4}$/] }.join("\n")
  }
end

dep 'gravatars mirrored' do
  def users
    "~/Desktop/rc7/emails.txt".p.read.split(/\n+/).uniq
  end
  def missing_avatars
    users.reject {|user| "~/Desktop/rc7/gravatars/#{user}.jpg".p.exists? }
  end
  met? { missing_avatars.empty? }
  meet {
    require 'digest/md5'
    cd "~/Desktop/rc7/gravatars", :create => true do
      missing_avatars.each {|email|
        Babushka::Archive.download "http://gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?s=512&d=404", "#{email}.jpg"
      }
    end
  }
end

dep 'google ajax libs mirrored' do
  define_var :mirror_root, :default => '/srv/http/ajax.googleapis.com'
  def search_libstate doc, key
    doc.search("dd.al-libstate[text()*='#{key}:']").text.gsub("#{key}:", '').strip
  end
  def urls
    require 'rubygems'
    require 'hpricot'
    require 'net/http'
    Hpricot(Net::HTTP.get(URI.parse('http://code.google.com/apis/ajaxlibs/documentation/'))).search('.al-liblist').map {|lib|
      # lib_name = search_libstate(lib, 'name')
      versions = search_libstate(lib, 'versions').split(/[, ]+/)
      [search_libstate(lib, 'path'), search_libstate(lib, 'path(u)')].squash.map {|path_template|
        versions.map {|version|
          URI.parse path_template.gsub(versions.last, version)
        }
      }
    }.flatten
  end
  def missing_urls
    urls.tap {|urls|
      log "#{urls.length} items to consider."
    }.reject {|url| (var(:mirror_root) / url.path).exists? }.tap {|present|
      log "Of those, we have #{present.length}."
    }
  end
  met? { missing_urls.empty? }
  meet {
    missing_urls.each {|url|
      cd var(:mirror_root) / url.path.p.dirname, :create => true do
        Babushka::Archive.download url
      end
    }
  }
end
