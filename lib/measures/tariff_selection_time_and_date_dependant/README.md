

###### (Automatically generated documentation)

# Tariff Selection-Time and Date Dependant

## Description
This measure sets flat rates for gas, water, district heating, and district cooling but has on seasonal and off peak rates for electricity. It exposes inputs for the time of day and day of year where peak rates should be applied.

## Modeler Description
Will add the necessary UtilityCost objects and associated schedule into the model.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Demand Window Length.

**Name:** demand_window_length,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Month Summer Begins
1-12
**Name:** summer_start_month,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Day Summer Begins
1-31
**Name:** summer_start_day,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Month Summer Ends
1-12
**Name:** summer_end_month,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Day Summer Ends
1-31
**Name:** summer_end_day,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Hour Peak Begins
1-24
**Name:** peak_start_hour,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Hour Peak Ends
1-24
**Name:** peak_end_hour,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electric Rate Summer On-Peak

**Name:** elec_rate_sum_peak,
**Type:** Double,
**Units:** $/kWh,
**Required:** true,
**Model Dependent:** false

### Electric Rate Summer Off-Peak

**Name:** elec_rate_sum_nonpeak,
**Type:** Double,
**Units:** $/kWh,
**Required:** true,
**Model Dependent:** false

### Electric Rate Not Summer On-Peak

**Name:** elec_rate_nonsum_peak,
**Type:** Double,
**Units:** $/kWh,
**Required:** true,
**Model Dependent:** false

### Electric Rate Not Summer Off-Peak

**Name:** elec_rate_nonsum_nonpeak,
**Type:** Double,
**Units:** $/kWh,
**Required:** true,
**Model Dependent:** false

### Electric Peak Demand Charge Summer

**Name:** elec_demand_sum,
**Type:** Double,
**Units:** $/kW,
**Required:** true,
**Model Dependent:** false

### Electric Peak Demand Charge Not Summer

**Name:** elec_demand_nonsum,
**Type:** Double,
**Units:** $/kW,
**Required:** true,
**Model Dependent:** false

### Gas Rate

**Name:** gas_rate,
**Type:** Double,
**Units:** $/therm,
**Required:** true,
**Model Dependent:** false

### Water Rate

**Name:** water_rate,
**Type:** Double,
**Units:** $/gal,
**Required:** true,
**Model Dependent:** false

### District Heating Rate

**Name:** disthtg_rate,
**Type:** Double,
**Units:** $/therm,
**Required:** true,
**Model Dependent:** false

### District Cooling Rate

**Name:** distclg_rate,
**Type:** Double,
**Units:** $/therm,
**Required:** true,
**Model Dependent:** false




