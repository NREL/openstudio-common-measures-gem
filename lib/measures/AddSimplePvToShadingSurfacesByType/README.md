

###### (Automatically generated documentation)

# Add Simple PV to Specified Shading Surfaces

## Description
This measure will add Simple PV objects to site, building or space/zone shading surfaces. This will not create any new geometry, but will just make PV objects out of existing shading geometry. Optionally a cost can be added for the PV.

## Modeler Description
This measure will add PV objects for all site, building, or zone shading surfaces. Site and Building surfaces exist in both OpenStudio and EnergyPlus. Space shading surfaces in OpenStudio are translated to zone shading surfaces in EnergyPlus. The necessary PV objects will be added for each surface, as well as a number of shared PV resources.  A number of arguments will expose various PV settings. The recurring cost objects added are not directly associated with the PV objects. If the PV objects are removed the cost will remain.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Choose the Type of Shading Surfaces to add PV to

**Name:** shading_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Fraction of Included Surface Area with PV

**Name:** fraction_surfacearea_with_pv,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Fractional Value for Cell Efficiency

**Name:** value_for_cell_efficiency,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Material and Installation Costs for the PV

**Name:** material_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### Expected Life

**Name:** expected_life,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false

### O & M Costs for the PV.

**Name:** om_cost,
**Type:** Double,
**Units:** $,
**Required:** true,
**Model Dependent:** false

### O & M Frequency

**Name:** om_frequency,
**Type:** Integer,
**Units:** whole years,
**Required:** true,
**Model Dependent:** false




