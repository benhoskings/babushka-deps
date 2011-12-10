dep 'lua.managed'

dep 'luarocks.src' do
  requires 'lua.managed'
  source 'http://luarocks.org/releases/luarocks-2.0.1.tar.gz'
end

dep 'Lua.tmbundle' do
  requires 'lua.managed'
  source 'https://github.com/textmate/lua.tmbundle.git'
end

# TODO set TextMate var: TM_LUA -> /opt/local/bin/lua
