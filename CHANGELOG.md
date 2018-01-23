# Changelog of Diggit

### Version 3.0.2
* Added version command

### Version 3.0.1
* Verbose option now used
* Improved gemspec
* Use new OJ upstream
* Improve help messages

### Version 3.0.0 (Cod)
* Compatible with new Oj version
* Cleaner docker image
* Updated conflict_merge analysis
* Fix dependencies vulnerabilities

### Version 2.1.2
* Improve documentation
* Fix bug of `sources del`

### Version 2.1.1
* Fixed small bugs in the CLI
* Fixed source error not showing up in case of clone error
* Now urls can have a trailing `|id` to enable checkout a tag, branch or commit with a specific id
* Out addon have more utility methods

### Version 2.1.0
* Now repositories are reseted to master by default
* Journal infrastructure has been vastly improved
* Journal now records time for analyses and joins
* Journal now handles runnables with clean errors

### Version 2.0.2
* Fixed analysis cleaning
* Fixed error in gemspec
* Now rspec is launched after rubocop.
* Dgit binary now takes a `-f` flag to indicates folder
* It is now possible to deletes joins and analyses from a dgit folder
* The `clone` commands has been renamed `clones` for consistency sake

### Version 2.0.1
* Removed `errors`command, merged with subcommands of `sources`
* Added a lot of documentation
* Now the `init` command creates the directory for plugins and skips creating already existing folders
* Fixed plugins not shipped with the gem
* Removed useless dependency on `mongo`

## Version 2.0.0 (Beardfish)
* huge refactoring of the code
* now addons are lazy loaded
* `require_addons` to include addons in analyses and joins
* addons are now accessible using a method with the name of the addon inside an analysis or a join
* improved command line: now uses the GLI library
* addition of run modes: `:run`, `:rerun` and `:clean`
* more detailed journaling

## Version 1.0.0 (Anchovy)
* initial version
