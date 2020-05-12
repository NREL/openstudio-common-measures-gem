

###### (Automatically generated documentation)

# Radiant Slab with DOAS

## Description
Adds a radiant slab with DOAS ventilation system to the model.

## Modeler Description
This measure adds either a radiant floor slab or radiant ceiling slab with dedicated outdoor air system to conditioned zones in the model.
Radiant systems are comfortable with wider zone air temperature range. Use the CBE Thermal Comfort Tool or other method to set thermostat setpoint temperatures.
This measure optionally removes existing HVAC systems (recommended).
This measure is dependent on an ASHRAE climate zone to set insulation and design supply temperature levels, so make sure this is set in the site parameters of the model.
Plant equipment options are an Air Source Heat Pump or a Boiler for hot water, and an Air Cooled Chiller or Water Cooled Chiller for chilled water.
The Air Source Heat Pump object uses a user-defined plant component in EnergyPlus and may not be compatible with several reporting measures, including the *Enable Detailed Output for Each Node in a Loop* measure.
If Water Cooled Chiller is selected, the measure will add a condenser loop with a variable speed cooling tower, and optionally enable water-side economizing when wet bulb conditions allow.
By default, the slab system does not include carpet. Carpet greatly reduces the heat transfer capacity of the radiant system.  If carpet is preferred, a ceiling-type slab and no lockout are recommended to avoid unmet hours.
The measure includes several control parameters for radiant system operation. Use the defaults unless you have strong reasons to deviate from them.
This measure runs a sizing run to set equipment efficiency values, so it may take up to a few minutes to run.
This measure adds many EnergyManagementSystem objects to the model. **DO NOT** change design days after running this measure.  Adding additional HVAC measures after applying this measure may break the model.
Radiant systems are particularly limited in cooling capacity and the model may have many unmet hours as a result.
To reduce unmet hours, use an expanded comfort range as mentioned above, remove carpet, reduce internal loads, reduce solar and envelope gains during peak times, or disable the lockout.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Remove existing HVAC system (keeps service water heating and zone exhaust fans)

**Name:** remove_existing_hvac,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heating Plant Type

**Name:** heating_plant_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Cooling Plant Type

**Name:** cooling_plant_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Water-side economizer (water cooled chiller only)

**Name:** waterside_economizer,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Radiant System Type

**Name:** radiant_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Include carpet over the radiant slab
Only applicable in radiant floor systems. This will greatly reduce system effectiveness and controllability.
**Name:** include_carpet,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Control Strategy

**Name:** control_strategy,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Proportional Gain

**Name:** proportional_gain,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Minimum Operating Hours
Fractional Hours Allowed, e.g. 30 min = 0.5
**Name:** minimum_operation,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Switch Over Time
Minimum time limitation for when the system can switch between heating and cooling.  Fractional hours allowed, e.g. 30 min = 0.5.
**Name:** switch_over_time,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enable radiant lockout
Lockout the radiant system to avoid operating during peak hours.
**Name:** radiant_lockout,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Lockout Start Time
Decimal hour of when radiant lockout starts.  Fractional hours allowed, e.g. 30 min = 0.5.
**Name:** lockout_start_time,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Lockout End Time
Decimal hour of when radiant lockout ends.  Fractional hours allowed, e.g. 30 min = 0.5.
**Name:** lockout_end_time,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add output variables for radiant system

**Name:** add_output_variables,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Standards Template
Standards template to use for HVAC equipment efficiencies and controls.
**Name:** standards_template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




