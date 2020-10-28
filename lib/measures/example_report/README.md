

###### (Automatically generated documentation)

# Example Report

## Description
Simple example of modular code to create tables and charts in OpenStudio reporting measures. This is not meant to use as is, it is an example to help with reporting measure development.

## Modeler Description
This measure uses the same framework and technologies (bootstrap and dimple) that the standard OpenStudio results report uses to create an html report with tables and charts. Download this measure and copy it to your Measures directory using PAT or the OpenStudio application. Then alter the data in os_lib_reporting_custom.rb to suit your needs. Make new sections and tables as needed.

## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### Tasty Treats

**Name:** template_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Material Properties

**Name:** mat_prop_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### General Building Information

**Name:** general_building_information_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




