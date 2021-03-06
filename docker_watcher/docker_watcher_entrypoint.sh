#!/bin/bash

# This file compiled from base/docker-pyramid-site-entrypoint.sh.in


# Modeled on:
#
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

set -e

# Ensure we have our Python dependencies
pip install -r requirements3.txt

# Change into the project directory
cd docker_watcher

# Create our buildbot directories
cd buildbot
buildbot create-master master
buildbot-worker create-worker worker localhost:9989 worker worker
cd ..

# Put our buildbot config in place
rm -f buildbot/master/buildbot.tac
ln -s /docker_watcher/buildbot/buildbot.tac buildbot/master/buildbot.tac
rm -f buildbot/master/master.cfg
ln -s /docker_watcher/buildbot/master.cfg buildbot/master/master.cfg

# Put our supervisord config in place
rm -f /etc/supervisor/conf.d/buildbot.conf
ln -s /docker_watcher/etc/supervisor/conf.d/buildbot.conf /etc/supervisor/conf.d/buildbot.conf

# Start the supervisord
exec /usr/bin/supervisord -n
