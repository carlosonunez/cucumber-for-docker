FROM ruby:alpine

RUN apk add --no-cache libc-dev \
  linux-headers \
  libxml2-dev \
  libxslt-dev \
  readline-dev \
  gcc \
  libffi-dev \
  readline \
  build-base
RUN gem install nokogiri -- --use-system-libraries
RUN gem install capybara cucumber selenium-webdriver
RUN gem install rspec

ENTRYPOINT ["cucumber"]

