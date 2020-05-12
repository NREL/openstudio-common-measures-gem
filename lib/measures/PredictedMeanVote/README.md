

###### (Automatically generated documentation)

# Predicted Mean Vote

## Description
This measure adds the necessary data to people objects to support Predicted Mean Vote output data. It also adds the variable request.

## Modeler Description
This will not add new people objects, but rather just extend the ones that are in the model. It will rely on schedules already made in the model instead of creating new schedules.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Enable ASHRAE 55 Comfort Warnings?

**Name:** comfortWarnings,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Mean Radiant Temperature Calculation Type

**Name:** meanRadiantCalcType,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose a Work Efficiency Schedule

**Name:** workEfficiencySchedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose a Clothing Insulation Schedule

**Name:** clothingSchedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose an Air Velocity Schedule

**Name:** airVelocitySchedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Reporting Frequency
The frequency at which to report timeseries output data.
**Name:** reporting_frequency,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




