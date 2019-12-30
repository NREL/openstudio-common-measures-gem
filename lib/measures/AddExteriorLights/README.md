

###### (Automatically generated documentation)

# Add Exterior Lights

## Description
Add exterior lighting to the building.  This may be in addition to or in place of existing exterior lighting.  This lighting will run from sunset to sunrise. Optionally you can add costs to the lights.

## Modeler Description
This measure has an argument for design power (W) and a name for the new exterior lights, as well as an option to remove any existing exterior lights. It will add an ExteriorLightsDefinition object and associate it with an Exterior Lights object. The lights will have a schedule that always has fractional value of 1 but the object will be controlled by an astronomical clock. Cost is added to the building and not the lights. If the lights are removed at a later date, the cost will remain.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Exterior Lighting Design Power

**Name:** ext_lighting_level,
**Type:** Double,
**Units:** W,
**Required:** true,
**Model Dependent:** false

### End-Use SubCategory

**Name:** end_use_subcategory,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Existing Exterior Lights in the Project

**Name:** remove_existing_ext_lights,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Material and Installation Costs for Exterior Lights

**Name:** material_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### Demolition Costs for Exterior Lights

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

### O & M Costs for Exterior Lights

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




