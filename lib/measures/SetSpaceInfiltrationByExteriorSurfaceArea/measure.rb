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

# start the measure
class SetSpaceInfiltrationByExteriorSurfaceArea < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Set Space Infiltration by Exterior Surface Area'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for infiltration
    infiltration_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('infiltration_ip', true)
    infiltration_ip.setDisplayName('Space Infiltration Flow per Exterior Envelope Surface Area (cfm/ft^2).') # (ft^3/min)/(ft^2) = (ft/min)
    infiltration_ip.setDefaultValue(0.05)
    args << infiltration_ip

    # make an argument for material and installation cost
    material_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost_ip', true)
    material_cost_ip.setDisplayName('Increase in Material and Installation Costs for Building per Exterior Envelope Area ($/ft^2).')
    material_cost_ip.setDefaultValue(0.0)
    args << material_cost_ip

    # make an argument for o&m cost
    om_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost_ip', true)
    om_cost_ip.setDisplayName('O & M Costs for Construction per Area Used ($/ft^2).')
    om_cost_ip.setDefaultValue(0.0)
    args << om_cost_ip

    # make an argument for o&m frequency
    om_frequency = OpenStudio::Measure::OSArgument.makeIntegerArgument('om_frequency', true)
    om_frequency.setDisplayName('O & M Frequency (whole years).')
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
    infiltration_ip = runner.getDoubleArgumentValue('infiltration_ip', user_arguments)
    material_cost_ip = runner.getDoubleArgumentValue('material_cost_ip', user_arguments)
    years_until_costs_start = 0 # removed user argument and set it to 0. For this measure it should always be 0
    om_cost_ip = runner.getDoubleArgumentValue('om_cost_ip', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # check infiltration for reasonableness
    if infiltration_ip < 0
      runner.registerError("The requested space infiltration flow rate of #{infiltration_ip} cfm/ft^2 was below the measure limit. Choose a positive number.")
      return false
    elsif infiltration_ip == 0.001 # put more thought into best warning trigger value
      runner.registerWarning("The requested space infiltration flow rate of  #{infiltration_ip} cfm/ft^2 seems abnormally low.")
    elsif infiltration_ip > 1.0 # put more thought into best warning trigger value
      runner.registerWarning("The requested space infiltration flow rate of  #{infiltration_ip} cfm/ft^2 seems abnormally high.")
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

    # helper to make it easier to do unit conversions on the fly
    def unit_helper(number, from_unit_string, to_unit_string)
      converted_number = OpenStudio.convert(OpenStudio::Quantity.new(number, OpenStudio.createUnit(from_unit_string).get), OpenStudio.createUnit(to_unit_string).get).get.value
    end

    # get space infiltration objects used in the model
    space_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates

    # reporting initial condition of model
    if !space_infiltration_objects.empty?
      runner.registerInitialCondition("The initial model contained #{space_infiltration_objects.size} space infiltration objects.")
    else
      runner.registerInitialCondition('The initial model did not contain any space infiltration objects.')
    end

    # remove space infiltration objects
    number_removed = 0
    number_left = 0
    space_infiltration_objects.each do |space_infiltration_object|
      opt_space_type = space_infiltration_object.spaceType
      if opt_space_type.empty?
        space_infiltration_object.remove
        number_removed += 1
      elsif !opt_space_type.get.spaces.empty?
        space_infiltration_object.remove
        number_removed += 1
      else
        number_left += 1
      end
    end
    if number_removed > 0
      runner.registerInfo("#{number_removed} infiltration objects were removed.")
    end
    if number_left > 0
      runner.registerInfo("#{number_left} infiltration objects in unused space types were left in the model. They will not be altered.")
    end

    # if no default space type then add an empty one (to hold new space infiltration object)
    building = model.getBuilding
    if building.spaceType.empty?
      new_default = OpenStudio::Model::SpaceType.new(model)
      new_default.setName('Building Default Space Type')
      building.setSpaceType(new_default)
      runner.registerInfo("Adding a building default space type to hold space infiltration for spaces that previously didn't have a space type.")
    end

    # si units for infiltration argument
    infiltration_si = unit_helper(infiltration_ip, 'ft/min', 'm/s')

    # loop through spacetypes used in the model adding space infiltration objects
    space_types = model.getSpaceTypes
    space_types.each do |space_type|
      if !space_type.spaces.empty?
        new_space_type_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        new_space_type_infil.setFlowperExteriorSurfaceArea(infiltration_si)
        new_space_type_infil.setSpaceType(space_type)
        if new_space_type_infil.schedule.empty?
          # TODO: - check if the warning below is falsely triggering when it does not need to.
          runner.registerWarning("The new infiltration object for space type '#{space_type.name}' does not have a schedule. Assigning a default schedule set including an infiltration schedule to the space type or the building will address this.")
        end
      end
    end

    # get area of surfaces with outdoor boundary condition. Take zone multipliers into account
    surfaces = model.getSurfaces
    exterior_surface_gross_area = 0
    space_warning_issued = []

    surfaces.each do |s|
      next if s.outsideBoundaryCondition != 'Outdoors'

      # get surface area adjusting for zone multiplier
      space = s.space
      if !space.empty?
        zone = space.get.thermalZone
      end
      if !zone.empty?
        zone_multiplier = zone.get.multiplier
        if (zone_multiplier > 1) && !space_warning_issued.include?(space.get.name.to_s)
          runner.registerInfo("Space #{space.get.name} in thermal zone #{zone.get.name} has a zone multiplier of #{zone_multiplier}. Adjusting area calculations.")
          space_warning_issued << space.get.name.to_s
        end
      else
        zone_multiplier = 1 # space is not in a thermal zone
        runner.registerWarning("Space #{space.get.name} is not in a thermal zone and won't be included in in the simulation. For area calculations in this measure a zone multiplier of 1 will be assumed.")
      end
      exterior_surface_gross_area += s.grossArea * zone_multiplier
    end

    # ip exterior surface area for reporting and building lifeCycleCostObject
    exterior_surface_gross_area_ip = unit_helper(exterior_surface_gross_area, 'm^2', 'ft^2')

    # only add LifeCyCyleCostItem if the user entered some non 0 cost values
    if (material_cost_ip != 0) || (om_cost_ip != 0)
      material_cost_si = unit_helper(material_cost_ip, '1/ft^2', '1/m^2')
      om_cost_si = unit_helper(om_cost_ip, '1/ft^2', '1/m^2')
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('LCC_Mat - Cost to Adjust Infiltration', building, exterior_surface_gross_area * material_cost_si, 'CostPerEach', 'Construction', 0, years_until_costs_start) # 0 for expected life will result infinite expected life
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('LCC_OM - Cost to Adjust Infiltration', building, exterior_surface_gross_area * om_cost_si, 'CostPerEach', 'Maintenance', om_frequency, years_until_costs_start) # o&m costs start after at sane time that material and installation costs occur
      runner.registerInfo("Costs related to the change in infiltration are attached to the building object. Any subsequent measures that may affect infiltration won't affect these costs.")
    else
      runner.registerInfo('Cost arguments were not provided, no cost objects were added to the model.')
    end

    # reporting final condition of model
    if !lcc_mat.nil?
      cost_per_area_ip = lcc_mat.get.totalCost / exterior_surface_gross_area_ip
    else
      cost_per_area_ip = 0
    end

    runner.registerFinalCondition("The final model has an infiltration rate of #{neat_numbers(infiltration_ip)} (cfm/ft^2). The material and installation cost increase resulting from this measure is $#{neat_numbers(cost_per_area_ip)} ($/ft^2) over #{neat_numbers(exterior_surface_gross_area_ip, 0)} (ft^2) of exterior envelope.")

    return true
  end
end

# this allows the measure to be used by the application
SetSpaceInfiltrationByExteriorSurfaceArea.new.registerWithApplication
