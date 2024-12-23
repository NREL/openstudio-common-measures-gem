# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SetSpaceInfiltrationPerExteriorArea < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'SetSpaceInfiltrationPerExteriorArea'
  end

  # human readable description
  def description
    return 'Set Space Infiltration Design Flow Rate per exterior area for the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Replace this text with an explanation for the energy modeler specifically.  It should explain how the measure is modeled, including any requirements about how the baseline model must be set up, major assumptions, citations of references to applicable modeling resources, etc.  The energy modeler should be able to read this description and understand what changes the measure is making to the model and why these changes are being made.  Because the Modeler Description is written for an expert audience, using common abbreviations for brevity is good practice.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # add double argument for space infiltration target
    flow_per_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('flow_per_area', true)
    flow_per_area.setDisplayName('Flow per Exterior Surface Area.')
    flow_per_area.setUnits('CFM/ft^2')
    flow_per_area.setDefaultValue(0.05)
    args << flow_per_area

    # add choice argument for exterior surfaces vs. just walls
    choices = OpenStudio::StringVector.new
    choices << 'ExteriorArea'
    choices << 'ExteriorWallArea'
    ext_surf_cat = OpenStudio::Measure::OSArgument.makeChoiceArgument('ext_surf_cat', choices, true)
    ext_surf_cat.setDisplayName('Exterior surfaces to include')
    ext_surf_cat.setDefaultValue('ExteriorArea')
    args << ext_surf_cat

    # interpret input as infiltration at 50PA presasure difference
    input_value_at_50_pa = OpenStudio::Measure::OSArgument.makeBoolArgument('input_value_at_50_pa', true)
    input_value_at_50_pa.setDisplayName('Interpret Flow Rate as seen at 50 Pascal Pressure Difference')
    input_value_at_50_pa.setDescription('Set to true if the flow per exterior surface entered represents the flow rate during blower door test with 50 Pascal pressure difference. When set to false the input value will be passed directly to the energy model.')
    input_value_at_50_pa.setDefaultValue(false)
    args << input_value_at_50_pa

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
    flow_per_area = runner.getDoubleArgumentValue('flow_per_area', user_arguments)
    ext_surf_cat = runner.getStringArgumentValue('ext_surf_cat', user_arguments)
    input_value_at_50_pa = runner.getBoolArgumentValue('input_value_at_50_pa', user_arguments)

    # check the flow_per_area for reasonableness
    if flow_per_area < 0
      runner.registerError('Please enter a non negative flow rate.')
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaceInfiltrationDesignFlowRates.size} SpaceInfiltrationDesignFlowRate objects and #{model.getSpaceInfiltrationEffectiveLeakageAreas.size} SpaceInfiltrationEffectiveLeakageArea objects.")

    # remove any SpaceInfiltrationEffectiveLeakageArea objects
    model.getSpaceInfiltrationEffectiveLeakageAreas.each(&:remove)

    # find most common lights schedule for use in spaces that do not have lights
    sch_hash = {}
    spaces_wo_infil = []
    # add schedules or infil directly assigned to space
    model.getSpaces.each do |space|
      space_has_infil = 0
      space_type_has_infil = 0
      space.spaceInfiltrationDesignFlowRates.each do |infil|
        if space_has_infil > 0
          runner.registerInfo("#{space.name} has more than one infiltration object, removing #{infil.name} to avoid excess infiltration in resulting model.")
          infil.remove
        end
        space_has_infil += 1
        if infil.schedule.is_initialized
          sch = infil.schedule.get
          if sch_hash.key?(sch)
            sch_hash[sch] += 1
          else
            sch_hash[sch] = 1
          end
        end
      end
      # add schedule for infil assigned to space types
      if space.spaceType.is_initialized
        space.spaceType.get.spaceInfiltrationDesignFlowRates.each do |infil|
          if space_type_has_infil > 0
            runner.registerInfo("#{space_type.name} has more than one infiltration object, removing #{infil.name} to avoid excess infiltration in resulting model.")
            infil.remove
          end
          space_type_has_infil += 1
          if infil.schedule.is_initialized
            sch = infil.schedule.get
            if sch_hash.key?(sch)
              sch_hash[sch] += 1
            else
              sch_hash[sch] = 1
            end
          end
        end
      end

      # identify spaces without infiltration and remove multiple infiltration from spaces
      if space_has_infil + space_type_has_infil == 0
        spaces_wo_infil << space
      elsif space_has_infil == 1 && space_type_has_infil == 1
        infil_to_rem = space.spaceInfiltrationDesignFlowRates.first
        runner.registerInfo("#{space.name} has infiltration object in both the space and space type, removing #{infil_to_rem.name} to avoid excess infiltration in resulting model.")
        infil_to_rem.remove
      end
    end
    most_comm_sch = sch_hash.key(sch_hash.values.max)

    # get target flow rate in ip
    if input_value_at_50_pa
      orig_flow = flow_per_area
      flow_per_area = flow_per_area / 8.92857
      runner.registerInfo("Converting flow rate of #{orig_flow.round(2)} (CFM/ft^2) at 50pa to #{flow_per_area.round(2)} (CFM/ft^2) for the energy analysis.")
    end
    flow_per_area_si = OpenStudio.convert(flow_per_area, 'ft/min', 'm/s').get

    # set infil for existing SpaceInfiltrationDesignFlowRate objects
    model.getSpaceInfiltrationDesignFlowRates.each do |infil|
      # TODO: - skip if this is unused space type
      next if infil.spaceType.is_initialized && infil.spaceType.get.floorArea == 0
      runner.registerInfo("Changing flow rate for #{infil.name}.")
      if ext_surf_cat == 'ExteriorWallArea'
        infil.setFlowperExteriorWallArea(flow_per_area_si)
      else # ExteriorArea
        infil.setFlowperExteriorSurfaceArea(flow_per_area_si)
      end
    end

    # add in new SpaceInfiltrationDesignFlowRate objects to any spaces taht don't have direct or inherited infiltration
    spaces_wo_infil.each do |space|
      infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      infil.setSchedule(most_comm_sch)
      runner.registerInfo("Adding new infiltration object to #{space.name} which did not initially have an infiltration object.")
      if ext_surf_cat == 'ExteriorWallArea'
        infil.setFlowperExteriorWallArea(flow_per_area_si)
      else # ExteriorArea
        infil.setFlowperExteriorSurfaceArea(flow_per_area_si)
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaceInfiltrationDesignFlowRates.size} SpaceInfiltrationDesignFlowRate objects and #{model.getSpaceInfiltrationEffectiveLeakageAreas.size} SpaceInfiltrationEffectiveLeakageArea objects.")

    return true
  end
end

# register the measure to be used by the application
SetSpaceInfiltrationPerExteriorArea.new.registerWithApplication
