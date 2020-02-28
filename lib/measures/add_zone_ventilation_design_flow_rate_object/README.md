

###### (Automatically generated documentation)

# Add Zone Ventilation Design Flow Rate Object

## Description
This will allow you to add a ZoneVentilation:DesignFlowRate object into your model in a specified zone. The ventilation type is exposed as an argument but the design flow rate calculation method is set to design flow rate. A number of other object inputs are exposed as arguments

## Modeler Description
This is simple implementation ment to expose the object to users. More complex use case specific versions will likely be developed in the future that may add multiple zone ventilation objects as well as zone mixing objects

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Choose Thermal Zones to add zone ventilation to

**Name:** zone,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose Schedulew

**Name:** vent_sch,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Ventilation Type

**Name:** vent_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Design Flow Rate

**Name:** design_flow_rate,
**Type:** Double,
**Units:** cfm,
**Required:** true,
**Model Dependent:** false




