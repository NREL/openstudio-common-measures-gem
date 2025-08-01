# OpenStudio Common Measures Gem

## Version 0.12.2
- Update dependency: `openstudio-extension` upgraded from `~> 0.9.1` to `~> 0.9.2`.
- Regenerate all `measure.xml` files for measures (79 files) to update version IDs, timestamps, and checksums.
- Add or update copyright/license header in:
  - `lib/measures/simulation_control/measure.rb`
  - `lib/measures/output_table_summary_reports/measure.rb`
  - Associated test files for these measures.
- Add new `LICENSE.md` for `simulation_control` measure (untracked).
- Minor whitespace or formatting changes in some HTML report templates (5 files).

## Version 0.12.1
- Fixed [#203]( https://github.com/NREL/openstudio-common-measures-gem/pull/203 ), Update copyright year in LICENSE.md files to 2025 for all measures

## Version 0.12.0
- Support for OpenStudio 3.10 (upgrade to standards gem 0.8.2, extension gem 0.9.1)
- todo add log after finalize bug fixes for this release
- Fixed [#191]( https://github.com/NREL/openstudio-common-measures-gem/pull/191 ), AddRooftopPV: name objects + set explicit critical defaults + write ratedElectricPowerOutput
- Fixed [#192]( https://github.com/NREL/openstudio-common-measures-gem/pull/192 ), ZoneReport fixes for 3.9.0
- Fixed [#195]( https://github.com/NREL/openstudio-common-measures-gem/pull/195 ), fix openstudio results rendering
- Fixed [#196]( https://github.com/NREL/openstudio-common-measures-gem/pull/196 ), add measure for Output Table Summary Reports
- Fixed [#198]( https://github.com/NREL/openstudio-common-measures-gem/pull/198 ), test on CI and then investigate bug fixes to add for release
- Fixed [#199]( https://github.com/NREL/openstudio-common-measures-gem/pull/199 ), 3.10.0 prep
- Fixed [#200]( https://github.com/NREL/openstudio-common-measures-gem/pull/200 ), Output table summary reports
- Fixed [#201]( https://github.com/NREL/openstudio-common-measures-gem/pull/201 ), Zone report 39 fix
- Fixed [#202]( https://github.com/NREL/openstudio-common-measures-gem/pull/202 ), AddRooftopPV: name objects + set explicit critical defaults + write r…

## Version 0.11.1
* Update dependencies for 3.9

## Version 0.11.0
- Support for OpenStudio 3.9 (upgrade to standards gem 0.7.0, extension gem 0.8.1)
- Fixed [#160]( https://github.com/NREL/openstudio-common-measures-gem/issues/160 ), ServerDirectoryCleanup test doesn't test whether the measure does what it's supposed to do
- Fixed [#174]( https://github.com/NREL/openstudio-common-measures-gem/issues/174 ), ChangeBuildingLocation CSV encoding
- Fixed [#133]( https://github.com/NREL/openstudio-common-measures-gem/pull/133 ), add measure for SimulationControl
- Fixed [#134]( https://github.com/NREL/openstudio-common-measures-gem/pull/134 ), add customization for revit to openstudio results
- Fixed [#156]( https://github.com/NREL/openstudio-common-measures-gem/pull/156 ), view_model / view_data: improve maintainability by using separate jS files + add new geometry diagnostics feature
- Fixed [#166]( https://github.com/NREL/openstudio-common-measures-gem/pull/166 ), fix not applicable message in AddOutputDiagnostics
- Fixed [#170]( https://github.com/NREL/openstudio-common-measures-gem/pull/170 ), add input_value_at_50_pa argument to set_space_infiltration_per_exterior_area
- Fixed [#172]( https://github.com/NREL/openstudio-common-measures-gem/pull/172 ), Os results enhancements
- Fixed [#173]( https://github.com/NREL/openstudio-common-measures-gem/pull/173 ), ChangeBuildingLocation EPW file encoding
- Fixed [#182]( https://github.com/NREL/openstudio-common-measures-gem/pull/182 ), View model geometry diag and split js

## Version 0.10.0
- Support for OpenStudio 3.8 (upgrade to standards gem 0.6.0, extension gem 0.8.0)
- Support Ruby 3.2.2

## Version 0.9.0

- Support for OpenStudio 3.7 (upgrade to standards gem 0.5.0, extension gem 0.7)
- Fixed [#140]( https://github.com/NREL/openstudio-common-measures-gem/issues/140 ), XcelEDAReportingandQAQC failing on 3.6.0 and CI issue with 3.5.1 measure

## Version 0.8.0

- Support for OpenStudio 3.6 (upgrade to standards gem 0.4.0, extension gem 0.6.1)
- Fixed [#119]( https://github.com/NREL/openstudio-common-measures-gem/pull/119 ), adding XcelEDAReportingandQAQC measure
- Fixed [#124]( https://github.com/NREL/openstudio-common-measures-gem/pull/124 ), Test using OpenStudio 3.5.1-rc1
- Fixed [#125]( https://github.com/NREL/openstudio-common-measures-gem/pull/125 ), Update remove orphan objects measure
- Fixed [#126]( https://github.com/NREL/openstudio-common-measures-gem/pull/126 ), backport OSA #585
- Fixed [#127]( https://github.com/NREL/openstudio-common-measures-gem/pull/127 ), Adds replace model measure
- Fixed [#128]( https://github.com/NREL/openstudio-common-measures-gem/pull/128 ), adding measure that exports output variables to csv
- Fixed [#129]( https://github.com/NREL/openstudio-common-measures-gem/pull/129 ), Use CI to test against 3.6.0-alpha
- Fixed [#130]( https://github.com/NREL/openstudio-common-measures-gem/pull/130 ), New AddThermalComfortModelTypes measure
- Fixed [#131]( https://github.com/NREL/openstudio-common-measures-gem/pull/131 ), add measure for ShadowCalculation
- Fixed [#141]( https://github.com/NREL/openstudio-common-measures-gem/pull/141 ), 3.6.0 rc1 (CI test not ready to merge yet)
- Fixed [#142]( https://github.com/NREL/openstudio-common-measures-gem/pull/142 ), fix other fuel queries in reporting qaqc measures
- Fixed [#143]( https://github.com/NREL/openstudio-common-measures-gem/pull/143 ), test 3.6.1-rc1
- Fixed [#144]( https://github.com/NREL/openstudio-common-measures-gem/pull/144 ), For all 14 tests to pass on generic qaqc 6 resource files had to be l…
- Fixed [#146]( https://github.com/NREL/openstudio-common-measures-gem/pull/146 ), Xcel reporting into remove qaqc resrouces
- Fixed [#147]( https://github.com/NREL/openstudio-common-measures-gem/pull/147 ), Dfg temp gem env ci test
- Fixed [#148]( https://github.com/NREL/openstudio-common-measures-gem/pull/148 ), Xcel reporting
- Fixed [#149]( https://github.com/NREL/openstudio-common-measures-gem/pull/149 ), Add/shadow calculation
- Fixed [#150]( https://github.com/NREL/openstudio-common-measures-gem/pull/150 ), Add thermal comfort model types
- Fixed [#151]( https://github.com/NREL/openstudio-common-measures-gem/pull/151 ), adding measure that exports output variables to csv
- Fixed [#153]( https://github.com/NREL/openstudio-common-measures-gem/pull/153 ), I'm testing a bunch of PR's in CI in a combined branch
- Fixed [#154]( https://github.com/NREL/openstudio-common-measures-gem/pull/154 ), backport OSA #585

## Version 0.7.0

- Support for OpenStudio 3.5 (upgrade to standards gem 0.3.0, extension gem 0.6.0)

## Version 0.6.1

- Fixed [#107]( https://github.com/NREL/openstudio-common-measures-gem/pull/107 ), Added natural gas emissions calculations
- Fixed [#109]( https://github.com/NREL/openstudio-common-measures-gem/pull/109 ), changed variable names to include Electricity and removed "_Var"

## Version 0.6.0

* Support for OpenStudio 3.4 (upgrade to standards gem 0.2.16, no extension gem upgrade)
* Fixed [#53]( https://github.com/NREL/openstudio-common-measures-gem/issues/53 ), View Model and View Data measures are missing rendering color for Foundation
* Fixed [#90]( https://github.com/NREL/openstudio-common-measures-gem/pull/90 ), Adjacency Checker
* Fixed [#93]( https://github.com/NREL/openstudio-common-measures-gem/pull/93 ), Qaqc issue 79
* Fixed [#94]( https://github.com/NREL/openstudio-common-measures-gem/pull/94 ), remove unique output variable names
* Fixed [#95]( https://github.com/NREL/openstudio-common-measures-gem/pull/95 ), Qaqc issue 79
* Fixed [#96]( https://github.com/NREL/openstudio-common-measures-gem/pull/96 ), Add additional argument to add_ev_load measure
* Fixed [#97]( https://github.com/NREL/openstudio-common-measures-gem/pull/97 ), Add color for Foundation boundary condition

## Version 0.5.0

* Support for OpenStudio 3.3 (upgrade to extension gem 0.5.1 and standards gem 0.2.15)
* Fixed [#80]( https://github.com/NREL/openstudio-common-measures-gem/pull/80 ), Custom emissions reporting measure
* Fixed [#82]( https://github.com/NREL/openstudio-common-measures-gem/pull/82 ), adding compatibility matrix and contribution policy
* Fixed [#84]( https://github.com/NREL/openstudio-common-measures-gem/pull/84 ), Add latest CO2 CSVs from LBNL
* Adding surface search to view model and view data commited by macumber

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
