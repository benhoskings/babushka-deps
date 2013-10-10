{
  'readline headers.managed' => 'readline.lib',
  'libssl headers.managed' => 'openssl.lib',
  'yaml headers.managed' => 'yaml.lib',
  'zlib headers.managed' => 'zlib.lib',
}.each_pair {|old_name, new_name|

  dep old_name do
    deprecated! '2014-04-10', :method_name => "'#{name}'", :callpoint => false, :instead => "the '#{new_name}' dep"
    requires new_name
    # This is just a wrapper dep; override the template. (Shouldn't be
    # necessary but :template is checked for truthiness, not presence.)
    met? { true }
  end

}
