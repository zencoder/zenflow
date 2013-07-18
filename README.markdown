# Zenflow

[![Gem Version](https://badge.fury.io/rb/zenflow.png)](http://badge.fury.io/rb/zenflow)
[![Code Climate](https://codeclimate.com/repos/51bf6e3b7e00a411ad00f6c3/badges/111fbe3664cebffa8e23/gpa.png)](https://codeclimate.com/repos/51bf6e3b7e00a411ad00f6c3/feed)
[![Coverage Status](https://coveralls.io/repos/zencoder/zenflow/badge.png)](https://coveralls.io/r/zencoder/zenflow)
[![Dependency Status](https://gemnasium.com/a1d29c5ea446d54bead93a6878bc204b.png)](https://gemnasium.com/zencoder/zenflow)
![CircleCI](https://circleci.com/gh/zencoder/zenflow.png?circle-token=992f1e59d778a8f6eef0fb9f2888e80cf60d7226)

-------

* [Getting Started](#getting-started)
* [Usage](#usage)
* [Commands Quick Reference](#commands)
* [Requirements](#requirements)

-------

### What is Zenflow?

Zenflow is a Ruby implimentation of the [GitFlow process](http://nvie.com/posts/a-successful-git-branching-model/) for managing development in Git. It's been used at [Zencoder](http://zencoder.com) since 2010 and we've benefitted greatly from the structure it helps enforce, so we wanted to share it with the world.

### <a name="getting-started"></a> Getting Started

Start off by installing the gem.

    gem install zenflow

Once you've installed the gem there are a few questions to answer so that Zenflow knows what sort of branches you want to track and what your qa/staging/production setup looks like.

To get started make sure you're in the root directory of the repository you want to work with, then run

    zenflow init

and answer the questions, then you're ready to start using Zenflow!

### <a name="usage"></a> Usage

#### Features

In Zenflow a feature branch is used to isolate the development of a new feature or refactoring of existing code.

To start a feature in Zenflow run `zenflow feature start`.

You'll be asked for the name of the feature - make it something descriptive - and a new branch will be creaated from master called feature/FEATURE-NAME.

Now you can work and commit normally. If you have Capistrano set up with a QA server, you can deploy the feature at any time by running `zenflow feature deploy`. This will merge the current feature branch in to the qa branch, deploy to the QA server if you have one configured with Capistrano, then go back to the feature branch.

If master has been updated and you want the latest code brought to your feature, you can run `zenflow feature update` to merge the latest code from master.

When you're ready for code review run `zenflow feature review` to create a pull request on GitHub, comparing the master branch and the feature branch. Work with any feedback from the rest of the team as necessary until the code is ready for production.

Once development of the feature is completed run `zenflow feature finish` to merge the feature branch in to master and delete the local and remote branches. If Zenflow is set up to confirm review and testing you'll be asked if you've tested this code on QA and had it code reviewed. Don't lie to Zenflow.

#### Releases

As features are finished they accumulate in the `master` branch. To get them to production we create a release.

To start a release in Zenflow run `zenflow release start` and provide a release name. Themed release names are fun - robots, spaceships, football players, flowers. Something there's a lot of.

There's typically not much that should be done within a new release - active development isn't supposed to happen at this stage. If code review turns up a bug fix it here, but anything more should be done in a feature or hotfix branch.

Once the release is made, typing `zenflow release deploy` will merge the release in to the staging branch, deploy to staging if you have a staging server configured with Capistano, then switch back to the release branch.

After confirming that things are running properly on Staging a release can be reviewed on GitHub by typing `zenflow release review`, which creates a pull request from the release to the production branch.

Once review is completed, type `zenflow release finish` to merge the release branch in to production and delete the local and remote release branches.

To deploy to production, type `zenflow deploy production`.

#### Hotfixes

Hotfixes are used for code updates that need to be deployed outside of a release, usually to address a breaking issue in production.

To start a hotfix type `zenflow hotfix start`. This creates a new hotfix branch off of the production branch.

After the hotfix branch is created you can work and commit as normally. Running `zenflow hotfix deploy` deploys to the staging and qa servers.

When you're ready for code review run `zenflow hotfix review` to create a pull request on GitHub, comparing the production branch and the hotfix branch. Work with any feedback from the rest of the team as necessary until the code is ready for production.

Once development of the feature is completed run `zenflow hotfix finish` to merge the feature branch in to production and master, plus delete the local and remote branches. If Zenflow is set up to confirm review and testing you'll be asked if you've tested this code on QA and had it code reviewed. Don't lie to Zenflow.

To deploy to production, type `zenflow deploy production`. Hotfixes are not automatically deployed to production when they are finished.

#### <a name="commands"></a> Commands Quick Ref

  zenflow init
  zenflow (feature|hotfix|release) start
  zenflow (feature|hotfix|release) deploy
  zenflow (feature|hotfix|release) review
  zenflow (feature|hotfix|release) finish
  zenflow deploy (qa|staging|production)

### <a name="requirements"></a> Requirements/Assumptions

* Git >= 1.8
* Ruby >= 1.9.3
* Capistrano and cap-ext
* A repository on GitHub
