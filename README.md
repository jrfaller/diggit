# Diggit

A ruby tool to analyse Git repositories

# Installation

Clone diggit using the following command.

```
git clone https://github.com/jrfaller/diggit.git
```

The diggit tool is in the lib folder. Don't hesitate to create a link to diggit.rb to be able to launch it in any repository.

# Usage

## Configuration

The diggit tool is designed to help you analyze software repositories. Firstly you have to create a new folder in which you launch the `diggit init` command. This way, the folder becomes a diggit folder in which you can configure repositories and analyses.

### Setting-up the repositories

You can add some repositories to be analyzed with the following command: `dgit sources add https://github.com/jrfaller/diggit.git`.

### Using addons

Addons add features the the diggit tool: for instance capability of writing to a mondodb database, etc. To enable addons for your current diggit folder you can use the following command: `dgit addons add TestAddon`.

### Setting-up analyses

An analysis is applied to each repository. You can configure the analyses to be performed with the following command: `dgit analyses add TestAnalysis`. Analyses are performed in the order they have been added.

### Setting-up joins

A join is performed after all analyses of all repositories have been performed. You can configure the joins to be performed with the following command: `dgit joins add TestJoin`. Joins are performed in the order they have been added.

## Running analyses

Once diggit is configured you can perform the analyses. First you have to perform the clone by using `dgit perform clones`. Then you can launch the analyses by using `dgit perform analyses`. Finally, the joins are executed via the command `dgit perform joins`.

At all time, you can check the status of your diggit folder by using `diggit status`. If you want more info on the status of a given repository, you can use the `dgit sources info https://github.com/jrfaller/diggit.git` command.

## Cleaning up

If something is going error, you can always delete the results of the joins by using the command `dgit clean joins` and of the analysis with the command `dgit clean analyses`.
