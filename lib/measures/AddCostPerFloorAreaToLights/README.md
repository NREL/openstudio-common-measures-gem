

###### (Automatically generated documentation)

# Add Cost per FloorArea to Lights

## Description
This measure will create life cycle cost objects associated with lights. You can choose any light definition used in the model that has a watt/area power. You can set a material &amp; installation cost, demolition cost, and O&M costs. Optionally existing cost objects already associated with the selected light definition can be deleted. This measure will not affect energy use of the building.

## Modeler Description
This measure has a choice input populated with watt/area light definitions applied to  spaces in the model. It will add a number of life cycle cost objects and will associate them with the selected definition. In addition to the inputs for the cost values, a number of other inputs are exposed to specify when the cost first occurs and at what frequency it occurs in the future. This measure is intended to be used as an 'Always Run' measure to apply costs to objects that design alternatives will impact. This will add costs to the baseline model before any design alternatives manipulate it. As an example, if you plan adjust the performance and cost of lights by a percentage, you will want to use this to cost the baseline definition.

For baseline costs, 'Years Until Costs Start' indicates the year that the capital costs first occur. For new construction this will be typically be 0 and 'Demolition Costs Occur During Initial Construction' will be false. For a retrofit 'Years Until Costs Start' is between 0 and the 'Expected Life' of the object, while 'Demolition Costs Occur During Initial Construction' is true.  O&M cost and frequency can be whatever is appropriate for the component

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Choose a Watt per Area Lights Definition to Add Costs to

**Name:** lights_def,
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




