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

### How do I reset this directory and try again?
rm -rf src build tools hostgo tinygo

### Why do you use such a tiny PATH?
Again, the purpose is to create certainty about what is
running.  A common source of errors is to "not be 
runnign what you thought you were" because of a mistaken
PATH setup.  The less that is the PATH, the fewer things
that can go wrong.
