

###### (Automatically generated documentation)

# ReduceSpaceInfiltrationByPercentage

## Description


## Modeler Description


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

### Space Infiltration Power Reduction (%).

**Name:** space_infiltration_reduction_percent,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Constant Coefficient.

**Name:** constant_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Temperature Coefficient.

**Name:** temperature_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Wind Speed Coefficient.

**Name:** wind_speed_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Wind Speed Squared Coefficient.

**Name:** wind_speed_squared_coefficient,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Alter constant temperature and wind speed coefficients.
Setting this to false will result in infiltration objects that maintain the coefficients from the initial model. Setting this to true replaces the existing coefficients with the values entered for the coefficient arguments in this measure.
**Name:** alter_coef,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Increase in Material and Installation Costs for Building per Affected Floor Area ($/ft^2).

**Name:** material_and_installation_cost,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### O & M Costs for Construction per Affected Floor Area ($/ft^2).

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




