# OpenStudio Common Measures Gem

## Version 0.4.0

* Support Ruby ~> 2.7
* Support for OpenStudio 3.2 (upgrade to extension gem 0.4.2 and standards gem 0.2.13)
* Add EV measure load files
* Update copyrights
* Fixed [#36]( https://github.com/NREL/openstudio-common-measures-gem/issues/36 ), update generic QAQC to use the extension gem
* Fixed [#52]( https://github.com/NREL/openstudio-common-measures-gem/issues/52 ), Bump envelope and internal load min version
* Fixed [#55]( https://github.com/NREL/openstudio-common-measures-gem/issues/55 ), ChangeBuildingLocation Error: Comparison of String with 0 failed 
* Fixed [#56]( https://github.com/NREL/openstudio-common-measures-gem/pull/56 ), Convert `args['set_year']` to integer
* Fixed [#63]( https://github.com/NREL/openstudio-common-measures-gem/issues/63 ), Issue with OpenStudio Results fenestration calculations
* Fixed [#65]( https://github.com/NREL/openstudio-common-measures-gem/issues/65 ), Tariff Selection-Flat measure needs to be updated for newer E+ versions
* Fixed [#68]( https://github.com/NREL/openstudio-common-measures-gem/issues/68 ), envelope_and_internal_load_breakdown syntax error
* Fixed [#64]( https://github.com/NREL/openstudio-common-measures-gem/pull/64 ), Fix to area reporting of sub-surfaces

## Version 0.3.2

* Bump openstudio-extension-gem version to 0.3.2 to support updated workflow-gem

## Version 0.3.1

* Removes the following from lib/measures and moves them to the OpenStudio-ee-gem:
    * AddDaylightSensors
    * EnableDemandControlledVentilation
    * EnableEconomizerControl
    * IncreaseInsulationRValueForExteriorWalls
    * IncreaseInsulationRValueForExteriorWallsByPercentage
    * IncreaseInsulationRValueForRoofs
    * IncreaseInsulationRValueForRoofsByPercentage
    * ReduceElectricEquipmentLoadsByPercentage
    * ReduceLightingLoadsByPercentage
    * ReduceSpaceInfiltrationByPercentage
    * ReduceVentilationByPercentage
    * create_variable_speed_rtu

## Version 0.3.0

* Support for OpenStudio 3.1 (upgrade to extension gem 0.3.1)

## Version 0.2.1

* Removes the following from lib/measures and moves them to the OpenStudio-calibration-gem:
    * AddDaylightSensors
    * EnableDemandControlledVentilation
    * EnableEconomizerControl
    * ImproveFanBeltEfficiency
    * ImproveMotorEfficiency
    * IncreaseInsulationRValueForExteriorWalls
    * IncreaseInsulationRValueForRoofs
    * ReduceElectricEquipmentLoadsByPercentage
    * ReduceLightingLoadsByPercentage
    * ReduceSpaceInfiltrationByPercentage
    * ReduceVentilationByPercentage
    * create_variable_speed_rtu
    * radiant_slab_with_doas
* Updates the following in lib/measures:
    * ChangeBuildingLocation
    * ExportScheduleCSV
    * ImportEnvelopeAndInternalLoadsFromIdf
    * MeterFlodPlot
    * ReportModelChanges
    * RunPeriodMultiple
    * ServerDirectoryCleanup
    * UnmetLoadHoursTroubleshooting
    * Ventilation QAQC
    * ZoneReport
    * envelope_and_internal_load_breakdown
    * example_report
    * gem_env_report
    * generic_qaqc
    * hvac_psychrometric_chart
    * inject_idf_objects
    * openstudio_results
    * set_run_period
* Adds the following to lib/measures:
    * add_ems_to_control_ev_charging
    * add_ev_load
    * view_data
    * view_model
* Upgrade Bundler to 2.1.0
* Upgrade openstudio-extension to 0.2.3

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
