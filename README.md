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

With the exception of the Land Management model, most models can be viewed by simply starting up a local server in the root of this repository. No build step is required. The easiest way to do this is with Python's built-in web server class:

    cd <root of project>
    python -m SimpleHTTPServer      # Protip: just alias this to `serve`. You'll use it a lot.
    open http://localhost:8000/

Alternately, you can use the Ruby Rackup server in `local-server/` but this requires installing gems and is hardly necessary.

## Building Land Management and Air Pollution Models with Brunch

To view any of the individual Land Management or Air Pollution models, you first need to build the model using [Brunch](http://brunch.io/). First. `cd` to the root directory for the specific model type -- `land-management/` or `air-pollution/` -- and run `brunch build`, then serve files from the `public` directory _under_ the root directory for the specific model type -- _e.g._, `land-management/public/`. You can use `brunch watch` when in the root directory for the specific model to rerun the build step automatically whenever changes are made to the source files. You may want to ignore the public directories in your text editor so that you don't inadvertently edit built files instead of source files.

Make sure that your `Brunch` version is **>= 1.7.20**! For example Brunch v1.7.19 was breaking the build system. Run `sudo npm install -g brunch` to install the latest available version.

## Deploying

Then production version of these models are hosted at https://models-resources.concord.org/agentscript/index.html

A development version can be found at this GitHub Pages site: http://concord-consortium.github.io/agentscript-models/

A second development version also exists: http://concord-consortium.github.io/agentscript-models-dev/ (This is useful for comparing old and new versions while still enjoying the convenience of GitHub Pages for both; we can treat the first development site like a "staging" site.)

The `gh-pages` branch of the two repositories (`agentscript-models` and `agentscript-models-dev`) now have an independent revision history from the `master` branch. Never merge `master` into `gh-pages`; instead, manage them as follows.

* Clone the `gh-pages` branch into the `public` directory at the root of the repository. You may wish to add the second ("`-dev`") repository as an additional remote (say, "dev") and track its `gh-pages` branch using a local branch named `dev-gh-pages` or something like that.
```
<in the root of the repository, with the master branch checked out>
$ git clone -b gh-pages git@github.com:concord-consortium/agentscript-models.git public
$ cd public
$ git remote add dev git@github.com:concord-consortium/agentscript-models-dev.git
$ git fetch dev
$ git checkout -b dev-gh-pages --track dev/gh-pages
```
* When you want to update gh-pages, run this script in the root of the repository (not in the `public` directory made in
the previous step):
```
$ ./update-public.sh
```
* `cd` to `public/`, commit the changes (add a descriptive commit mentioning the SHA of the related commit in the main repository), and push.

To update the production version, merge `gh-pages` into `production` and push to the `agentscript-models` repository. The Travis build process will use the `s3_website` Gem to update the `resources.models.concord.org` site.
