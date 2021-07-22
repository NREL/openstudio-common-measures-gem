---
title: "ReadMe"
author: "Eric Bonnema"
date: "7/22/2020"
output:
  pdf_document: default
  html_document: default
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Add EMS to Control EV Charging Load
## Description
This measure reports emissions based on user-provided CSVs.

## Modeler Description
This measure uses EnergyPlus' Energy Management System to log and report emissions based on user provided CSV file(s).

## Measure Type
EnergyPlusMeasure

## Arguments
## CSV Path
Name: csv_path, Type: string, Units: none, Required: true, Model Dependent: false. This argument sets the path to the CSV file which contains the emissions information. There is no default.
