# Guide for Air Wall Zone Mixing Measure

## Measure Intent
 - This measure is meant to provide a simple approximation of zone mixing where the zone boundary doesn’t represent a physical wall.
 - Typically the “Air Wall” construction In OpenStudio is mainly used if using Radiance for daylighting. For thermal analysis it is modeled as something similar to plywood.
 - This measure uses air walls to define where zone mixing should be used instead of conductive heat transfer.
 
## Seed Model Preparation
 - Create a model with air walls for zone boundaries
 that don’t represent physical walls.
 - If you have a core and perimeter model you can just set the construction set default for interior wall to “Air Wall”. If not you can manually set just the walls you want by hard assigning constructions.
 - You can split a matched wall and make only a portoon of it air walls.
 
## How the Measure Works
 
 - The measure works by adding a pair of zone mixing objects between zones with matched wall surfaces using the air wall construction.
 - At the same time the boundary conditoon is changed to adiabatic so there isn’t simulation of both conductoon and air transfer.
 - A simple formula with user adjustable coefficient is applied where it takes 4x the depth of a space given the same opening size to get 2x the CFM of air mixing.
 - With a coefficient of 1 a zone that is as deep as it is high should have about 1 ACH of air mixing.
 
## Formula used to calculate air mixing volume
***air mixing rate (CFM) = zone mixing coefficient * zone volume / sqrt(zone volume / (air wall area * zone height))***
 
## Example Scenarios
 
![Time Series Results](./docs/example_a.png?raw=true) 
***Example A:***
1 * 4000 ft^3 / sqrt(4000 ft^3 / (400 ft^2 * 10 ft)) = 4000 ft^3 per hour = 1 ACH and 66.67 CFM

![Time Series Results](./docs/example_b.png?raw=true) 
***Example B:***
1 * 16,000 ft^3 / sqrt(16,000 ft^3 / (400 ft^2 * 10 ft)) = 8000 ft^3 per hour = 0.5 ACH and 133.3 CFM

![Time Series Results](./docs/example_c.png?raw=true) 
***Example C:***
1 * 4000 ft^3 / sqrt(4000 ft^3 / (400 ft^2 * 40 ft)) = 8000 ft^3 per hour = 2 ACH and 133.3 CFM

![Time Series Results](./docs/example_d.png?raw=true) 
***Example D:***
1 * 16,000 ft^3 / sqrt(16,000 ft^3 / (1600 ft^2 * 40 ft)) = 32,000 ft^3 per hour = 2 ACH and 533.3 CFM
 
  - In examples A and B the opening area and height is the same. Example B has 4 times the depth, double the total airflow (CFM) and half of the ACH as example A.
    - Using the current formula, a space has to be 4x deeper to double the airflow (CFM).
 - Example C, which looks like A on its side has a similar resulting airflow (CFM) to example B.
 - Example D is the same as Example A, but with the height increased by 4x. It results in 8x the CFM and 2x the ACH for Example D vs. Example A.
   - Using the current formula, a space has to be 4x taller to double the air changes per hour that result from the formula.
 - Formula is calculated independently for a pair adjacent spaces. The lower of the two resulting airflow values (CFM) is used for the air mixing objects.
  
## View of Measure Log Messages
  
![Time Series Results](./docs/measure_logs.png?raw=true)
 
## View of Simulation Results

![Simulation Results](./docs/simulation_results.png?raw=true)
   
## View of Time Series Results

![Time Series Results](./docs/timeseries_results.png?raw=true)

## Limitations and Known Issues
 - The formula used isn’t perfect, it jsut provides an approximation of airflow across the zone boundary. The goal is to offer an alternative to the conductive transfer that has no airflow across the zone boundary.
   - Based on the specific characteristics of the geometry and internal characteristics of your model, you can adjust the cross mixing coefficent as descired. It can also be altered as part of an uncertainly analysis.
 - The formula was developed with orthogonal spaces in mind. If you have a diagonal line across a boundary like the intersection of two perimeter zones on a core and perimeter model, it may over estimate the airflow. This is because the formula uses a very simple approach to estimate the depth of a zone by dividing the volume by the opening area, assuming the opening is the entire connecting area.
 - Currently the measure just works on walls and not floors, and isn’t appropriate for a stack of spaces like s stair well.