FROM ruby:2.3-alpine

ENV DOCKER_VERSION=1.8.3

RUN apk add --update curl bash grep && \
  curl --silent \
    --show-error \
    --location \
    https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION \
    --output /usr/bin/docker && \
  chmod +x /usr/bin/docker

ADD deis-cleanup.rb /deis-cleanup.rb

CMD ["./deis-cleanup.rb"]
