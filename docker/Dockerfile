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

RUN useradd -ms /bin/bash diggit

USER diggit
WORKDIR /home/diggit

RUN gem install --user-install diggit

USER root

RUN ln -s /home/diggit/.gem/ruby/2.3.0/bin/dgit /usr/bin

USER diggit

RUN dgit init

USER root
COPY plugins plugins
COPY sources .dgit/sources
RUN chown -R diggit:diggit .

USER diggit
