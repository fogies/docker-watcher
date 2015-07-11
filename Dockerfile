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

# Install the Python packages we need
COPY requirements2.txt /tmp/requirements2.txt
RUN pip2 install -r /tmp/requirements2.txt && \
    rm /tmp/requirements2.txt

# Install Docker and Fig
RUN curl -sSL https://get.docker.com/ubuntu/ | sh && \
    curl -L https://github.com/docker/fig/releases/download/1.0.1/fig-`uname -s`-`uname -m` > /usr/local/bin/fig; chmod +x /usr/local/bin/fig

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