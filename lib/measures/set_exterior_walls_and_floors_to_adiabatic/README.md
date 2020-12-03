

###### (Automatically generated documentation)

# Set Exterior Walls and Floors to Adiabatic

## Description


## Modeler Description


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Make Exterior Roof Surfaces Adiabatic

**Name:** ext_roofs,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make Exterior Exposed Floor Surfaces Adiabatic

**Name:** ext_floors,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make Ground Exposed Floor Surfaces Adiabatic

**Name:** ground_floors,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make North Facing Exterior Surfaces Adiabatic

**Name:** north_walls,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make South Facing Exterior Surfaces Adiabatic

**Name:** south_walls,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make East Facing Exterior Surfaces Adiabatic

**Name:** east_walls,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make West Facing Exterior Surfaces Adiabatic

**Name:** west_walls,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Adiabatic Inclusion List
Surfaces listed here will be changed to adiabatic boundary condition. This can contain one or more surface names. It is case sensitive and multiple names should be separated with a vertical pipe character like this. |
**Name:** inclusion_list,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Adiabatic Exclusion List
Surfaces listed here will not be changed to adiabatic boundary condition. This can contain one or more surface names. It is case sensitive and multiple names should be separated with a vertical pipe character like this. |
**Name:** exclusion_list,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




