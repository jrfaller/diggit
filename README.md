# Diggit [![Build Status](https://travis-ci.org/jrfaller/diggit.svg?branch=develop)](https://travis-ci.org/jrfaller/diggit) [![Coverage Status](https://coveralls.io/repos/jrfaller/diggit/badge.svg?branch=develop)](https://coveralls.io/r/jrfaller/diggit?branch=develop) [![Inline docs](http://inch-ci.org/github/jrfaller/diggit.svg?branch=develop)](http://inch-ci.org/github/jrfaller/diggit)

A ruby tool to analyze Git repositories

# Installation

## Prerequisites

In order for Ruby's libgit binding, [rugged](Pre-requisites), to work, you need to install several native libraries. To build the libgit version shipped with rugged's gem, you need `pkg-config` and `cmake` installed. If you want rugged to be able to clone ssh or https repositories, you need several additional depenc as listed on [libgit website](https://github.com/libgit2/libgit2#optional-dependencies).

## From a gem

Just run `gem install diggit`.

## From the source, with bundler

Install diggit using the following commands:
```
git clone https://github.com/jrfaller/diggit.git
cd diggit
gem install bundler --user-install
bundler install
```
Beware, the gem bin directory must be in your path. Also, the `dgit` command is in the `bin` folder of diggit.

## From the source, with vagrant

You can automatically get a working VM with all required dependencies with only one command, how cool is that? For this, just install [vagrant](https://www.vagrantup.com/) and [virtualbox](https://www.virtualbox.org/), and `vagrant up` in a freshly cloned diggit folder (see previous section). Beware, this magic only works on Mac OS and Linux because it uses NFS shared folders. Note that if you use this method, you don't care about the prerequisites.

# Usage

Don't forget that dgit binary has an associated help that can be consulted using `dgit help`.

## Configuration

The diggit tool is designed to help you analyze software repositories. Firstly you have to create a new folder in which you launch the `dgit init` command. This way, the folder becomes a diggit folder in which you can configure repositories and analyses.

### Setting-up the repositories

You can add some repositories to be analyzed with the following command: `dgit sources add https://github.com/jrfaller/diggit.git`.

### Using addons

Addons add features the the diggit tool: for instance capability of writing to a MongoDB database, etc. To enable addons for your current diggit folder you can use the following command: `dgit addons add test_addon`.

### Setting-up analyses

An analysis is applied to each repository. You can configure the analyses to be performed with the following command: `dgit analyses add test_analysis`. Analyses are performed in the order they have been added. Analyses are provided in the `plugins/analysis` folder (from the diggit installation or in any initialized diggit folder). The filename of an analysis is the underscore cased name of the class where it is defined (which is camel cased).

### Setting-up joins

A join is performed after all analyses of all repositories have been performed. You can configure the joins to be performed with the following command: `dgit joins add test_join`. Joins are performed in the order they have been added. Similarly to analyses, joins are provided in the `plugins/join` folder (from the diggit installation or in any initialized diggit folder). The filename of a join is the underscore cased name of the class where it is defined (which is camel cased). 

## Running analyses

Once diggit is configured you can perform the analyses. First, you have to clone the repositories by using `dgit clones perform`. Then you can launch the analyses by using `dgit analyses perform`. Finally, the joins are executed via the command `dgit joins perform`. You can use the `mode` option to handle the cleaning of joins or analyses.

At all time, you can check the status of your diggit folder by using `dgit status`.
