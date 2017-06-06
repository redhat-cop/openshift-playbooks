FROM ruby:2.3-alpine

RUN apk add --no-cache --update \
    make \
    gcc \
    libc-dev \
    python \
    ;

ADD bin/start.sh /home/jekyll/

WORKDIR /home/jekyll

EXPOSE 4000

CMD ["/bin/sh", "--login", "/home/jekyll/start.sh"]
