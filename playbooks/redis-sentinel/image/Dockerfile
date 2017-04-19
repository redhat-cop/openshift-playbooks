FROM rhel7:latest
USER root

MAINTAINER Shah_Zobair

RUN yum update -y
RUN yum install make gcc cc tar python -y
RUN yum -y install deltarpm yum-utils --disablerepo=*-eus-* --disablerepo=*-htb-* \
    --disablerepo=*-ha-* --disablerepo=*-rt-* --disablerepo=*-lb-* --disablerepo=*-rs-* --disablerepo=*-sap-*

RUN yum-config-manager --disable *-eus-* *-htb-* *-ha-* *-rt-* *-lb-* *-rs-* *-sap-* > /dev/null

RUN \
  cd /tmp && \
  curl -O http://download.redis.io/redis-stable.tar.gz && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  cd deps && \
  make hiredis jemalloc linenoise lua && \
  cd .. && \
  make && \
  make install && \
  cp -f src/redis-sentinel /usr/local/bin && \
  mkdir -p /redis-master && \
  mkdir -p /redis-slave && \
  rm -rf /tmp/redis-stable*


COPY redis-master.conf /redis-master/redis.conf
COPY redis-slave.conf /redis-slave/redis.conf
COPY run.sh /run.sh
RUN chmod 755 /run.sh

CMD [ "/run.sh" ]
ENTRYPOINT [ "/bin/bash", "-c" ]
