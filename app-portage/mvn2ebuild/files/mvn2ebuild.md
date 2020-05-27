MVN2EBUILD 1 "Version 1.0.0: May 2020"
======================================

[//]: # ( Convert to manpage using e.g. go-md2man -in=mvn2ebuild.md -out=mvn2ebuild.1 )

NAME
----

mvn2ebuild - create a starter ebuild for a Maven project

SYNOPSIS
--------

`mvn2ebuild` [*MVN_OPTIONS*]

DESCRIPTION
-----------

`mvn2ebuild` is a simple script that can be used to create a 'starter'
ebuild from a (working) Maven Java project. It is invoked in place
of `mvn`, in the top level directory, passing any options that
would normally be given to `mvn` (`-DskipTests` etc.)

The resulting ebuild is emitted to stdout; any other messages are
sent to stderr.

The (usually long) list of URLs of all the jars, poms,
etc that are required to be present in the Maven
cache, in order to build and run the project, will be explicitly
captured in the *EMAVEN_VENDOR* array in the resulting ebuild
(transformed into the correct format for use
by the `java-mavan-pkg` eclass, which it inherits).

This, in turn, allows for the construction (via the eclass) of 
an 'on-the-fly' Maven cache during the
ebuild's `src_prepare()` phase, sufficient to allow the rest of
the build to proceed without needing to hit the network at all
(necessary, if it is to run properly inside the `portage`(5) sandbox).

You will almost certainly need to provide further functionality to
the resulting ebuild, before it is ready for deployment.

OPTIONS
-------

`[MVN_OPTIONS]`
   Pass any options to `mvn2ebuild` that you normally would to your
   (working) `mvn` clean build invocation. By default (if nothing is passed)
   the following 'equivalent' Maven invocation will be assumed:
   `mvn -DskipTests -Dassembly.skipAssembly=false clean package install -f pom.xml`
   Note that `mvn2ebuild` also passes
   `-Dos.detected.{name,os,classifier}` parameters, to ensure these
   are set correctly.


ALGORITHM
---------

The script works by invoking `mvn` with a temporary cache that is
initially empty, and then recording all files downloaded, using these
to populate the *EMAVEN_VENDOR* array in the ebuild.

If invoked inside a `git`(1) repository, `mvn2ebuild` will
automatically inherit the `git-r3` eclass in the ebuild, and
set *EGIT_REPO_URI*, *EGIT_BRANCH* and *EGIT_COMMIT* appropriately.


BUGS
----

This is a very simple script, so many edge cases exist that can fool
it. For example, if you pass some build options, but omit `clean`, then
the resulting *EMAVEN_VENDOR* may be incomplete. The parsing out of
Maven coordinates from captured URLs is primitive and may not work
in certain cases. No attempt to create e.g. appropriate `src_install()`
functions for zipped assemblies (etc.) is attempted (you need to roll
your own install in such a case, but that is not particularly difficult).


COPYRIGHT
---------

Copyright © 2020 sakaki

License GPLv3+ (GNU GPL version 3 or later)
<http://gnu.org/licenses/gpl.html>

This is free software, you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


AUTHOR
------

sakaki — send bug reports or comments to <sakaki@deciban.com>


SEE ALSO
--------

`ebuild`(5), `git`(1), `portage`(5)
