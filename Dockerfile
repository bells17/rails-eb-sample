FROM ruby:2.5.1-slim

WORKDIR /app

ENV TZ Asia/Tokyo
ENV LANG en_US.UTF-8
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
  && apt-get install -y --no-install-recommends \
    nodejs \
    yarn \
    locales \
    default-libmysqlclient-dev \
    libxml2-dev \
    libxslt-dev \
  && rm -rf /var/lib/apt/lists/* \
  && rm /etc/apt/sources.list.d/yarn.list \
  \
  && echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata \
  && locale-gen en_US.UTF-8 \
  && localedef -f UTF-8 -i en_US en_US.utf8
ENV LC_CTYPE en_US.UTF-8

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
ARG BundlerInstallOption='-j3 --deployment --without test'
RUN buildDeps=' \
    build-essential \
    pkg-config \
  ' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  \
  && bundle config build.nokogiri --use-system-libraries \
  && bundle install $BundlerInstallOption \
  \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get purge -y --auto-remove $buildDeps

COPY . /app
RUN bundle exec rake assets:precompile
CMD bundle exec rails s
