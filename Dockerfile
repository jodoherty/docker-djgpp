FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y build-essential \
    autoconf automake bison file flex gdb texinfo unzip \
    libgmp-dev libisl-dev libmpfr-dev libmpc-dev \
    && \
    mkdir -p /usr/local/src && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -s /bin/bash -m djgpp

ARG INSTALL_PREFIX=/opt/djgpp

ENV PATH=$PATH:$INSTALL_PREFIX/bin

ARG TARGET=i586-pc-msdosdjgpp
ARG BINUTILS_VERSION=2.36.1

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

RUN cd /home/djgpp/src/binutils-build && make install

USER djgpp

ARG GCC_VERSION=11.1.0

ADD gcc-$GCC_VERSION.tar.gz /home/djgpp/src/

RUN cd /home/djgpp/src && \
    mkdir gcc-build && \
    cd gcc-build && \
    ../gcc-$GCC_VERSION/configure \
        --prefix=$INSTALL_PREFIX --target=$TARGET \
        --disable-nls \
        --disable-plugin \
        --disable-gcov \
        --enable-libstdcxx-filesystem-ts \
        --enable-libquadmath-support \
        --enable-version-specific-runtime-libs \
        --enable-languages=c && \
    make -j8

USER root

RUN cd /home/djgpp/src/gcc-build && make install && \
    ln -s $INSTALL_PREFIX/$TARGET/djcrx/lib/specs \
          $INSTALL_PREFIX/lib/gcc/$TARGET/$GCC_VERSION/specs

USER djgpp

VOLUME /home/djgpp/src
WORKDIR /home/djgpp/src


