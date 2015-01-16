## Goal

Develop email in a separate git repo, but allow easy consumption by mozilla-b2g/gaia and do not force a change in behavior for gaia consumers, for things like builds and localizations.

## General plan

1) Create a new `gaia-email` repo that carries over the mozilla-b2g/gaia git history for `apps/email`.

2) Use tooling that can pull over changes from mozilla-b2g/gaia into the gaia-email. This should be isolated to following:

* build changes that affect mozilla-b2g/gaia.
* localization changes, except en-US, which is modified in gaia-email.
* /shared files.

3) Tooling that can push changes from gaia-email to mozilla-b2g/gaia. This should just be the app changes.

## Creation of the repo

```
git clone git@github.com:mozilla-b2g/gaia.git gaia-email
cd gaia-email
git filter-branch --subdirectory-filter apps/email -- --all
```

For cleanup:

```
git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
git reflog expire --expire=now --all
git gc --prune=now
```

Check the history, make sure the email history is in there.

Set up new directory structure, to hold docs and other things at the top level, and have the app in a nested gaia-email directory for ease of deployment without deploying support files. The goal is to end up with a structure like this inside the repo:

* docs
* gaia-email
* README.md

```
mkdir gaia-email
git mv autoconfig gaia-email
git mv index.html gaia-email
git mv js gaia-email
git mv locales/ gaia-email
git mv manifest.webapp gaia-email
git mv sounds gaia-email
git mv style gaia-email
git mv .jshintrc gaia-email/js/
cp ../gaia/.jshintrc .jshintrc
```


Then update the .git/config to point "origin" to new URL, like to `git@github.com:jrburke/gaia-email.git`.

Finally, push the code to github:

```
git push origin refs/remotes/origin/*:refs/heads/*
```

## Builds

* do l10n locale stuff
* make sure that gaia-email/shared stays intact when copying over.


## TODO

* Cannot go privileged because document.registerElement not available to privileged apps.
* make sure linting works
* Hook up pre-commit hook for js/css linting, install as part of Makefile setup
* have an npm install locally for jshint
* what about `make DEBUG=1` case.
* Cannot run source file directly on device because of funtion.tostring stripping. KHAAAAN!

## DOC TODO

* set up local.mk for location of GAIA_DIR
* using sync-shared and sync-email


