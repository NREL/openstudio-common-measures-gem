

###### (Automatically generated documentation)

# Replace Exterior Window Constructions with a Different Construction from the Model.

## Description


## Modeler Description


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Pick a Window Construction From the Model to Replace Existing Window Constructions.

**Name:** construction,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Change Fixed Windows?

**Name:** change_fixed_windows,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Change Operable Windows?

**Name:** change_operable_windows,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Existing Costs?

**Name:** remove_costs,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Material and Installation Costs for Construction per Area Used ($/ft^2).

**Name:** material_cost_ip,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Demolition Costs for Construction per Area Used ($/ft^2).

**Name:** demolition_cost_ip,
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

### O & M Costs for Construction per Area Used ($/ft^2).

**Name:** om_cost_ip,
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




