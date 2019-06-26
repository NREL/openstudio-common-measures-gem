

###### (Automatically generated documentation)

# Reduce Electric Equipment Loads by Percentage

## Description
Reduce Electric Equipment Loads by Percentage</display_name>
  <description>Reduce electric equipment loads. This will affect equipment that have a, power, power per area (LPD), or power per person value. This can be applied to the entire building or a specific space type. A positive percentage represents an increase electric equipment power, while a negative percentage can be used for an increase in electric equipment power.

## Modeler Description
Loop through all electric equipment objects in the specified space type or the entire building. Clone the definition if it has not already been cloned, rename and adjust the power based on the specified percentage. Link the new definition to the existing electric equipment instance. Loop through objects first in space types and then in spaces, but only for spaces that are in the specified space type, unless entire building has been chosen.

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

### Electric Equipment Power Reduction

**Name:** elecequip_power_reduction_percent,
**Type:** Double,
**Units:** %,
**Required:** true,
**Model Dependent:** false

### Increase in Material and Installation Cost for Electric Equipment per Floor Area

**Name:** material_and_installation_cost,
**Type:** Double,
**Units:** %,
**Required:** true,
**Model Dependent:** false

### Increase in Demolition Costs for Electric Equipment per Floor Area

**Name:** demolition_cost,
**Type:** Double,
**Units:** %,
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

### Increase O & M Costs for Electric Equipment per Floor Area

**Name:** om_cost,
**Type:** Double,
**Units:** %,
**Required:** true,
**Model Dependent:** false

### O & M Frequency

**Name:** om_frequency,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false




