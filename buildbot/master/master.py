import buildbot.plugins
import os

# This file configures a buildmaster via this dictionary
build_config = BuildmasterConfig = {}

# BUILDSLAVES

# 'slaves' list defines the set of recognized build slaves.
# Each element is a BuildSlave object, specifying a unique slave name and password.
# The same slave name and password must be configured on the slave.
build_config['slaves'] = [
    buildbot.plugins.buildslave.BuildSlave('worker-slave', 'worker-slave')
]

# 'protocols' contains information about protocols which master will use for communicating with slaves.
# 'port' option defines where slaves could connect to master with this protocol.
# 'port' must match the value configured into the buildslaves (with their --master option)
build_config['protocols'] = {
    'pb': {'port': 9989}
}

# CHANGESOURCES

# 'change_source' tells the buildmaster how it should find out about source code changes
repositories = [environ for environ in os.environ if environ.startswith('GIT_REPOSITORY')]

build_config['change_source'] = []
for repository_current in repositories:
    branch = os.environ.get(repository_current + '_BRANCH', 'master')

    build_config['change_source'].append(
        buildbot.plugins.changes.GitPoller(
            os.environ[repository_current],
            workdir='gitpoller-workdir-{}'.format(repository_current),
            branches=[branch],
            pollinterval=300
        )
    )

# SCHEDULERS

# 'schedulers' decide how to react to incoming changes
build_config['schedulers'] = [
    buildbot.plugins.schedulers.SingleBranchScheduler(
        name='all',
        change_filter=buildbot.plugins.util.ChangeFilter(),
        # treeStableTimer=None,
        builderNames=['restart-services']
    )
]

# BUILDERS

# 'builders' define how to perform a build: what steps, and which slaves can execute them.
# note that any particular build will only take place on one slave.
services = [os.environ[environ] for environ in os.environ if environ.startswith('SERVICE')]

factory = buildbot.plugins.util.BuildFactory()
for service_current in services:
    factory.addStep(
        buildbot.plugins.steps.ShellCommand(
            command=['docker-compose', '-f', '/docker-compose/docker-compose.yml', 'build', service_current]
        )
    )
for service_current in services:
    factory.addStep(
        buildbot.plugins.steps.ShellCommand(
            command=['docker-compose', '-f', '/docker-compose/docker-compose.yml', 'up', '--no-deps', '--force-recreate', '-d', service_current]
        )
    )

build_config['builders'] = [
    buildbot.plugins.util.BuilderConfig(
        name='restart-services',
        slavenames=['worker-slave'],
        factory=factory
    )
]

# STATUS TARGETS

# 'status' is a list of Status Targets. The results of each build will be
# pushed to these targets. buildbot/status/*.py has a variety to choose from,
# including web pages, email senders, and IRC bots.
build_config['status'] = []

# PROJECT IDENTITY

# 'title' will appear at the top of this buildbot installation's html.WebStatus home page
# (linked to the 'titleURL') and is embedded in the title of the waterfall HTML page.
build_config['title'] = 'Watcher'
build_config['titleURL'] = 'https://github.com/fogies/docker-watcher'

# 'buildbotURL' string should point to the location where the buildbot's
# internal web server (usually the html.WebStatus page) is visible.
# This typically uses the port number set in the Waterfall 'status' entry, but with
# an externally-visible host name which the buildbot cannot figure out without some help.
build_config['buildbotURL'] = 'http://localhost:8010/'

# DB URL
build_config['db'] = {
    # This specifies what database buildbot uses to store its state.
    # You can leave this at its default for all but the largest installations.
    'db_url': 'sqlite:///state.sqlite',
}
