

###### (Automatically generated documentation)

# Tariff Selection-Flat

## Description
This measure sets flat rates for electricity, gas, water, district heating, and district cooling.

## Modeler Description
Will add the necessary UtilityCost objects into the model.

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

### Electric Rate

**Name:** elec_rate,
**Type:** Double,
**Units:** $/kWh,
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




