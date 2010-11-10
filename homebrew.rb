meta :homebrew_mirror do
  template {
    helper :urls do
      script = %Q{
#!/usr/bin/env ruby

prefix = `brew --prefix`.chomp
$LOAD_PATH << File.join(prefix, 'Library', 'Homebrew')

require 'extend/ARGV'
require 'global'
ARGV.extend HomebrewArgvExtension
require 'formula'

before = Class.constants

Dir[File.join(prefix, 'Library/Formula/*')].each {|f| load f }
classes_to_skip = %w[AspellLang COREUTILS_ALIASES DICT_CONF Rational SOLR_START_SCRIPT]

urls = (Class.constants - before - classes_to_skip).reject {|k|
  k =~ /DownloadStrategy$/
}.map {|k|
  eval(k.to_s)
}.select {|k|
  k.respond_to? :url
}.map {|k|
  k.url
}
puts urls * "\n"
      }
      shell("ruby", :input => script).split("\n").select {|url| url[/^(https?|ftp):/] }.uniq
    end
  }
end

dep 'mirrored.homebrew_mirror' do
  define_var :homebrew_downloads, :default => '/srv/http/files'
  define_var :homebrew_vhost_root, :default => '/srv/http/homebrew'
  helper :missing_urls do
    urls.tap {|urls| log "#{urls.length} URLs in the homebrew database." }.reject {|url|
      path = var(:homebrew_downloads) / File.basename(url)
      path.exists? && !path.empty?
    }.tap {|urls| log "Of those, #{urls.length} aren't present locally." }
  end
  met? { missing_urls.empty? }
  meet {
    in_dir var(:homebrew_downloads) do
      missing_urls.each {|url| Babushka::Resource.download url }
    end
  }
end

dep 'linked.homebrew_mirror' do
  requires 'mirrored.homebrew_mirror'
  helper :unlinked_urls do
    urls.tap {|urls| log "#{urls.length} URLs in the homebrew download pool." }.select {|url|
      path = var(:homebrew_downloads) / File.basename(url)
      link = var(:homebrew_vhost_root) / url.sub(/^[a-z]+:\/\/[^\/]+\//, '')
      path.exists? && !(link.exists? && link.readlink)
    }.tap {|urls| log "Of those, #{urls.length} aren't symlinked into the vhost." }
  end
  met? { unlinked_urls.empty? }
  meet {
    unlinked_urls.each {|url|
      shell "mkdir -p '#{var(:homebrew_vhost_root) / File.dirname(url.sub(/^[a-z]+:\/\/[^\/]+\//, ''))}'"
      log_shell "Linking #{url}", "ln -sf '#{var(:homebrew_downloads) / File.basename(url)}' '#{var(:homebrew_vhost_root) / url.sub(/^[a-z]+:\/\/[^\/]+\//, '')}'"
    }
  }
  after {
    log urls.map {|url|
      url.scan(/^[a-z]+:\/\/([^\/]+)\//).flatten.first
    }.uniq.reject {|url|
      url[/[:]/]
    }.join(' ')
    log "Those are the domains you should alias the host to."
  }
end
