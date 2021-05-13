ARG DEBIAN_IMAGE_TAG=buster

ARG INSTALL_PREFIX=/opt/djgpp
# This one isn't meant to be configurabe. It's really just here as an arg so
# that it's only set during the build.
ARG DEBIAN_FRONTEND=noninteractive

FROM debian:$DEBIAN_IMAGE_TAG

# Docker build args are scoped. This brings in the args from the global scope
# at the top into this stage.
# https://github.com/moby/moby/issues/37345
ARG INSTALL_PREFIX
ARG DEBIAN_FRONTEND

# These args are only used in this stage, so we just define them here.
ARG TARGET=i586-pc-msdosdjgpp
ARG BINUTILS_VERSION=2.36.1
ARG GCC_VERSION=11.1.0

RUN apt-get update -y && \
    apt-get install -y build-essential bison file flex texinfo unzip \
    libgmp-dev libisl-dev libmpfr-dev libmpc-dev && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -s /bin/bash -m djgpp

ENV PATH=$PATH:$INSTALL_PREFIX/bin

USER djgpp

RUN mkdir -p /home/djgpp/src

COPY djcrx205.zip /home/djgpp/src/

USER root

RUN mkdir -p $INSTALL_PREFIX/$TARGET && \
    cd $INSTALL_PREFIX/$TARGET && \
    mkdir -p djcrx && \
    cd djcrx && \
    unzip -a /home/djgpp/src/djcrx205.zip && \
    cd $INSTALL_PREFIX/$TARGET && \
    mkdir -p bin lib && \
    gcc -O ./djcrx/src/utils/bin2h.c -o bin/bin2h && \
    gcc -O ./djcrx/src/stub/stubify.c -o bin/stubify && \
    gcc -O ./djcrx/src/stub/stubedit.c -o bin/stubedit && \
    ln -s $INSTALL_PREFIX/$TARGET/djcrx/include include && \
    ln -s $INSTALL_PREFIX/$TARGET/djcrx/lib/* lib

USER djgpp

ADD binutils-$BINUTILS_VERSION.tar.gz /home/djgpp/src/

RUN cd /home/djgpp/src && \
    mkdir binutils-build && \
    cd binutils-build && \
    ../binutils-$BINUTILS_VERSION/configure \
        --prefix=$INSTALL_PREFIX --target=$TARGET \
        --disable-nls --disable-werror && \
    make -j4

USER root

RUN cd /home/djgpp/src/binutils-build && make install-strip

USER djgpp


ADD gcc-$GCC_VERSION.tar.gz /home/djgpp/src/

# Currently I'm building this without libstdc++ because it fails
# with an error.
RUN cd /home/djgpp/src && \
    mkdir gcc-build && \
    cd gcc-build && \
    ../gcc-$GCC_VERSION/configure \
        --prefix=$INSTALL_PREFIX --target=$TARGET \
        --disable-nls \
        --disable-plugin \
        --disable-gcov \
        --disable-libstdcxx \
        --enable-libquadmath-support \
        --enable-version-specific-runtime-libs \
        --enable-languages=c,c++ && \
    make -j8

USER root

RUN cd /home/djgpp/src/gcc-build && make install-strip && \
    ln -s $INSTALL_PREFIX/$TARGET/djcrx/lib/specs \
          $INSTALL_PREFIX/lib/gcc/$TARGET/$GCC_VERSION/specs

# Now create the cross-compiler host image. This prevents all of the copied and
# extracted sources from the previous stage from being in the final image.

FROM debian:$DEBIAN_IMAGE_TAG

ARG INSTALL_PREFIX
ARG DEBIAN_FRONTEND

RUN apt-get update -y && \
    apt-get install -y make libgmp10 libisl19 libmpc3 libmpfr6 zlib1g && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -s /bin/bash -m djgpp

COPY --from=0 $INSTALL_PREFIX $INSTALL_PREFIX

USER djgpp

RUN mkdir -p /home/djgpp/src

VOLUME /home/djgpp/src
WORKDIR /home/djgpp/src

ENV PATH=$PATH:$INSTALL_PREFIX/bin

