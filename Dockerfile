FROM ubuntu:14.04

# Install the packages we need for getting things done
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      dos2unix \
      git \
    && \
    apt-get clean

# Install the packages we need for Buildbot
RUN apt-get update && \
    apt-get install -y \
      python-dev \
      python-pip \
      supervisor \
    && \
    apt-get clean

# Install Docker and Docker Compose
RUN curl -sSL https://get.docker.com/ | sh && \
    curl -L https://github.com/docker/compose/releases/download/1.5.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install the Python packages we need
COPY requirements2.txt /tmp/requirements2.txt
RUN pip2 install -r /tmp/requirements2.txt && \
    rm /tmp/requirements2.txt

# Create our buildbot directories
RUN mkdir buildbot && \
    cd buildbot && \
    buildbot create-master master && \
    buildslave create-slave slave localhost:9989 worker-slave worker-slave

# Upload our cfg
COPY buildbot/master/master.py /buildbot/master/master.cfg

# Our supervisord runs the master and the slave
COPY etc/supervisor/conf.d/buildbot.conf /etc/supervisor/conf.d/buildbot.conf

# Start the supervisord
cmd ["/usr/bin/supervisord", "-n"]
