FROM centos:7

MAINTAINER Andrew Block “andrew.block@redhat.com”

# Update System and install clients
RUN yum update -y; \
	yum install -y epel-release which git tar java-1.8.0-openjdk libyaml-devel openssh-server autoconf gcc-c++ readline-devel zlib-devel libffi-devel openssl-devel automake libtool bison sqlite-devel; \
	yum install -y nodejs; \
 	yum clean all; \
	useradd builder; \
	echo "builder:builder" | chpasswd;

ADD bin/start.sh /home/builder/

RUN echo "export BUNDLE_PATH=/home/builder/bundle" >> /home/builder/.bash_profile; \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''; \
    chown builder:builder /home/builder/start.sh; \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash; \
	bash -c "source /root/.nvm/install.sh"; \
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3; \
	curl -sSL https://get.rvm.io | bash -s stable; \
	source /etc/profile.d/rvm.sh;
	
RUN	/bin/bash -l -c "rvm requirements"; 
RUN	/bin/bash -l -c "rvm install 2.3.0";
RUN	/bin/bash -l -c "rvm use 2.3.0";
RUN	/bin/bash -l -c "rvm rubygems latest";
RUN /bin/bash -l -c "gem install bundler";

ENV BUNDLE_PATH /home/builder/bundle

# Expose port
EXPOSE 4000 22

# Set /root as starting directory
WORKDIR /home/builder

# Start Command
CMD ["/bin/bash", "--login", "/home/builder/start.sh"]
