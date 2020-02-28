

###### (Automatically generated documentation)

# Set Electric Equipment loads by EPD

## Description
Set the electric equipment power density (W/ft^2) in the to a specified value for all spaces that have electric equipment. This can be applied to the entire building or a specific space type. Cost can be added per floor area

## Modeler Description
Delete all of the existing electric equipment in the model. Add electric equipment with the user defined electric equipment power density to all spaces that initially had electric equipment, using the schedule from the original electric equipment. If multiple electric equipment existed the schedule will be pulled from the one with the highest electric equipment power density value. Demolition costs from electric equipment removed by this measure can be included in the analysis.

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


**Choice Display Names** ["*Entire Building*"]



### Lighting Power Density (W/ft^2)

**Name:** epd,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Add electric equipment to all spaces included in floor area, including spaces that did not originally include electric equipment

**Name:** add_instance_all_spaces,
**Type:** Boolean,
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







