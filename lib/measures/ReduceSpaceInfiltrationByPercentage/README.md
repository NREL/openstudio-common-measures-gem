

###### (Automatically generated documentation)

# ReduceSpaceInfiltrationByPercentage

## Description
This measure will reduce space infiltration rates by the requested percentage. A cost per square foot of building area can be added to the model.

## Modeler Description
This can be run across a space type or the entire building. Costs will be associated with the building. If infiltration objects are removed at a later date, the costs will remain.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Apply the Measure to a Specific Space Type or to the Entire Model.

**Name:** space_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Space Infiltration Power Reduction

**Name:** space_infiltration_reduction_percent,
**Type:** Double,
**Units:** %,
**Required:** true,
**Model Dependent:** false

### Constant Coefficient

**Name:** constant_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Temperature Coefficient

**Name:** temperature_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Wind Speed Coefficient

**Name:** wind_speed_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Wind Speed Squared Coefficient

**Name:** wind_speed_squared_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Alter constant temperature and wind speed coefficients.
Setting this to false will result in infiltration objects that maintain the coefficients from the initial model. Setting this to true replaces the existing coefficients with the values entered for the coefficient arguments in this measure
**Name:** alter_coef,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Increase in Material and Installation Costs for Building per Affected Floor Area

**Name:** material_and_installation_cost,
**Type:** Double,
**Units:** $/ft^2,
**Required:** true,
**Model Dependent:** false

### O & M Costs for Construction per Affected Floor Area

**Name:** om_cost,
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




