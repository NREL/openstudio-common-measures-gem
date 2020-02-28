

###### (Automatically generated documentation)

# Get Site from Building Component Library

## Description
Populate choice list from BCL, then selected site will be brought into model. This will include the weather file, design days, and water main temperatures.

## Modeler Description
To start with measure will hard code a string to narrow the search. Then a shorter list than all weather files on BCL will be shown. In the future woudl be nice to select region based on climate zone set in building object.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Zip Code for project
Enter valid us 5 digit zipcode
**Name:** zipcode,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use Upstream Argument Values
When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.
**Name:** use_upstream_args,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




