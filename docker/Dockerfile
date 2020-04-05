FROM ruby:2.7.1-alpine3.11

# Install dependencies
RUN apk add --update --no-cache \
    make \
    cmake \
    g++ \
    git \
    diffutils \
    cloc \
    libgit2 \
    openssl-dev \
    && gem install bundler \
    && rm -rf /var/cache/apk/*

# Install dgit
WORKDIR /opt
COPY . /opt/diggit
WORKDIR /opt/diggit
RUN bundle install
ENV BUNDLE_GEMFILE /opt/diggit/Gemfile

RUN mkdir /data
VOLUME /data
WORKDIR /data

ENTRYPOINT ["bundle", "exec", "/opt/diggit/bin/dgit"]
