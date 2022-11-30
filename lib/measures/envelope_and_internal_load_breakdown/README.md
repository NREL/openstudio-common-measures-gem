

###### (Automatically generated documentation)

# Envelope and Internal Load Breakdown

## Description
Report provides annual and monthly views into heat gains and losses for envelope and internal loads.

## Modeler Description
It uses the following variables: Electric Equipment Total Heating Energy, Zone Lights Total Heating Energy, Zone, People Sensible Heating Energy, Surface Average Face Conduction Heat Transfer Energy, Surface Window Heat Gain Energy, Surface Window Heat Loss Energy, Zone Infiltration Sensible Heat Gain Energy, Zone Infiltration Sensible Heat Loss Energy. For Surface Average Face Conduction Heat Transfer Energy bin positive values as heat gain and negative values as heat loss.


## Measure Type
ReportingMeasure

## Taxonomy


## Arguments




This measure does not have any user arguments




###### (Manually generated documentation)
## Report Screenshots

* Colors of envelope components match default model rendering by surface type. 
* Colors for equipment and lights use colors similar to OpenStudio Results. 
* Click the blue headings above plots to expand source table. 

#### Heat Gains Summary
*Annual pie chart and monthly stacked bar chart by component.*

![Heat Gains Summary](./docs/htg_gain_summary.png?raw=true)

#### Heat Loss Summary
*Annual pie chart and monthly stacked bar chart by component.*

![Heat Loss Summary](./docs/htg_loss_summary.png?raw=true)

#### Heat Gains By Month Detailed
*Each component type has a table with each contributing object listed by month. There are annual totals for each component, and there is a monthly total with all components of that type aggregated*

![Heat Gains By Month Detailed - a](./docs/htg_gain_detailed_a.png?raw=true)

*Each sub-surface and surface with an outdoor or ground boundary boundary condition is listed. At the end of the surface type a row subtotals the heat gains by outdoor walls, outdoor roofs, and ground boundary surfaces.*
![Heat Gains By Month Detailed - b](./docs/htg_gain_detailed_b.png?raw=true)

#### Heat Losses By Month Detailed
*Each component type has a table with each contributing object listed by month. There are annual totals for each component, and there is a monthly total with all components of that type aggregated*

![Heat Losses By Month Detailed](./docs/htg_loss_detailed.png?raw=true)
