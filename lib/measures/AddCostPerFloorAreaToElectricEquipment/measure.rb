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

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class AddCostPerFloorAreaToElectricEquipment < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Add Cost per Floor Area to Electric Equipment'
  end

  # human readable description
  def description
    return 'This measure will create life cycle cost objects associated with electric equipment. You can choose any electric equipment definition used in the model that has a watt/area power. You can set a material and installation cost, demolition cost, and O&M costs. Optionally existing cost objects already associated with the selected electric equipment definition can be deleted. This measure will not affect energy use of the building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure has a choice input populated with watt/area electric equipment definitions used in spaces in the model. It will add a number of life cycle cost objects and will associate them with the selected definition. In addition to the inputs for the cost values, a number of other inputs are exposed to specify when the cost first occurs and at what frequency it occurs in the future. This measure is intended to be used as an 'Always Run' measure to apply costs to objects that design alternatives will impact. This will add costs to the baseline model before any design alternatives manipulate it. As an example, if you plan adjust the performance and cost of electric equipment by a percentage, you will want to use this to cost the baseline definition.

For baseline costs, 'Years Until Costs Start' indicates the year that the capital costs first occur. For new construction this will be typically be 0 and 'Demolition Costs Occur During Initial Construction' will be false. For a retrofit 'Years Until Costs Start' is between 0 and the 'Expected Life' of the object, while 'Demolition Costs Occur During Initial Construction' is true. O&M cost and frequency can be whatever is appropriate for the component"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate choice argument for equip_defs that are applied to surfaces in the model
    equip_def_handles = OpenStudio::StringVector.new
    equip_def_display_names = OpenStudio::StringVector.new

    # putting space types and names into hash
    equip_def_args = model.getElectricEquipmentDefinitions
    equip_def_args_hash = {}
    equip_def_args.each do |equip_def_arg|
      equip_def_args_hash[equip_def_arg.name.to_s] = equip_def_arg
    end

    # looping through sorted hash of equip_defs
    equip_def_args_hash.sort.map do |key, value|
      # only include if equip_def is an equip_def, if it is used in a space, and is an LPD def
      if (value.quantity > 0) && !value.wattsperSpaceFloorArea.empty?
        equip_def_handles << value.handle.to_s
        equip_def_display_names << key
      end
    end

    # make an argument for equip_def
    # todo update this to allow all LPD elec equipment defs. Think about how we want to handle multiple equipment instances in same space.
    equip_def = OpenStudio::Measure::OSArgument.makeChoiceArgument('equip_def', equip_def_handles, equip_def_display_names, true)
    equip_def.setDisplayName('Choose a Watts per Area Electric Equipment Definition to Add Costs to')
    args << equip_def

    # make an argument to remove existing costs
    remove_costs = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_costs', true)
    remove_costs.setDisplayName('Remove Existing Costs')
    remove_costs.setDefaultValue(true)
    args << remove_costs

    # make an argument for material and installation cost
    material_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost_ip', true)
    material_cost_ip.setDisplayName('Material and Installation Costs for Construction per Area Used')
    material_cost_ip.setUnits('$/ft^2')
    material_cost_ip.setDefaultValue(0.0)
    args << material_cost_ip

    # make an argument for demolition cost
    demolition_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('demolition_cost_ip', true)
    demolition_cost_ip.setDisplayName('Demolition Costs for Construction per Area Used')
    demolition_cost_ip.setUnits('$/ft^2')
    demolition_cost_ip.setDefaultValue(0.0)
    args << demolition_cost_ip

    # make an argument for duration in years until costs start
    years_until_costs_start = OpenStudio::Measure::OSArgument.makeIntegerArgument('years_until_costs_start', true)
    years_until_costs_start.setDisplayName('Years Until Costs Start')
    years_until_costs_start.setUnits('whole years')
    years_until_costs_start.setDefaultValue(0)
    args << years_until_costs_start

    # make an argument to determine if demolition costs should be included in initial definition
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
    om_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost_ip', true)
    om_cost_ip.setDisplayName('O & M Costs for Construction per Area Used')
    om_cost_ip.setUnits('$/ft^2')
    om_cost_ip.setDefaultValue(0.0)
    args << om_cost_ip

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
    equip_def = runner.getOptionalWorkspaceObjectChoiceValue('equip_def', user_arguments, model) # model is passed in because of argument type
    remove_costs = runner.getBoolArgumentValue('remove_costs', user_arguments)
    material_cost_ip = runner.getDoubleArgumentValue('material_cost_ip', user_arguments)
    demolition_cost_ip = runner.getDoubleArgumentValue('demolition_cost_ip', user_arguments)
    years_until_costs_start = runner.getIntegerArgumentValue('years_until_costs_start', user_arguments)
    demo_cost_initial_const = runner.getBoolArgumentValue('demo_cost_initial_const', user_arguments)
    expected_life = runner.getIntegerArgumentValue('expected_life', user_arguments)
    om_cost_ip = runner.getDoubleArgumentValue('om_cost_ip', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # check the Definition for reasonableness
    if equip_def.empty?
      handle = runner.getStringArgumentValue('equip_def', user_arguments)
      if handle.empty?
        runner.registerError('No Electric Equipment Definition was chosen.')
      else
        runner.registerError("The selected Electric Equipment Definition with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !equip_def.get.to_ElectricEquipmentDefinition.empty?
        equip_def = equip_def.get.to_ElectricEquipmentDefinition.get
      else
        runner.registerError('Script Error - argument not showing up as Electric Equipment Definition.')
        return false
      end
    end

    # set flags to use later
    costs_requested = false
    costs_removed = false

    # check costs for reasonableness
    if material_cost_ip.abs + demolition_cost_ip.abs + om_cost_ip.abs == 0
      runner.registerInfo("No costs were requested for #{equip_def.name}.")
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

    # reporting initial condition of model
    runner.registerInitialCondition("Electric equipment definition #{equip_def.name} has #{equip_def.lifeCycleCosts.size} lifecycle cost objects.")

    # remove any component cost line items associated with the construction.
    if !equip_def.lifeCycleCosts.empty? && (remove_costs == true)
      runner.registerInfo("Removing existing lifecycle cost objects associated with #{equip_def.name}")
      removed_costs = equip_def.removeLifeCycleCosts
      costs_removed = !removed_costs.empty?
    end

    # show as not applicable if no cost requested and if no costs removed
    if (costs_requested == false) && (costs_removed == false)
      runner.registerAsNotApplicable('No new lifecycle costs objects were requested, and no costs were deleted.')
    end

    # add lifeCycleCost objects if there is a non-zero value in one of the cost arguments
    if costs_requested == true

      # converting doubles to si values from ip
      material_cost_si = OpenStudio.convert(OpenStudio::Quantity.new(material_cost_ip, OpenStudio.createUnit('1/ft^2').get), OpenStudio.createUnit('1/m^2').get).get.value
      demolition_cost_si = OpenStudio.convert(OpenStudio::Quantity.new(demolition_cost_ip, OpenStudio.createUnit('1/ft^2').get), OpenStudio.createUnit('1/m^2').get).get.value
      om_cost_si = OpenStudio.convert(OpenStudio::Quantity.new(om_cost_ip, OpenStudio.createUnit('1/ft^2').get), OpenStudio.createUnit('1/m^2').get).get.value

      # adding new cost items
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{equip_def.name}", equip_def, material_cost_si, 'CostPerArea', 'Construction', expected_life, years_until_costs_start)
      if demo_cost_initial_const
        lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{equip_def.name}", equip_def, demolition_cost_si, 'CostPerArea', 'Salvage', expected_life, years_until_costs_start)
      else
        lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{equip_def.name}", equip_def, demolition_cost_si, 'CostPerArea', 'Salvage', expected_life, years_until_costs_start + expected_life)
      end
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_OM - #{equip_def.name}", equip_def, om_cost_si, 'CostPerArea', 'Maintenance', om_frequency, 0)

    end

    # loop through lifecycle costs getting total costs under "Construction category"
    equip_def_LCCs = equip_def.lifeCycleCosts
    equip_def_total_mat_cost = 0
    equip_def_LCCs.each do |equip_def_LCC|
      if equip_def_LCC.category == 'Construction'
        equip_def_total_mat_cost += equip_def_LCC.totalCost
      end
    end

    # reporting final condition of model
    if !equip_def.lifeCycleCosts.empty?
      costed_area_ip = OpenStudio.convert(OpenStudio::Quantity.new(equip_def.lifeCycleCosts[0].costedArea.get, OpenStudio.createUnit('m^2').get), OpenStudio.createUnit('ft^2').get).get.value
      runner.registerFinalCondition("A new lifecycle cost object was added to Electric Equipment Definition #{equip_def.name} with an area of #{neat_numbers(costed_area_ip, 0)} (ft^2). Material and Installation costs are $#{neat_numbers(equip_def_total_mat_cost, 0)}.")
    else
      runner.registerFinalCondition("There are no lifecycle cost objects associated with Electric Equipment Definition #{equip_def.name}.")
    end

    return true
  end
end

# this allows the measure to be used by the application
AddCostPerFloorAreaToElectricEquipment.new.registerWithApplication
