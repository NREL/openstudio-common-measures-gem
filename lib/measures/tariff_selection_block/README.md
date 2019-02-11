

###### (Automatically generated documentation)

#  Tariff Selection-Block

## Description
This measure sets block rates for electricity, and flat rates for gas, water, district heating, and district cooling.

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

### Electric Block Rate Ceiling Values
Comma separated block ceilings.
**Name:** elec_block_values,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electric Block Rate Costs
Comma separated block rate values. Should have same number of rates as blocks.
**Name:** elec_block_costs,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electric Rate for Remaining
Rate for Electricity above last block level.
**Name:** elec_remaining_rate,
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




