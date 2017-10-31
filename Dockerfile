FROM ruby:2.4.2-alpine

RUN apk add --no-cache --virtual .build-dependencies ruby-dev build-base \
  && gem install azure-storage --pre \
  && apk del .build-dependencies  

COPY check in out azure-blobstore-concourse-resource-common.rb /opt/resource/
