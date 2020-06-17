# Feelings From Scratch

Feelings From Scratch is a set of scripts, configuration files, and other various 
bits and bobs that will get you a complete and working set of tools for doing 
feelings development.

## Stage 0: Prerequisites (15 minutes)

If you got this file and the scripts via github, you have already cloned the code and you should
rename it now.  We will assume you are going to rename `feelingsfromscratch` to `ffs`.  If you
got this file via a tarball, you'll want to make sure that you go back to where you unpacked the
tarball and rename the directory that contains this file to `ffs` if it's not already.

We are going to start by setting up the baseline tools you'll need and some environment variables.
In particular, you will need to adjust your PATH.  It is likely you will to remove (or hide) some
amount of software on your system if you use a package manager.

## Stage 0: Prerequisites:  MacOS instructions 

All of this document has been tested on OSX 10.15.5 (Catalina).  It is likely that most things will
work on earlier versions, with the exception of the code signing which changed in later versions
of OSX.

Install:

* xcode command line tools, version 11.5 (https://developer.apple.com/download/more/)

Verify:

* `/usr/bin/clang` and `/usr/bin/clang++` exist and can run with `/usr/bin/clang -v` or similar.
We will be using these compilers to build our darwin tooling.
* `/usr/bin/git` exists and can run with `/usr/bin/git --version`.  The particular version is 
not important because we are not doing anything tricky with git.
* `/usr/bin/curl` exists and can run with `/usr/bin/curl --version` Again, we are not doing 
anything sophisticated with curl, just using it to download source code from the internet.
* `/usr/bin/make` exists and can run with `/usr/bin/make -v` We use make in many
different ways, but we don't use special extensions to it, so any modern version of
make is likely to work.

### WARNING WARNING WARNING: brew is not your friend

For the duration of Feelings From Scratch, you are going to want to make sure that you do *not*
have `/usr/local/bin` in your path.  Whether you use `brew` or `fink` or any other automated
package manager, they are almost certainly going to cause you headache and pain.  Nearly every
reported problem with this set of instructions is related to a package manager. 

You definitely *do not* want to try to install the tools we will be building in this tutorial using
brew (or similar)  because there are too many ways for that fail.  You'll need to get rid of 
the command itself and hide the things it has installed by taking the brew-managed tools  
out of your path.  If you can get anything else it manages out of your way, that's a bonus. For
example, you probably will want to rename `/usr/local/opt` to `/usr/local/xxopt` for the duration
of these instructions.

The path I recommend starting with is:
```shell script
$ echo $PATH
/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/go/bin
```

The last entry in that PATH list is the path to a go compiler.

At various points in these instructions, we will advise you on how to update your PATH as tools
we need to use are built.

### Go bootstrap

If you do not already have a version of go on your system (and in your path) you can download one here:
https://golang.org/dl/

It's ok if that installs in some standard location (usually `/usr/local/go`) because we are only going
to use that go compiler as the bootstrap compiler.  Once you are done with the prerequisits, you 
can delete it.  If you are using your own existing go compiler to bootstrap, that's fine, just be
sure it's at least version 1.4 or higher.

The first time we will use an automated script will be now.  We are going to download and build our
ffs go compiler. This tool, called `hostgo` compiles host-side tools that are part of feelings. Open a 
shell _in the directory that contains this file_ and try:

```shell script
$ ./go-bootstrap.sh
```

You should see that the go-boostrap script  use curl to download the go sources and then use your 
bootstrap compiler to compile and test these sources.  This takes about
5 to 10 minutes.

From now on these instructions two rules need to be followed related to running scripts:
* *Always* run them from this directory (the one with the INSTRUCTIONS file)
* If at the end of the script there is some output with additional instructions, be sure
to do that immediately.

In the case of `go-bootstrap` you will notice it tells you to update your PATH and add
our ffs go compiler and remove the bootstrap compiler.  Your PATH should look like this
(although with your home directory, not mine):

```shell script
echo $PATH
/usr/bin:/bin:/usr/sbin:/sbin:/Users/iansmith/ffs/hostgo/bin
```

### Cleanup
You can test your hostgo with `go version` which should report that it is
go 1.14.4.  Once you have tested your hostgo and verified that your PATH is
in good shape (above) you can delete the downloaded tarball: 
```shell script
rm go1.14.4src.tar.gz
``` 


## Stage 0: Prerequisites: Linux
TBD

## Stage 1: Tinygo (1 hour 15 minutes)

For doing development that involves the target hardware (Raspberry PI 3B+)
or the simulator (QEMU 5.0.0), you'll need tinygo.  Tinygo was originally
targeted at microcontrollers, but because it targets bare hardware, it is
much easier to use for OS development than the "big" go compiler that we 
have just built as hostgo. You can read more about Tinygo
[here](https://tinygo.org/).

Tinygo is actually a layer on top of the [LLVM](http://llvm.org/)
compiler infrastructure.  It uses the back-end of LLVM to produce the code
for microcontrollers and for "aarch64" which is the processor in our Raspberry
Pi 3.  

Use the `tinygo-install.bash` script in the usual way to start the process
of getting tinygo and then download ad build the massive LLVM compiler
infrastructure. (If you forgot, always run scripts from the directory they are
sitting in, like `./tinygo-install.bash`.)  tinygo-install will first use 
git to grab the source code from github and switch to the `dev` branch
at a particular commit id.  You will likely receive a warning like this
```shell script
You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false
```
This warning is harmless and correct.

Once the git operation is done, the script uses two make targets in the tinygo 
repository to download, then build the llvm source code.  These two targets are:
```shell script
make llvm-source
make llvm-build
```
In total, these two targets can take up to about two hours, but 1 hour and a little
bit is much more common on recent computers.  

After llvm is installed, the tinygo-install script uses plain old make to build
tinygo itself (`make`).  This only takes about 5 minutes.

After this process is finished you will receive some instructions about updating
your PATH to include the directories that allow you to run tinygo and
llvm tools.  A 



