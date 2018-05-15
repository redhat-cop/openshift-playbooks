FROM ruby:2.4.3-alpine

RUN apk add --no-cache --update \
    make \
    gcc \
    libc-dev \
    python \
    libcurl \
    ;

ENV USER_UID=1001 \
    HOME=/home/jekyll

ADD root /

RUN /usr/local/bin/user_setup

EXPOSE 4000

USER ${USER_UID}

WORKDIR ${HOME}
ENTRYPOINT [ "/usr/local/bin/entrypoint" ]
CMD ["/usr/local/bin/run"]
