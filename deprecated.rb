{
  'readline headers.managed' => 'readline.lib',
  'libssl headers.managed' => 'openssl.lib',
  'yaml headers.managed' => 'yaml.lib',
  'zlib headers.managed' => 'zlib.lib',
  'pcre.managed' => 'pcre.lib',
  'unzip.managed' => 'unzip.bin'
}.each_pair {|old_name, new_name|

  dep old_name do
    deprecated! '2014-04-10', :method_name => "'#{name}'", :callpoint => false, :instead => "the '#{new_name}' dep"
    requires new_name
    # This is just a wrapper dep; bypass the template's logic.
    met? { true }
  end

}
