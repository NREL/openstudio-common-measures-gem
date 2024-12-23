

###### (Automatically generated documentation)

# SetSpaceInfiltrationPerExteriorArea

## Description
Set Space Infiltration Design Flow Rate per exterior area for the entire building.

## Modeler Description
Replace this text with an explanation for the energy modeler specifically.  It should explain how the measure is modeled, including any requirements about how the baseline model must be set up, major assumptions, citations of references to applicable modeling resources, etc.  The energy modeler should be able to read this description and understand what changes the measure is making to the model and why these changes are being made.  Because the Modeler Description is written for an expert audience, using common abbreviations for brevity is good practice.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Flow per Exterior Surface Area.

**Name:** flow_per_area,
**Type:** Double,
**Units:** CFM/ft^2,
**Required:** true,
**Model Dependent:** false




### Exterior surfaces to include

**Name:** ext_surf_cat,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false


**Choice Display Names** ["ExteriorArea", "ExteriorWallArea"]



### Interpret Flow Rate as seen at 50 Pascal Pressure Difference
Set to true if the flow per exterior surface entered represents the flow rate during blower door test with 50 Pascal pressure difference. When set to false the input value will be passed directly to the energy model.
**Name:** input_value_at_50_pa,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false







