FROM ubuntu:xenial

RUN apt-get update && \
  apt-get install -y ruby && \
  apt-get install -y ruby-dev && \
  apt-get install -y libssl-dev && \
  apt-get install -y libgit2-dev && \
  apt-get install -y libssh2-1-dev && \
  apt-get install -y pkg-config && \
  apt-get install -y cmake && \
  apt-get install -y git

RUN gem install formatador gli oj rugged

WORKDIR /opt
RUN git clone https://github.com/jrfaller/diggit.git
RUN ln -s /opt/diggit/bin/dgit /usr/bin/dgit

COPY run.sh /usr/bin/run_diggit.sh

RUN mkdir /diggit
VOLUME /diggit

WORKDIR /diggit
CMD ["bash","run_diggit.sh"]
