FROM ubuntu:xenial

USER root

RUN apt-get update && \
  apt-get install -y ruby && \
  apt-get install -y ruby-dev && \
  apt-get install -y libssl-dev && \
  apt-get install -y libgit2-dev && \
  apt-get install -y libssh2-1-dev && \
  apt-get install -y pkg-config && \
  apt-get install -y cmake
RUN mkdir /var/diggit
RUN gem install diggit

WORKDIR /var/diggit

ONBUILD RUN dgit init
ONBUILD COPY plugins plugins
ONBUILD COPY sources .dgit/sources
ONBUILD RUN dgit clones perform
ONBUILD VOLUME /var/diggit

ENTRYPOINT ["/usr/local/bin/dgit"]
