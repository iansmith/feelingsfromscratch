# FAQ Regarding Feelings From Scratch

### Why did you do this?
The purpose is to have a standard set of dev tools for all
developers.  There are simply too many libraries and binaries
to commit all of them to the repo.

### Why do you link so many things statically?
Since the purpose is to have _common_ set of dev tools, there
is no reason to introduce any uncertainty.  When you use dynamic
linking there is always the chance that you are inadvertently
picking a up a library, that has the same name, that you did not
intend to.

### Why do you hate brew and other package managers?
Broadly, when you let somebody else make decisions about
your machine's layout/setup you are no longer able to be
sure about what state the machine is in.  Did brew install
something in a place I wasn't expecting?  Did brew get the
right version (exactly) that I need to use so I am in sync
with other developers?  Building your own "virtual machine"
of tools from scratch, like these instructions do, is the
way to have confidence in whay you are running.

### Why do you use such a tiny PATH?
Again, the purpose is to create certainty about what is
running.  A common source of errors is to "not be 
runnign what you thought you were" because of a mistaken
PATH setup.  The less that is the PATH, the fewer things
that can go wrong.

### Why not use -j4 or -j8 when doing make?
This build of the necessary tools for feelings takes a long
time.  I assume that you will be using your machine for other 
things while the build is going on, thus you don't want your
machines entire capacity used by the build.  Feel free to
change any of the scripts to use -j4 or -j8 or your choice
of jobs if you prefer a faster build and a less responsive
system.
