FROM redis:2.8
#RUN yum -y update
#RUN yum install -yy -q python
RUN apt-get update
RUN apt-get install -yy -q python

COPY redis-master.conf /redis-master/redis.conf
COPY redis-slave.conf /redis-slave/redis.conf
COPY run.sh /run.sh

CMD [ "/run.sh" ]
ENTRYPOINT [ "sh", "-c" ]
