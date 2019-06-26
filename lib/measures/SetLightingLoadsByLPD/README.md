

###### (Automatically generated documentation)

# Set Lighting Loads by LPD

## Description
Set the lighting power density (W/ft^2) in the to a specified value for all spaces that have lights. This can be applied to the entire building or a specific space type. Cost can be added per floor area

## Modeler Description
Delete all of the existing lighting in the model. Add lights with the user defined lighting power density to all spaces that initially had lights, using the schedule from the original lights. If multiple lights existed the schedule will be pulled from the one with the highest lighting power density value. Demolition costs from lights and luminaires removed by this measure can be included in the analysis.

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

**Name:** lpd,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Add lights to all spaces included in floor area, including spaces that did not originally include lights

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







