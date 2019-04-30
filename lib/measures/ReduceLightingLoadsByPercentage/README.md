

###### (Automatically generated documentation)

# Reduce Lighting Loads by Percentage

## Description
The lighting system in this building uses more power per area than is required with the latest lighting technologies.  Replace the lighting system with a newer, more efficient lighting technology.  Newer technologies provide the same amount of light but use less energy in the process.

## Modeler Description
This measure supports models which have a mixture of lighting assigned to spaces and space types.  The lighting may be specified as individual luminaires, lighting equipment level, lighting power per area, or lighting power per person. Loop through all lights and luminaires in the specified space type or the entire building. Clone the definition if it is shared by other lights, rename and adjust the power based on the specified percentage. Link the new definition to the existing lights or luminaire instance.  Adjust the power for lighting equipment assigned to a particular space but only if that space is part of the selected space type by  looping through the objects first in space types and then in spaces, but again only for spaces that are in the specified space type (unless the entire building has been chosen).  Material and installation cost increases will be applied to all costs related to both the definition and instance of the lighting object.  If this measure includes baseline costs, then the material and installation costs of the lighting objects in the baseline model will be summed together and added as a capital cost on the building object.

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

### Lighting Power Reduction

**Name:** lighting_power_reduction_percent,
**Type:** Double,
**Units:** %,
**Required:** true,
**Model Dependent:** false

### Increase in Material and Installation Cost for Lighting per Floor Area

**Name:** material_and_installation_cost,
**Type:** Double,
**Units:** %,
**Required:** true,
**Model Dependent:** false

### Increase in Demolition Costs for Lighting per Floor Area

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

### Increase O & M Costs for Lighting per Floor Area

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




