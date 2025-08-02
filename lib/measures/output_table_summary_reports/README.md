

###### (Automatically generated documentation)

# Output Table Summary Reports

## Description
This Measure adds one of the predefined summary table outputs from EnergyPlus to the the Model, which can be helpful for requesting monthly or sizing reports.

## Modeler Description
OpenStudio automatically adds the AllSummary report during translation to EnergyPlus. Choices include reports with the All* prefix and do not include individual predefined reports such as the "Annual Building Utility Performance Summary". Including the Component Load Summary reports (any with *AndSizingPeriod) will increase the simulation run time

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Output Table Summary Report
AllSummary is added automatically by OpenStudio.
**Name:** report,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




