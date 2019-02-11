

###### (Automatically generated documentation)

# Set Lighting Loads by LPD

## Description


## Modeler Description


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Apply the Measure to a Specific Space Type or to the Entire Model

**Name:** space_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Lighting Power Density (W/ft^2)

**Name:** lpd,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Material and Installation Costs for Lights per Floor Area ($/ft^2).

**Name:** material_cost,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Demolition Costs for Lights per Floor Area ($/ft^2).

**Name:** demolition_cost,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Years Until Costs Start (whole years).

**Name:** years_until_costs_start,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Demolition Costs Occur During Initial Construction?

**Name:** demo_cost_initial_const,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Expected Life (whole years).

**Name:** expected_life,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### O & M Costs for Lights per Floor Area ($/ft^2).

**Name:** om_cost,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### O & M Frequency (whole years).

**Name:** om_frequency,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false




