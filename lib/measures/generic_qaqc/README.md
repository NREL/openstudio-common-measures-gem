

###### (Automatically generated documentation)

# Generic QAQC

## Description
This measure extracts key simulation results and performs basic model QAQC checks. Each category of checks provides a description of the source of the check. In some cases the target standards and tollerances are adjustable.

## Modeler Description
Reads the model and sql file to pull out the necessary information and run the model checks.  The check results show up as warning messages in the measure's output on the PAT run tab.

## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### Target ASHRAE Standard
This used to set the target standard for most checks.
**Name:** template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### EUI Reasonableness (General)
Check model EUI against selected ASHRAE standard DOE prototype building.
**Name:** check_eui_reasonableness,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### EUI Reasonableness Tolerance

**Name:** check_eui_reasonableness_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### End Use by Category (General)
Check model consumption by end use against selected ASHRAE standard DOE prototype building.
**Name:** check_eui_by_end_use,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Use by Category Tolerance

**Name:** check_eui_by_end_use_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Mechanical System Part Load Efficiency (General)
Check 40% and 80% part load efficency against selected ASHRAE standard for the following compenent types: ChillerElectricEIR, CoilCoolingDXSingleSpeed, CoilCoolingDXTwoSpeed, CoilHeatingDXSingleSpeed. Checking EIR Function of Part Load Ratio curve for chiller and EIR Function of Flow Fraction for DX coils.
**Name:** check_mech_sys_part_load_eff,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Mechanical System Part Load Efficiency Tolerance

**Name:** check_mech_sys_part_load_eff_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Mechanical System Capacity (General)
Check HVAC capacity against ASHRAE rules of thumb for chiller max flow rate, air loop max flow rate, air loop cooling capciaty, and zone heating capcaity. Zone heating check will skip thermal zones without any exterior exposure, and thermal zones that are not conditioned.
**Name:** check_mech_sys_capacity,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Simultaneous Heating and Cooling (General)
Check for simultaneous heating and cooling by looping through all Single Duct VAV Reheat Air Terminals and analyzing hourly data when there is a cooling load. 
**Name:** check_simultaneous_heating_and_cooling,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Simultaneous Heating and Cooling Max Tolerance

**Name:** check_simultaneous_heating_and_cooling_max_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Internal Loads (Baseline)
Check LPD, ventilation rates, occupant density, plug loads, and equipment loads against selected ASHRAE standard DOE Prototype buildings.
**Name:** check_internal_loads,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Internal Loads Tolerance

**Name:** check_internal_loads_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Schedules (Baseline)
Check schedules for lighting, ventilation, occupant density, plug loads, and equipment based on DOE reference building schedules in terms of full load hours per year.
**Name:** check_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Schedules Tolerance

**Name:** check_schedules_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Envelope R-Value (Baseline)
Check envelope against selected ASHRAE standard. Roof reflectance of 55%, wall relfectance of 30%.
**Name:** check_envelope_conductance,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Envelope R-Value Tolerance

**Name:** check_envelope_conductance_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Domestic Hot Water (Baseline)
Check against the 2011 ASHRAE Handbook - HVAC Applications, Table 7 section 50.14.
**Name:** check_domestic_hot_water,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Domestic Hot Water Tolerance

**Name:** check_domestic_hot_water_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Mechanical System Efficiency (Baseline)
Check against selected ASHRAE standard for the following component types: ChillerElectricEIR, CoilCoolingDXSingleSpeed, CoilCoolingDXTwoSpeed, CoilHeatingDXSingleSpeed, BoilerHotWater, FanConstantVolume, FanVariableVolume, PumpConstantSpeed, PumpVariableSpeed.
**Name:** check_mech_sys_efficiency,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Mechanical System Efficiency Tolerance

**Name:** check_mech_sys_efficiency_tol,
**Type:** Double,
**Units:** fraction,
**Required:** true,
**Model Dependent:** false

### Baseline Mechanical System Type (Baseline)
Check against ASHRAE 90.1. Infers the baseline system type based on the equipment serving the zone and their heating/cooling fuels. Only does a high-level inference; does not look for the presence/absence of required controls, etc.
**Name:** check_mech_sys_type,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Supply and Zone Air Temperature (Baseline)
Check if fans modeled to ASHRAE 90.1 2013 Section G3.1.2.9 requirements. Compare the supply air temperature for each thermal zone against the thermostat setpoints. Throw flag if temperature difference excedes threshold of 20.0F plus the selected tolerance.
**Name:** check_supply_air_and_thermostat_temp_difference,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Supply and Zone Air Temperature Tolerance

**Name:** check_supply_air_and_thermostat_temp_difference_tol,
**Type:** Double,
**Units:** F,
**Required:** true,
**Model Dependent:** false

### Use Upstream Argument Values
When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.
**Name:** use_upstream_args,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false






## Screenshot of Sample Summary Table
![Summary Table](./docs/generic_qaqc_summary.jpg?raw=true)

## Screenshot of Sample Detailed Table  
![Detailed Table](./docs/generic_qaqc_detailed.jpg?raw=true)
