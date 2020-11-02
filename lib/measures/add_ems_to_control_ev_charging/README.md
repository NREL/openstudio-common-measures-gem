---
title: "ReadMe"
author: "Amy Allen"
date: "8/18/2020"
output:
  pdf_document: default
  html_document: default
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```


## Add EMS to Control EV Charging Load 
## Description
This measure uses EnergyPlus' EnergyManagementSystem objects to control an electric vehicle charging load to better align the charging power draw with expected solar PV power production. If the need for load shifting passes, and, in any case, by late afternoon, the load shifting will be ended, and the EV load be charged at a higher rate in order to compensate for the earlier curtailment. Curtailment will be compensated for such that vehicles being charged are charged to at least 95% of the level that they would have been otherwise. 

## Modeler Description 
This measure is intended for use at a 15-minute timestep.This measure requires than an electric vehicle charging load (with a schedule containing the strings "EV" or "V(v)ehicle" in the name) is already present in the model. This can be accomplished through first applying the Add EV Load measure. Note that this measure can result in increasing the peak load associated with EV charging, during the periods in which curtailment is compensated. This measure is structured around the assumption of an office building occupancy schedule, with occupants requiring vehicles to be charged by 7pm. Load shifting events are characterized by declining levels of solar radiation, which is used as a proxy for diminishing power output from on-site solar PV. Load shifting occurs only on weekdays, when commercial buildings would typically have higher EV charging loads. 

## Measure Type
EnergyPlusMeasure

## Arguments
## Curtailment Fraction
Name: Curtailment Frac, Type: Double, Units: Percent , Required: true, Model Dependent: false. This argument sets the fraction by which EV charging will be curtailed during a load-shifting event. This value defaults to 50%. 


