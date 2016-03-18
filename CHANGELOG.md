# Changelog of Diggit

### Version 2.1.1
* Fixed small bugs in the CLI
* Fixed source error not showing up in case of clone error

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
