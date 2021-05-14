# DJGPP cross-compiler Docker image

This repository contains a Dockerfile for building a Docker image containing a
DJGPP cross compiler.

You can find the pre-built images at:

https://hub.docker.com/r/jodoherty/djgpp

If you would like to reproduce my image yourself, first download the files
listed in `sources`. I've included checksums in `SHA256SUMs` so that you can
verify that you have the right files.

The include `gcc-libstdcxx.diff` patch makes the following changes for
libstdc++v3 to compile:

* The alignment of certain fields in `get_mutex` in `shared_ptr.cc` was
  reverted to that of the GCC 9 line, since the new alignment isn't compatible
  with DJGPP.

* Some C++17 filesystem APIs were removed.

