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

The models cannot be viewed using a simple `file://` URL and need to be served by a local server. The easiest way to do this is with Python's built-in web server class:

    cd <root of project>
    python -m SimpleHTTPServer      # Protip: just alias this to `serve`. You'll use it a lot.
    open http://localhost:8000/

Alternately, you can use the Ruby Rackup server in `local-server/` but this requires installing gems and is hardly necessary.

## GitHub pages

The live, production version of this site can be found at http://concord-consortium.github.io/agentscript-models/

The development version can be found at http://concord-consortium.github.io/agentscript-models-dev/

To update the production site, merge your changes into the gh-pages branch of the agentscript-models repository; to update the development site, merge your changes into the gh-pages branch of the agentscript-models-dev repository. It's best to setup a Git remote for the production development sites (as `dev`, say), and to use a different local branch name (such as `gh-pages-dev`) and set it to track `dev/gh-pages,` while allowing `gh-pages` to track the `gh-pages` branch of the production repository
