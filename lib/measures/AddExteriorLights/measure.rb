# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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

# start the measure
class AddExteriorLights < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Add Exterior Lights'
  end

  # human readable description
  def description
    return 'Add exterior lighting to the building.  This may be in addition to or in place of existing exterior lighting.  This lighting will run from sunset to sunrise. Optionally you can add costs to the lights.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure has an argument for design power (W) and a name for the new exterior lights, as well as an option to remove any existing exterior lights. It will add an ExteriorLightsDefinition object and associate it with an Exterior Lights object. The lights will have a schedule that always has fractional value of 1 but the object will be controlled by an astronomical clock. Cost is added to the building and not the lights. If the lights are removed at a later date, the cost will remain.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for lighting level
    ext_lighting_level = OpenStudio::Measure::OSArgument.makeDoubleArgument('ext_lighting_level', true)
    ext_lighting_level.setDisplayName('Exterior Lighting Design Power')
    ext_lighting_level.setUnits('W')
    ext_lighting_level.setDefaultValue(1000.0)
    args << ext_lighting_level

    # make an argument for end-use subcategory
    end_use_subcategory = OpenStudio::Measure::OSArgument.makeStringArgument('end_use_subcategory', true)
    end_use_subcategory.setDisplayName('End-Use SubCategory')
    end_use_subcategory.setDefaultValue('Exterior Facade Lighting')
    args << end_use_subcategory

    # make an argument to determine if existing exterior lights should be removed
    remove_existing_ext_lights = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_existing_ext_lights', true)
    remove_existing_ext_lights.setDisplayName('Remove Existing Exterior Lights in the Project')
    remove_existing_ext_lights.setDefaultValue(false)
    args << remove_existing_ext_lights

    # make an argument for material and installation cost
    material_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost', true)
    material_cost.setDisplayName('Material and Installation Costs for Exterior Lights')
    material_cost.setUnits('$')
    material_cost.setDefaultValue(0.0)
    args << material_cost

    # make an argument for demolition cost
    demolition_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('demolition_cost', true)
    demolition_cost.setDisplayName('Demolition Costs for Exterior Lights')
    demolition_cost.setUnits('$')
    demolition_cost.setDefaultValue(0.0)
    args << demolition_cost

    # make an argument for duration in years until costs start
    years_until_costs_start = OpenStudio::Measure::OSArgument.makeIntegerArgument('years_until_costs_start', true)
    years_until_costs_start.setDisplayName('Years Until Costs Start')
    years_until_costs_start.setUnits('whole years')
    years_until_costs_start.setDefaultValue(0)
    args << years_until_costs_start

    # make an argument to determine if demolition costs should be included in initial construction
    demo_cost_initial_const = OpenStudio::Measure::OSArgument.makeBoolArgument('demo_cost_initial_const', true)
    demo_cost_initial_const.setDisplayName('Demolition Costs Occur During Initial Construction')
    demo_cost_initial_const.setDefaultValue(false)
    args << demo_cost_initial_const

    # make an argument for expected life
    expected_life = OpenStudio::Measure::OSArgument.makeIntegerArgument('expected_life', true)
    expected_life.setDisplayName('Expected Life')
    expected_life.setUnits('whole years')
    expected_life.setDefaultValue(20)
    args << expected_life

    # make an argument for o&m cost
    om_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost', true)
    om_cost.setDisplayName('O & M Costs for Exterior Lights')
    om_cost.setUnits('$')
    om_cost.setDefaultValue(0.0)
    args << om_cost

    # make an argument for o&m frequency
    om_frequency = OpenStudio::Measure::OSArgument.makeIntegerArgument('om_frequency', true)
    om_frequency.setDisplayName('O & M Frequency')
    om_frequency.setUnits('whole years')
    om_frequency.setDefaultValue(1)
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
    ext_lighting_level = runner.getDoubleArgumentValue('ext_lighting_level', user_arguments)
    end_use_subcategory = runner.getStringArgumentValue('end_use_subcategory', user_arguments)
    remove_existing_ext_lights = runner.getBoolArgumentValue('remove_existing_ext_lights', user_arguments)
    material_cost = runner.getDoubleArgumentValue('material_cost', user_arguments)
    demolition_cost = runner.getDoubleArgumentValue('demolition_cost', user_arguments)
    years_until_costs_start = runner.getIntegerArgumentValue('years_until_costs_start', user_arguments)
    demo_cost_initial_const = runner.getBoolArgumentValue('demo_cost_initial_const', user_arguments)
    expected_life = runner.getIntegerArgumentValue('expected_life', user_arguments)
    om_cost = runner.getDoubleArgumentValue('om_cost', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # check the lpd for reasonableness
    if ext_lighting_level < 0
      runner.registerError("An exterior lighting power of #{ext_lighting_level} Watts is below the measure limit. Choose a non-negative number.")
      return false
    elsif ext_lighting_level > 9999 # hard to pin down without building size. I could get building area and add a per area value to get this?
      runner.registerWarning("An exterior lighting power of  #{ext_lighting_level} Watts seems abnormally high depending on the size of your building.")
    end

    if (ext_lighting_level == 0) && remove_existing_ext_lights
      runner.registerWarning('The requested lighting power was 0 watts and existing exterior lights have been removed. The final model has no exterior lights.')
    elsif ext_lighting_level == 0
      runner.registerAsNotApplicable('The requested lighting power was 0 watts and existing exterior lights have not been removed. This measure will not affect the simulation results.')
      return true # no need to continue through the measure if it won't do anything
    end

    # set flags to use later
    costs_requested = false

    # check costs for reasonableness
    if material_cost.abs + demolition_cost.abs + om_cost.abs == 0
      runner.registerInfo('No costs were requested for Exterior Lights.')
    else
      costs_requested = true
    end

    # check lifecycle arguments for reasonableness
    if (years_until_costs_start < 0) && (years_until_costs_start > expected_life)
      runner.registerError('Years until costs start should be a non-negative integer less than Expected Life.')
    end
    if (expected_life < 1) && (expected_life > 100)
      runner.registerError('Choose an integer greater than 0 and less than or equal to 100 for Expected Life.')
    end
    if om_frequency < 1
      runner.registerError('Choose an integer greater than 0 for O & M Frequency.')
    end

    # short def to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure
    def neat_numbers(number, roundto = 2) # round to 0 or 2)
      if roundto == 2
        number = format '%.2f', number
      else
        number = number.round
      end
      # regex to add commas
      number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
    end

    # helper that loops through lifecycle costs getting total costs under "Construction" or "Salvage" category and add to counter if occurs during year 0
    def get_total_costs_for_objects(objects)
      counter = 0
      objects.each do |object|
        object_LCCs = object.lifeCycleCosts
        object_LCCs.each do |object_LCC|
          if (object_LCC.category == 'Construction') || (object_LCC.category == 'Salvage')
            if object_LCC.yearsFromStart == 0
              counter += object_LCC.totalCost
            end
          end
        end
      end
      return counter
    end

    # get total lighting
    facility = model.getFacility
    starting_exterior_lights_power = 0
    starting_exterior_lights = facility.exteriorLights
    starting_exterior_lights.each do |starting_exterior_light|
      starting_exterior_light_multiplier = starting_exterior_light.multiplier
      starting_exterior_light_def = starting_exterior_light.exteriorLightsDefinition
      starting_exterior_light_base_power = starting_exterior_light_def.designLevel
      starting_exterior_lights_power += starting_exterior_light_base_power * starting_exterior_light_multiplier
    end

    # reporting initial condition of model
    runner.registerInitialCondition("The initial model had #{starting_exterior_lights.size} exterior lights with a total power of #{starting_exterior_lights_power} Watts.")

    # remove exterior lights if requested
    if remove_existing_ext_lights
      starting_exterior_lights.each do |starting_exterior_light|
        runner.registerInfo("Removed exterior light named #{starting_exterior_light.name}.")
        starting_exterior_light.remove
      end
    end

    # creating exterior lights definition
    if ext_lighting_level != 0
      ext_lights_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
      ext_lights_def.setName("#{ext_lighting_level} w Exterior Lighting Definition")
      runner.registerInfo("Setting exterior lights definition to a design power of #{ext_lighting_level} Watts")
      ext_lights_def.setDesignLevel(ext_lighting_level)

      # creating schedule type limits for the exterior lights schedule
      ext_lights_sch_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      ext_lights_sch_type_limits.setName('Exterior Lights Fractional')
      ext_lights_sch_type_limits.setLowerLimitValue(0)
      ext_lights_sch_type_limits.setUpperLimitValue(1)
      ext_lights_sch_type_limits.setNumericType('Continuous')

      # creating an exterior lights schedule
      ext_lights_sch = OpenStudio::Model::ScheduleConstant.new(model)
      ext_lights_sch.setName("#{ext_lighting_level} w Exterior Lights Sch")
      ext_lights_sch_handle = ext_lights_sch.handle
      ext_lights_sch.setScheduleTypeLimits(ext_lights_sch_type_limits)
      ext_lights_sch.setValue(1)

      # creating exterior lights object
      ext_lights = OpenStudio::Model::ExteriorLights.new(ext_lights_def, ext_lights_sch)
      ext_lights.setName("#{ext_lighting_level} w Exterior Light")
      ext_lights.setControlOption('AstronomicalClock')
      ext_lights.setEndUseSubcategory(end_use_subcategory)

      # get building to add cost to
      building = model.getBuilding

      # add lifeCycleCost objects if there is a non-zero value in one of the cost arguments
      if costs_requested == true

        starting_lcc_counter = building.lifeCycleCosts.size

        # adding new cost items
        lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{ext_lights_def.name}", building, material_cost, 'CostPerEach', 'Construction', expected_life, years_until_costs_start)
        if demo_cost_initial_const
          lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{ext_lights_def.name}", building, demolition_cost, 'CostPerEach', 'Salvage', expected_life, years_until_costs_start)
        else
          lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{ext_lights_def.name}", building, demolition_cost, 'CostPerEach', 'Salvage', expected_life, years_until_costs_start + expected_life)
        end
        lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_OM - #{ext_lights_def.name}", building, om_cost, 'CostPerEach', 'Maintenance', om_frequency, 0)

        if building.lifeCycleCosts.size - starting_lcc_counter == 3
          runner.registerInfo("Cost for #{ext_lights_def.name} was added to the building object. If you remove the exterior light from the model, the cost will still remain.")
        else
          runner.registerWarning("The measure did not function as expected. #{building.lifeCycleCosts.size - starting_lcc_counter} LifeCycleCost objects were made, 3 were expected.")
        end

      end

      # show as not applicable if no cost requested
      if costs_requested == false
        runner.registerAsNotApplicable('No new lifecycle costs objects were requested.')
      end

      # get final year 0 cost
      building_array = [] # def below needs an array vs. object
      building_array << building
      yr0_capital_totalCosts = get_total_costs_for_objects(building_array)

    end

    # get total lighting
    final_exterior_lights_power = 0
    final_exterior_lights = facility.exteriorLights
    final_exterior_lights.each do |final_exterior_light|
      final_exterior_light_multiplier = final_exterior_light.multiplier
      final_exterior_light_def = final_exterior_light.exteriorLightsDefinition
      final_exterior_light_base_power = final_exterior_light_def.designLevel
      final_exterior_lights_power += final_exterior_light_base_power * final_exterior_light_multiplier
    end

    # reporting final condition of model
    runner.registerFinalCondition("The final model has  #{final_exterior_lights.size} exterior lights objects with a total power of #{final_exterior_lights_power} Watts. The initial year capital costs for adding #{ext_lights_def.name} was $ #{neat_numbers(yr0_capital_totalCosts, 0)}.")

    return true
  end
end

# this allows the measure to be used by the application
AddExteriorLights.new.registerWithApplication
