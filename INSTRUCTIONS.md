### Setup: Linux

### symlink overrides
```
cd $FFS
mkdir -p bin
ln -s /usr/bin/sed ./gsed
ln -s /usr/bin/libtool ./glibtool
ln -s /usr/bin/libtoolize ./glibtool
```


### Setup: MacOS

#### brew command
```
brew install glib meson gettext automake libtool openssl cmake nettle gnutls gnu-sed
```

### symlink overrides
```
cd $FFS
mkdir -p bin
ln -s /usr/local/Cellar/python@3.8/3.8.3/bin/python3 ./python3
ln -s /usr/local/Cellar/python@3.8/3.8.3/bin/python3 ./pip3

```

build gmp
build ffi
build nettle
build readline
build openssl?

### path vars
```shell script
$ export PATH=$FFS/tools/bin:$PATH
$ export DYLD_LIBRARY_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib
$ export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig
```