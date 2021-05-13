# DJGPP cross-compiler Docker image

This repository contains a Dockerfile for building a Docker image containing a
DJGPP cross compiler.

You can find the pre-built images at:

https://hub.docker.com/r/jodoherty/djgpp

I'm currently having issues building GCC with libstdc++, so C++ support is
incomplete for now. Once I have that sorted, I might write a game programming
tutorial utilizing this cross-compiler container image for easy set up.

If you would like to reproduce my image yourself, first download the files
listed in `sources`. I've included checksums in `SHA256SUMs` so that you can
verify that you have the right files.
