FROM ruby:2.4.2-alpine

RUN gem install azure-storage --pre

COPY check in out azure-blobstore-concourse-resource-common.rb /opt/resource/
