

###### (Automatically generated documentation)

# Create Variable Speed RTU

## Description
This measure examines the existing HVAC system(s) present in the current OpenStudio model. If a constant-speed system is found, the user can opt to have the measure replace that system with a variable-speed RTU. 'Variable speed' in this case means that the compressor will be operated using either two or four stages (user's choice). The user can choose between using a gas heating coil, or a direct-expansion (DX) heating coil. Additionally, the user is able to enter the EER (cooling) and COP (heating) values for each DX stage. This measure allows users to easily identify the impact of improved part-load efficiency.

## Modeler Description
This measure loops through the existing airloops, looking for loops that have a constant speed fan. (Note that if an object such as an AirloopHVAC:UnitarySystem is present in the model, that the measure will NOT identify that loop as either constant- or variable-speed, since the fan is located inside the UnitarySystem object.) The user can designate which constant-speed airloop they'd like to apply the measure to, or opt to apply the measure to all airloops. The measure then replaces the supply components on the airloop with an AirloopHVAC:UnitarySystem object. Any DX coils added to the UnitarySystem object are of the type CoilCoolingDXMultiSpeed / CoilHeatingDXMultiSpeed, with the number of stages set to either two or four, depending on user input. If the user opts for a gas furnace, an 80% efficient CoilHeatingGas object is added. Fan properties (pressure rise and total efficiency) are transferred automatically from the existing (but deleted) constant speed fan to the new variable-speed fan. Currently, this measure is only applicable to the Standalone Retail DOE Prototype building model, but it has been structured to facilitate expansion to other models with a minimum of effort.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Choose an Air Loop to change from CAV to VAV.

**Name:** object,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Choose the type of cooling coil.

**Name:** cooling_coil_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Rated Cooling Coil EER

**Name:** rated_cc_eer,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Cooling Coil EER at 75% Capacity

**Name:** three_quarter_cc_eer,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Cooling Coil EER at 50% Capacity

**Name:** half_cc_eer,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Cooling Coil EER at 25% Capacity

**Name:** quarter_cc_eer,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Choose the type of heating coil.

**Name:** heating_coil_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Rated Gas Heating Coil Efficiency (0-1.00)

**Name:** rated_hc_gas_efficiency,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Rated Heating Coil COP

**Name:** rated_hc_cop,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Heating Coil COP at 75% Capacity

**Name:** three_quarter_hc_cop,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Heating Coil COP at 50% Capacity

**Name:** half_hc_cop,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Heating Coil COP at 25% Capacity

**Name:** quarter_hc_cop,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false




