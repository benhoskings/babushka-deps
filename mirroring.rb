dep 'mirror has assets' do
  define_var :mirror_prefix, :default => '/srv/http' #L{ "http://#{var(:mirror_path).p.basename}" }
  helper :scanned_urls do
    (var(:mirror_prefix) / var(:mirror_domain)).glob("**/*").select {|f|
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
