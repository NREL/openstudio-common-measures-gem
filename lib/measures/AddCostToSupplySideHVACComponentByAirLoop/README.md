

###### (Automatically generated documentation)

# Add Cost to Supply Side HVAC Component by Air Loop

## Description
This will add cost to HVAC components of a specified type in the selected air loop(s). It can run on all air loops or a single air loop. This measures only adds cost and doesn't alter equipment performance

## Modeler Description
Currently this measure supports the following objects: CoilCoolingDXSingleSpeed, CoilCoolingDXTwoSpeed, CoilHeatingDXSingleSpeed, CoilHeatingElectric, CoilHeatingGas, CoilHeatingWaterBaseboard, FanConstantVolume, FanOnOff, FanVariableVolume, PumpConstantSpeed, PumpVariableSpeed, CoilCoolingWater, CoilHeatingWater.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select an HVAC Air Loop Supply Side Component Type

**Name:** hvac_comp_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose an Air Loop to Add Costs to

**Name:** object,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Existing Costs

**Name:** remove_costs,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Material and Installation Costs per Component

**Name:** material_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### Demolition Costs per Component

**Name:** demolition_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### Years Until Costs Start

**Name:** years_until_costs_start,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false

### Demolition Costs Occur During Initial Construction

**Name:** demo_cost_initial_const,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Expected Life

**Name:** expected_life,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false

### O & M Costs per Component

**Name:** om_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### O & M Frequency

**Name:** om_frequency,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false




