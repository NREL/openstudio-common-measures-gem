

###### (Automatically generated documentation)

# Add Cost per Area to Construction

## Description
This measure will create life cycle cost objects associated with the selected construction. You can set a material and installation cost, demolition cost, and O&M costs. Optionally existing cost objects already associated with building can be deleted. This measure will not affect energy use of the building.

## Modeler Description
In addition to the inputs for the cost values, a number of other inputs are exposed to specify when the cost first occurs and at what frequency it occurs in the future. This measure is intended to be used as an 'Always Run' measure to apply costs to the baseline simulation before any design alternatives manipulate it.

For baseline costs, 'Years Until Costs Start' indicates the year that the capital costs first occur. For new construction this will be typically be 0 and 'Demolition Costs Occur During Initial Construction' will be 'false'. For a retrofit 'Years Until Costs Start' is between 0 and the 'Expected Life' of the object, while 'Demolition Costs Occur During Initial Construction' is true.  O&M cost and frequency can be whatever is appropriate for the component.

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




