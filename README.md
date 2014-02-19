agentscript-models
==================

### Models created by the Concord Consortium using AgentScript.

This repository contains AgentScript models created by the [Concord Consortium](http://www.concord.org).

[AgentScript](https://github.com/backspaces/agentscript) is a Agent Based Modeling (ABM) framework based on [NetLogo](http://ccl.northwestern.edu/netlogo/), created by Owen Densmore. This repository uses the [Concord Consortium branch of Agent Script](https://github.com/concord-consortium/agentscript) which has additional contributions by Concord Consortium.

## Checking out the project

If you have commit access to the repository use this form:

    git clone git@github.com:concord-consortium/agentscript-models.git

Alternatively if you don't have commit access use this form:

    git clone git://github.com/concord-consortium/agentscript-models.git

Then

    git submodule update --init

You can then find the index at file://path.to.agentscript-models/index.html

## Locally viewing models

The models cannot be viewed using a simple `file://` URL.
So you can either use a webserver like apache to serve the files, or use an included ruby based rack server.
To use the rack server you should:

    cd local-server
    bundle install --binstubs
    bin/rackup
    open http://localhost:9292/

If you haven't used bundler, ruby, and rvm or rbenv before, you will probably need to learn a bit about those before this will work for you.

## GitHub pages

The live, production version of this site can be found at http://concord-consortium.github.io/agentscript-models/

The development version can be found at http://concord-consortium.github.io/agentscript-models-dev/

To update the production site, merge your changes into the gh-pages branch of the agentscript-models repository; to update the development site, merge your changes into the gh-pages branch of the agentscript-models-dev repository. It's best to setup a Git remote for the production development sites (as `dev`, say), and to use a different local branch name (such as `gh-pages-dev`) and set it to track `dev/gh-pages,` while allowing `gh-pages` to track the `gh-pages` branch of the production repository
