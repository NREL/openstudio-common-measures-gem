

###### (Automatically generated documentation)

# Add Zone Mixing Object

## Description
This adds a zone mixing object with a few inputs exposed, including source zone. You can add multiple copies of this to the workflow as needed.

## Modeler Description
Currently this is just setup for design level calculation method, but it could be extended as needed..

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Zone with Exhaust

**Name:** zone_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Schedule Name for Zone Mixing

**Name:** schedule_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Design Level for Zone Mixing

**Name:** design_level,
**Type:** Double,
**Units:** cfm,
**Required:** true,
**Model Dependent:** false

### Source Zone for Zone Mixing

**Name:** source_zone_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




