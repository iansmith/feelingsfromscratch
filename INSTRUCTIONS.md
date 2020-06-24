# Feelings From Scratch

##### iansmith, june 2020

We apologize to the authors of the wonderful 
book [Linux From Scratch](http://www.linuxfromscratch.org/lfs/view/stable/).
This is not a book, not as well written as their book, nor is this documentation
really "from scratch" since it uses package managers.

## Preface

In this document, we assume you have set the environment variable `FFS`
to the directory where this document is located.  This should be a 
fully-qualified, not relative, path.

Anytime you are running a script or Makefile in any part of feelings
or feelings from scratch, you should be *in the directory* where the
script or Makefile is located when you try to use it.

## Package managers: friend and foe
Package managers are dangerous because they do many things that you don't know
about.  Package managers are valuable and good because they do many things 
that you don't know about.  This set of instructions will try to split the
difference by using package managers for packages that we *think* are old
enough and stable enough that roughly any version will do.  On the contrary,
we will build from source the things that we are sure must be at a specific
version.

We will also _override_ some typical environment variables with versions that
choose our newly built packages.  For example, we will maintain our own
`pkg-config` for all the packages where we have concerns about the version
numbers.  Then we will set `PKG_CONFIG_PATH` to 
```shell script
export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig
```
on MacOS and somethig like
```shell script
export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
```

This document only uses ubuntu/debian's `apt-get` package manager 
[until we fix it](https://app.clubhouse.io/feelings/story/98/support-linux-package-manager-diversity). 


### Setup: Linux
The following is the command to set up the packages for a fresh linux system, or if you are
[building a container](https://app.clubhouse.io/feelings/story/100/distribution-scripts).

```shell script
apt-get -y  install libglib2.0-dev meson gettext automake autogen libtool openssl libnettle7 libp11-kit0 libtasn1-6 cmake libhogweed5 libgnutls30 build-essential texinfo
```

Most linux users probably have many of these packages installed already and, if our 
crucial assumption above is correct, that is fine.

### symlink overrides

We will use symlinks to make the linux system "look like" the MacOS system, assuming
the PATH is setup correctly.

```
cd $FFS
mkdir -p bin
cd bin
ln -s /usr/bin/sed ./gsed
ln -s /usr/bin/libtool ./glibtool
ln -s /usr/bin/libtoolize ./glibtool
```

### Setup: MacOS

We will assume that MacOS users are using [brew](https://brew.sh/) for package management.
If you want to send in a PR for another package manager (fink?) that would be great!

Here is the package installation line for MacOS, assuming you are on Catalina (OS 10.15).
If you want to send in a PR for another MacOS version, that would be great!

#### brew command

```
brew install glib meson gettext automake libtool openssl cmake nettle gnutls gnu-sed
```

As with linux, you may have many of these packages installed already and we are praying
hard that this will be ok.

To insure that we have access to the versions of packages we want, rather than what
might be installed elsewhere, on MacOS we also symlink some binaries.
 
### symlink overrides
```
cd $FFS
mkdir -p bin
ln -s /usr/local/Cellar/python@3.8/3.8.3/bin/python3 ./python3
ln -s /usr/local/Cellar/python@3.8/3.8.3/bin/python3 ./pip3
```

## Environment variables
This is a good time to set the environment variables for the rest of this
process.

### linux environment variables
```shell script
export PATH=$FFS/tools/bin:$PATH
export LIB_LIBRARY_PATH=$FFS/tools/lib:/usr/lib/x86_64-linux-gnu
export PKG_CONFIG_PATH=/cross/tools/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig

```

### MacOS environment variables
```shell script
export PATH=$FFS/tools/bin:$PATH
export DYLD_LIBRARY_PATH=$FFS/tools/lib:/usr/local/lib:/usr/lib
export PKG_CONFIG_PATH=$FFS/tools/lib/pkgconfig:/usr/local/lib/pkgconfig
```

## Building remaining libraries and tools  from source

The primary tools that you need when using or developing for feelings are:

* a modern gcc cross compiler for aarch64-elf
* a modern gdb cross debugger for aarch64-elf
* a modern, cross version of gnu binutils for aarch64-elf 
* go 1.14+ for the host system
* tinygo 0.13+ (and on the dev branch)
* qemu 5.0.0

The gdb is for debugging kernel binaries running inside qemu.  The go compiler
is for host tools used at compile time.  Tinygo is for compiling things that 
run on the raspi3 hardware.  The binutils are for some tools that are used in
scripts or debugging related to the kernel like `objdump` and `readelf`. The
gcc is for testing C code that is "known to work" on bare metal raspi3.

The script that builds all the necessary libraries at the right
version numbers and all the tools above is called `primary-tools.bash`
and it uses `utils.bash` to do a lot of its work.  It takes a parameter
"-j=n" where n is the number of simulateous jobs.  There is a debugging
parameter "-x" which causes the script to print out each shell command
it uses.  We are working to try to make "-s" cause the output to be silent
unless there is an error, but this is 
[still a work in progress](https://app.clubhouse.io/feelings/story/107/make-silent-work-better).

Launch the build with:
```shell script
./primary-tools.bash -j=8
``` 

If you are lucky, everything will "just work."  If you are unlucky, you may have
mess with the script or various tools/libraries to get it to build everything.
If you manage to get something to work that was clearly broken, please file a
PR against this repository!

Note: We currently (as of gcc 10.1) have to patch the gcc source due to a badly
constructed macro in the backend support for aarch64, which is the processor
in a raspi3.  We simply disable the support for tagged memory (which is cool,
but feelings doesn't use it) and everything is ok.

 