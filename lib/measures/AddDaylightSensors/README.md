

###### (Automatically generated documentation)

# Add Daylight Sensor at the Center of Spaces with a Specified Space Type Assigned

## Description
This measure will add daylighting controls to spaces that that have space types assigned with names containing the string in the argument. You can also add a cost per space for sensors added to the model.

## Modeler Description
Make an array of the spaces that meet the criteria. Locate the sensor x and y values by averaging the min and max X and Y values from floor surfaces in the space. If a space already has a daylighting control, do not add a new one and leave the original in place. Warn the user if the space isn't assigned to a thermal zone, or if the space doesn't have any translucent surfaces. Note that the cost is added to the space not the sensor. If the sensor is removed at a later date, the cost will remain.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Add Daylight Sensors to Spaces of This Space Type

**Name:** space_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daylighting Setpoint

**Name:** setpoint,
**Type:** Double,
**Units:** fc,
**Required:** true,
**Model Dependent:** false

### Daylighting Control Type

**Name:** control_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daylighting Minimum Input Power Fraction
min = 0 max = 0.6
**Name:** min_power_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daylighting Minimum Light Output Fraction
min = 0 max = 0.6
**Name:** min_light_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Fraction of zone controlled by daylight sensors

**Name:** fraction_zone_controlled,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Sensor Height

**Name:** height,
**Type:** Double,
**Units:** inches,
**Required:** true,
**Model Dependent:** false

### Material and Installation Costs per Space for Daylight Sensor

**Name:** material_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### Demolition Costs per Space for Daylight Sensor

**Name:** demolition_cost,
**Type:** Double,
**Units:** $,
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

### O & M Costs per Space for Daylight Sensor

**Name:** om_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### O & M Frequency

**Name:** om_frequency,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false




