## Add EMS to Report Emissions
## Description
This measure reports emissions based on user-provided CSVs.

## Modeler Description
This measure uses EnergyPlus' Energy Management System to log and report emissions based on user provided CSV file(s).

## Measure Type
EnergyPlusMeasure

## Arguments
## Subregion
Name: sub_regn, Type: string, Units: none, Required: true, Model Dependent: false. This argument is the eGrid subregion. Options are: AZNM, CAMX, ERCT, FRCC, MROE, MROW, NEWE, NWPP, NYST, RFCE, RFCM, RFCW, RMPA, SPNO, SPSO, SRMV, SRMW, SRSO, SRTV, and SRVC. Default is RMPA. 
## Future Year
Name: fut_year, Type: integer, Units: none, Required: true, Model Dependent: false. This argument is the future year of interest. Options are: 2020 to 2050 in two year increments. Default is 2030.
## Historical Year
Name: his_year, Type: integer, Units: none, Required: true, Model Dependent: false. This argument is the historical year of interest. Options are: 2007, 2009, 2010, 2012, 2014, 2016, 2018, and 2019. Default is 2010.
