#!/bin/bash

#
# these are the packages that seem safe to just let the pkg manager do it
#
#libglib2.0-dev -> libffi-dev (>= 3.3), libglib2.0-0 (= 2.64.2-1~fakesync1),
#    libglib2.0-bin (= 2.64.2-1~fakesync1), libglib2.0-dev-bin (= 2.64.2-1~fakesync1),
#    libmount-dev (>= 2.28), libpcre3-dev (>= 1:8.31), libselinux1-dev,
#    pkg-config, zlib1g-dev
#meson -> python3:any (>= 3.7~), ninja-build (>= 1.6)
#gettext -> libc6 (>= 2.17), libcroco3 (>= 0.6.2), libgomp1 (>= 6),
#    libtinfo6 (>= 6), libunistring2 (>= 0.9.7), libxml2 (>= 2.9.1),
#    gettext-base, dpkg (>= 1.15.4) | install-info
#automake -> autoconf (>= 2.65), autotools-dev (>= 20020320.1)
#autogen -> guile-2.2-libs, libc6 (>= 2.17), libopts25 (>= 1:5.18.16),
#    libxml2 (>= 2.7.4), libopts25-dev (= 1:5.18.16-3), perl:any
#libtool -> gcc | c-compiler, cpp, libc6-dev | libc-dev, file, autotools-dev
#openssl -> libc6 (>= 2.15), libssl1.1 (>= 1.1.1)
#libnettle7  -> libc6 (>= 2.14)
#libp11-kit0 ->  libc6 (>= 2.26), libffi7 (>= 3.3~20180313)
#libtasn1-6 -> libc6 (>= 2.14)
#cmake ->  cmake-data (= 3.16.3-1ubuntu1), procps, libarchive13 (>= 3.3.3),
#    libc6 (>= 2.17), libcurl4 (>= 7.16.2), libexpat1 (>= 2.0.1),
#    libgcc-s1 (>= 3.0), libjsoncpp1 (>= 1.7.4), librhash0 (>= 1.2.6),
#    libstdc++6 (>= 9), libuv1 (>= 1.11.0), zlib1g (>= 1:1.1.4)

#
#OSX needs gsed
#

#
# these two have a dep on libgmp10, as do the installed compilers from build-essential
#
#libhogweed5 libc6 (>= 2.14), ****libgmp10 ****  (>= 2:6.0.0),
#   libnettle7 (= 3.5.1+really3.5.1-2)
#libgnutls (***libgmp10***) libc6 (>= 2.25), libhogweed5, libidn2-0 (>= 2.0.0),
#    libnettle7, libp11-kit0 (>= 0.23.18.1), libtasn1-6 (>= 4.14),
#    libunistring2 (>= 0.9.7)

#apt-get -y  install libglib2.0-dev meson gettext automake autogen libtool openssl libnettle7 libp11-kit0 libtasn1-6 cmake libhogweed5 libgnutls30 \abuild-essential texinfo

root@242f516eef63:/tools# echo $LD_LIBRARY_PATH
/tools/tools/lib:/usr/lib/x86_64-linux-gnu
root@242f516eef63:/tools# echo $PKG_CONFIG_PATH
/tools/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
root@242f516eef63:/tools# echo $PATH
/tools/tools/bin:/tools/tools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

BREW

glib -> gettext libffi pcre python3
meson -> ninja python3
gettext ->
automake -> autoconf
autogen -> guile2
glibtool ->
openssl ->
cmake ->

gnutls -> ***gmp*** libidn2 libtasn1 libunistring nettle p11-kit unbound
nettle -> **gmp***

brew install glib meson gettext automake glibtool openssl cmake nettle gnutls