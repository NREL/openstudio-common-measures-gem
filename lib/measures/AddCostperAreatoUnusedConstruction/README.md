

###### (Automatically generated documentation)

# Add Cost per Area to Unused Construction

## Description
This measure is the same as 'Add Cost per Area to Construction' except that it only offers constructions that are not used on any surfaces in the baseline construction.

## Modeler Description
The use case for this is a construction that is not used in the baseline but will be used after other measures are run. For example adding overhangs to the Building.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Choose a Construction to Add Costs to

**Name:** construction,
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

### Material and Installation Costs for Construction per Area Used

**Name:** material_cost_ip,
**Type:** Double,
**Units:** $/ft^2,
**Required:** true,
**Model Dependent:** false

### Demolition Costs for Construction per Area Used

**Name:** demolition_cost_ip,
**Type:** Double,
**Units:** $/ft^2,
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

### O & M Costs for Construction per Area Used

**Name:** om_cost_ip,
**Type:** Double,
**Units:** $/ft^2,
**Required:** true,
**Model Dependent:** false

### O & M Frequency

**Name:** om_frequency,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false




