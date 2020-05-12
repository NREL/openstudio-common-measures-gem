

###### (Automatically generated documentation)

# Remove Orphan Objects and Unused Resources

## Description
This is the start of a measure that will have expanded functionality over time. It will have two distinct functions. One will be to remove orphan objects. This will typically include things that should never have been left alone and often are not visible in the GUI. This would include load instances without a space or space type, and surfaces without a space.

A second functionality is to remove unused resources. This will include things like space types, schedules, constructions, and materials. There will be a series of checkboxes to enable/disable this purge. There won't be an option for the orphan objects. They will always be removed.

## Modeler Description
Purging objects like space types, schedules, and constructions requires a specific sequence to be most effective. This measure will first remove unused space types, then load defs, schedules sets, schedules,  construction sets, constructions, and then materials. A space type having a construction set assign, will show that construction set as used even if no spaces are assigned to that space type. That is why order is important.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Remove Unused Space Types

**Name:** remove_unused_space_types,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Unused Load Definitions

**Name:** remove_unused_load_defs,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Unused Schedules Sets and Schedules

**Name:** remove_unused_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Unused Curves

**Name:** remove_unused_curves,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Unused Construction Sets, Constructions, and Materials

**Name:** remove_unused_constructions,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




