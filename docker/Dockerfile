FROM ruby:2.2-alpine

RUN apk add --update --no-cache \
    make \
    cmake \
    g++ \
    git \
    && gem install formatador gli oj rugged \
    && apk del make cmake g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /opt
RUN git clone https://github.com/jrfaller/diggit.git \
    && ln -s /opt/diggit/bin/dgit /usr/bin/dgit

RUN mkdir /diggit
VOLUME /diggit

WORKDIR /diggit
ENTRYPOINT ["/bin/sh", "run.sh"]
