# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class ReduceSpaceInfiltrationByPercentage < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ReduceSpaceInfiltrationByPercentage'
  end

  # human readable description
  def description
    return 'This measure will reduce space infiltration rates by the requested percentage. A cost per square foot of building area can be added to the model.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This can be run across a space type or the entire building. Costs will be associated with the building. If infiltration objects are removed at a later date, the costs will remain.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    # looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key, value|
      # only include if space type is used in the model
      if !value.spaces.empty?
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    # add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << '*Entire Building*'

    # make a choice argument for space type
    space_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('space_type', space_type_handles, space_type_display_names)
    space_type.setDisplayName('Apply the Measure to a Specific Space Type or to the Entire Model.')
    space_type.setDefaultValue('*Entire Building*') # if no space type is chosen this will run on the entire building
    args << space_type

    # make an argument for reduction percentage
    space_infiltration_reduction_percent = OpenStudio::Measure::OSArgument.makeDoubleArgument('space_infiltration_reduction_percent', true)
    space_infiltration_reduction_percent.setDisplayName('Space Infiltration Power Reduction')
    space_infiltration_reduction_percent.setDefaultValue(30.0)
    space_infiltration_reduction_percent.setUnits('%')
    args << space_infiltration_reduction_percent

    # make an argument for constant_coefficient
    constant_coefficient = OpenStudio::Measure::OSArgument.makeDoubleArgument('constant_coefficient', true)
    constant_coefficient.setDisplayName('Constant Coefficient')
    constant_coefficient.setDefaultValue(1.0)
    args << constant_coefficient

    # make an argument for temperature_coefficient
    temperature_coefficient = OpenStudio::Measure::OSArgument.makeDoubleArgument('temperature_coefficient', true)
    temperature_coefficient.setDisplayName('Temperature Coefficient')
    temperature_coefficient.setDefaultValue(0.0)
    args << temperature_coefficient

    # make an argument for wind_speed_coefficient
    wind_speed_coefficient = OpenStudio::Measure::OSArgument.makeDoubleArgument('wind_speed_coefficient', true)
    wind_speed_coefficient.setDisplayName('Wind Speed Coefficient')
    wind_speed_coefficient.setDefaultValue(0.0)
    args << wind_speed_coefficient

    # make an argument for wind_speed_squared_coefficient
    wind_speed_squared_coefficient = OpenStudio::Measure::OSArgument.makeDoubleArgument('wind_speed_squared_coefficient', true)
    wind_speed_squared_coefficient.setDisplayName('Wind Speed Squared Coefficient')
    wind_speed_squared_coefficient.setDefaultValue(0.0)
    args << wind_speed_squared_coefficient

    # make an argument for alter_coef
    alter_coef = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_coef', true)
    alter_coef.setDisplayName('Alter constant temperature and wind speed coefficients.')
    alter_coef.setDescription('Setting this to false will result in infiltration objects that maintain the coefficients from the initial model. Setting this to true replaces the existing coefficients with the values entered for the coefficient arguments in this measure')
    alter_coef.setDefaultValue(true)
    args << alter_coef


    # make an argument for material and installation cost
    material_and_installation_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_and_installation_cost', true)
    material_and_installation_cost.setDisplayName('Increase in Material and Installation Costs for Building per Affected Floor Area')
    material_and_installation_cost.setDefaultValue(0.0)
    material_and_installation_cost.setUnits('$/ft^2')
    args << material_and_installation_cost

    # make an argument for O & M cost
    om_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost', true)
    om_cost.setDisplayName('O & M Costs for Construction per Affected Floor Area')
    om_cost.setDefaultValue(0.0)
    om_cost.setUnits('$/ft^2')
    args << om_cost

    # make an argument for O & M frequency
    om_frequency = OpenStudio::Measure::OSArgument.makeIntegerArgument('om_frequency', true)
    om_frequency.setDisplayName('O & M Frequency')
    om_frequency.setDefaultValue(1)
    om_frequency.setUnits('whole years')
    args << om_frequency

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    space_infiltration_reduction_percent = runner.getDoubleArgumentValue('space_infiltration_reduction_percent', user_arguments)
    constant_coefficient = runner.getDoubleArgumentValue('constant_coefficient', user_arguments)
    temperature_coefficient = runner.getDoubleArgumentValue('temperature_coefficient', user_arguments)
    wind_speed_coefficient = runner.getDoubleArgumentValue('wind_speed_coefficient', user_arguments)
    wind_speed_squared_coefficient = runner.getDoubleArgumentValue('wind_speed_squared_coefficient', user_arguments)
    alter_coef = runner.getBoolArgumentValue('alter_coef', user_arguments)
    material_and_installation_cost = runner.getDoubleArgumentValue('material_and_installation_cost', user_arguments)
    om_cost = runner.getDoubleArgumentValue('om_cost', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # check the space_type for reasonableness and see if measure should run on space type or on the entire building
    apply_to_building = false
    space_type = nil
    if object.empty?
      handle = runner.getStringArgumentValue('space_type', user_arguments)
      if handle.empty?
        runner.registerError('No space type was chosen.')
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !object.get.to_SpaceType.empty?
        space_type = object.get.to_SpaceType.get
      elsif !object.get.to_Building.empty?
        apply_to_building = true
      else
        runner.registerError('Script Error - argument not showing up as space type or building.')
        return false
      end
    end

    # check the space_infiltration_reduction_percent and for reasonableness
    if space_infiltration_reduction_percent > 100
      runner.registerError('Please enter a value less than or equal to 100 for the Space Infiltration reduction percentage.')
      return false
    elsif space_infiltration_reduction_percent == 0
      runner.registerInfo('No Space Infiltration adjustment requested, but infiltration coefficients or life cycle costs may still be affected.')
    elsif (space_infiltration_reduction_percent < 1) && (space_infiltration_reduction_percent > -1)
      runner.registerWarning("A Space Infiltration reduction percentage of #{space_infiltration_reduction_percent} percent is abnormally low.")
    elsif space_infiltration_reduction_percent > 90
      runner.registerWarning("A Space Infiltration reduction percentage of #{space_infiltration_reduction_percent} percent is abnormally high.")
    elsif space_infiltration_reduction_percent < 0
      runner.registerInfo('The requested value for Space Infiltration reduction percentage was negative. This will result in an increase in Space Infiltration.')
    end

    # todo - currently not checking for negative $/ft^2 for material_and_installation_cost and om_cost, confirm if E+ will allow negative cost

    if om_frequency < 1
      runner.registerError('Choose an integer greater than 0 for O & M Frequency.')
    end

    # helper to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure.
    def neat_numbers(number, roundto = 2) # round to 0 or 2)
      if roundto == 2
        number = format '%.2f', number
      else
        number = number.round
      end
      # regex to add commas
      number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
    end

    # get space infiltration objects used in the model
    space_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates
    # TODO: - it would be nice to give ranges for different calculation methods but would take some work.

    # counters needed for measure
    altered_instances = 0
    affected_area_si = 0

    # reporting initial condition of model
    if !space_infiltration_objects.empty?
      runner.registerInitialCondition("The initial model contained #{space_infiltration_objects.size} space infiltration objects.")
    else
      runner.registerInitialCondition('The initial model did not contain any space infiltration objects.')
    end

    # get space types in model
    building = model.building.get
    if apply_to_building
      space_types = model.getSpaceTypes
      affected_area_si = building.floorArea
    else
      space_types = []
      space_types << space_type # only run on a single space type
      affected_area_si = space_type.floorArea
    end

    # def to alter performance and life cycle costs of objects
    def alter_performance(object, space_infiltration_reduction_percent, constant_coefficient, temperature_coefficient, wind_speed_coefficient, wind_speed_squared_coefficient, alter_coef, runner)
      # edit instance based on percentage reduction
      instance = object
      if !instance.designFlowRate.empty?
        new_infiltration_design_flow_rate = instance.setDesignFlowRate(instance.designFlowRate.get - instance.designFlowRate.get * space_infiltration_reduction_percent * 0.01)
      elsif !instance.flowperSpaceFloorArea.empty?
        new_infiltration_flow_floor_area = instance.setFlowperSpaceFloorArea(instance.flowperSpaceFloorArea.get - instance.flowperSpaceFloorArea.get * space_infiltration_reduction_percent * 0.01)
      elsif !instance.flowperExteriorSurfaceArea.empty?
        new_infiltration_flow_ext_area = instance.setFlowperExteriorSurfaceArea(instance.flowperExteriorSurfaceArea.get - instance.flowperExteriorSurfaceArea.get * space_infiltration_reduction_percent * 0.01)
      elsif !instance.flowperExteriorWallArea.empty?
        new_infiltration_flow_ext_area = instance.setFlowperExteriorWallArea(instance.flowperExteriorWallArea.get - instance.flowperExteriorWallArea.get * space_infiltration_reduction_percent * 0.01)
      elsif !instance.airChangesperHour.empty?
        new_infiltration_ach = instance.setAirChangesperHour(instance.airChangesperHour.get - instance.airChangesperHour.get * space_infiltration_reduction_percent * 0.01)
      else
        runner.registerWarning("'#{instance.name}' is used by one or more instances and has no load values.")
      end

      # only alter coefficients if requested
      if alter_coef
        instance.setConstantTermCoefficient(constant_coefficient)
        instance.setTemperatureTermCoefficient(temperature_coefficient)
        instance.setVelocityTermCoefficient(wind_speed_coefficient)
        instance.setVelocitySquaredTermCoefficient(wind_speed_squared_coefficient)
      end

    end

    # loop through space types
    space_types.each do |space_type|
      next if space_type.spaces.size <= 0
      space_type_infiltration_objects = space_type.spaceInfiltrationDesignFlowRates
      space_type_infiltration_objects.each do |space_type_infiltration_object|
        # call def to alter performance and life cycle costs
        alter_performance(space_type_infiltration_object, space_infiltration_reduction_percent, constant_coefficient, temperature_coefficient, wind_speed_coefficient, wind_speed_squared_coefficient, alter_coef, runner)

        # rename
        updated_instance_name = space_type_infiltration_object.setName("#{space_type_infiltration_object.name} #{space_infiltration_reduction_percent} percent reduction")
        altered_instances += 1
      end
    end

    # getting spaces in the model
    spaces = model.getSpaces

    # get space types in model
    if apply_to_building
      spaces = model.getSpaces
    else
      if !space_type.spaces.empty?
        spaces = space_type.spaces # only run on a single space type
      end
    end

    spaces.each do |space|
      space_infiltration_objects = space.spaceInfiltrationDesignFlowRates
      space_infiltration_objects.each do |space_infiltration_object|
        # call def to alter performance and life cycle costs
        alter_performance(space_infiltration_object, space_infiltration_reduction_percent, constant_coefficient, temperature_coefficient, wind_speed_coefficient, wind_speed_squared_coefficient, alter_coef, runner)

        # rename
        updated_instance_name = space_infiltration_object.setName("#{space_infiltration_object.name} #{space_infiltration_reduction_percent} percent reduction")
        altered_instances += 1
      end
    end

    if (altered_instances == 0) && (material_and_installation_cost == 0) && (om_cost == 0)
      runner.registerAsNotApplicable('No space infiltration objects were found in the specified space type(s) and no life cycle costs were requested.')
    end

    # only add LifeCyCyleCostItem if the user entered some non 0 cost values
    affected_area_ip = OpenStudio.convert(affected_area_si, 'm^2', 'ft^2').get
    if (material_and_installation_cost != 0) || (om_cost != 0)
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('LCC_Mat - Cost to Adjust Infiltration', building, affected_area_ip * material_and_installation_cost, 'CostPerEach', 'Construction', 0, 0) # 0 for expected life will result infinite expected life
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('LCC_OM - Cost to Adjust Infiltration', building, affected_area_ip * om_cost, 'CostPerEach', 'Maintenance', om_frequency, 0) # o&m costs start after at sane time that material and installation costs occur
      runner.registerInfo("Costs related to the change in infiltration are attached to the building object. Any subsequent measures that may affect infiltration won't affect these costs.")
      final_cost = lcc_mat.get.totalCost
    else
      runner.registerInfo('Cost arguments were not provided, no cost objects were added to the model.')
      final_cost = 0
    end

    # report final condition
    runner.registerFinalCondition("#{altered_instances} space infiltration objects in the model were altered affecting #{neat_numbers(affected_area_ip, 0)}(ft^2) at a total cost of $#{neat_numbers(final_cost, 0)}.")

    return true
  end
end

# this allows the measure to be use by the application
ReduceSpaceInfiltrationByPercentage.new.registerWithApplication
