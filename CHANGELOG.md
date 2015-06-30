# Changelog of Diggit

### Version 2.0.1
* Added a lot of documentation
* Now the `init` command creates the directory for plugins and skips creating already existing folders
* RuboCop is now launched by the default rake task
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
