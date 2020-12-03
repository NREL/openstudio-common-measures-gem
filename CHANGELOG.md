# OpenStudio Common Measures Gem

## Version 0.3.0

* Support for OpenStudio 3.1 (upgrade to extension gem 0.3.1)

## Version 0.2.0

* Support for OpenStudio 3.0
    * Upgrade Bundler to 2.1.x
    * Restrict to Ruby ~> 2.5.0   
    * Removed simplecov forked dependency 
* Upgraded openstudio-extension to 0.2.2
    * Updated measure tester to 0.2.0 (removes need for github gem in downstream projects)
* Upgraded openstudio-standards to 0.2.11
* Exclude measure tests from being released with the gem (reduces the size of the installed gem significantly)

## Version 0.1.2

* Run update measures command to generate new measure.xml files
 
## Version 0.1.1

* Add in common measures from the to be deprecated private OpenStudio-Measures repository. 
* Update copyrights
* Include updated PMV measure

## Version 0.1.0 

* Initial release of the common measures used for OpenStudio
