sudo apt-get install lua5.3 liblua5.3-dev -y

cd download 

rm -f luarocks-2.2.1.tar.gz*
wget http://luarocks.org/releases/luarocks-2.2.1.tar.gz
tar zxpf luarocks-2.2.1.tar.gz
cd luarocks-2.2.1 
./configure --lua-version=5.3 --versioned-rocks-dir; make build
sudo make install

sudo luarocks install luafilesystem