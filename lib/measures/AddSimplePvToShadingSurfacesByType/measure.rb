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
class AddSimplePvToShadingSurfacesByType < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see
  def name
    return 'Add Simple PV to Specified Shading Surfaces'
  end

  # human readable description
  def description
    return 'This measure will add Simple PV objects to site, building or space/zone shading surfaces. This will not create any new geometry, but will just make PV objects out of existing shading geometry. Optionally a cost can be added for the PV.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will add PV objects for all site, building, or zone shading surfaces. Site and Building surfaces exist in both OpenStudio and EnergyPlus. Space shading surfaces in OpenStudio are translated to zone shading surfaces in EnergyPlus. The necessary PV objects will be added for each surface, as well as a number of shared PV resources.  A number of arguments will expose various PV settings. The recurring cost objects added are not directly associated with the PV objects. If the PV objects are removed the cost will remain.'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for shading surfaces
    chs = OpenStudio::StringVector.new
    chs << 'Site Shading'
    chs << 'Building Shading'
    chs << 'Space/Zone Shading'
    shading_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('shading_type', chs, true)
    shading_type.setDisplayName('Choose the Type of Shading Surfaces to add PV to')
    shading_type.setDefaultValue('Building Shading')
    args << shading_type

    # Fraction of surfaces to contain PV
    fraction_surfacearea_with_pv = OpenStudio::Measure::OSArgument.makeDoubleArgument('fraction_surfacearea_with_pv', true)
    fraction_surfacearea_with_pv.setDisplayName('Fraction of Included Surface Area with PV')
    fraction_surfacearea_with_pv.setDefaultValue(0.5)
    args << fraction_surfacearea_with_pv

    # Value for Cell Efficiency
    value_for_cell_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument('value_for_cell_efficiency', true)
    value_for_cell_efficiency.setDisplayName('Fractional Value for Cell Efficiency')
    value_for_cell_efficiency.setDefaultValue(0.12)
    args << value_for_cell_efficiency

    # make an argument for material and installation cost
    material_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost', true)
    material_cost.setDisplayName('Material and Installation Costs for the PV')
    material_cost.setUnits('$')
    material_cost.setDefaultValue(0.0)
    args << material_cost

    # make an argument for expected life
    expected_life = OpenStudio::Measure::OSArgument.makeIntegerArgument('expected_life', true)
    expected_life.setDisplayName('Expected Life')
    expected_life.setUnits('whole years')
    expected_life.setDefaultValue(20)
    args << expected_life

    # make an argument for o&m cost
    om_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost', true)
    om_cost.setDisplayName('O & M Costs for the PV.')
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
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    shading_type = runner.getStringArgumentValue('shading_type', user_arguments)
    fraction_surfacearea_with_pv = runner.getDoubleArgumentValue('fraction_surfacearea_with_pv', user_arguments)
    value_for_cell_efficiency = runner.getDoubleArgumentValue('value_for_cell_efficiency', user_arguments)
    material_cost = runner.getDoubleArgumentValue('material_cost', user_arguments)
    expected_life = runner.getIntegerArgumentValue('expected_life', user_arguments)
    om_cost = runner.getDoubleArgumentValue('om_cost', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # set flags to use later
    costs_requested = false

    # check the surface type for reasonableness
    if shading_type == 'Site Shading'
      pv_shading_surfaces = workspace.getObjectsByType('Shading:Site:Detailed'.to_IddObjectType)
    elsif shading_type == 'Building Shading'
      pv_shading_surfaces = workspace.getObjectsByType('Shading:Building:Detailed'.to_IddObjectType)
    elsif shading_type == 'Space/Zone Shading'
      pv_shading_surfaces = workspace.getObjectsByType('Shading:Zone:Detailed'.to_IddObjectType)
    else
      runner.registerError("You shouldn't see this, something went wrong with choice arguments.")
      return false
    end

    if pv_shading_surfaces.empty?
      runner.registerAsNotApplicable("The model does not contain any #{shading_type} surfaces. The model will not be altered.")
      return true
    end

    if (fraction_surfacearea_with_pv < 0) || (fraction_surfacearea_with_pv > 1)
      runner.registerError('Please pick a value between or equal to 0 and 1 for the fraction of surface to receive PV.')
      return false
    end

    if (value_for_cell_efficiency < 0) || (value_for_cell_efficiency > 1)
      runner.registerError('Please pick a value between or equal to 0 and 1 for the PV cell efficiency.')
      return false
    end

    # check costs for reasonableness
    if material_cost.abs + om_cost.abs == 0
      runner.registerInfo('No costs were requested for the PV.')
    else
      costs_requested = true
    end

    # check lifecycle arguments for reasonableness
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
    gen_pv = workspace.getObjectsByType('Generator:Photovoltaic'.to_IddObjectType)
    runner.registerInitialCondition("The initial building had #{gen_pv.size} PV generator objects.")

    # cancel out of model appears to already have PV. current script doesn't handle this, but could be added later
    if !gen_pv.empty?
      runner.registerError("This model appears to already have some PV objects. The measure isn't designed to work on models that already have PV.")
      return false
    end

    # array to hold new IDF objects needed for PV
    string_objects = []

    # add PhotovoltaicPerformance:Simple object
    string_objects << "
      PhotovoltaicPerformance:Simple,
        pvPerformanceObject,  !- Name
        #{fraction_surfacearea_with_pv},  !- Fraction of Surface Area with Active Solar Cells {dimensionless}
        Fixed,                            !- Conversion Efficiency Input Mode
        #{value_for_cell_efficiency};     !- Value for Cell Efficiency if Fixed
        "

    # add Generator:Photovoltaic objects

    # array to hold names of generators for ElectricLoadCenter:Generators object
    generator_list = []

    pv_shading_surfaces.each do |shading_surface|
      # set the fields to the values you want
      surface_name = shading_surface.getString(0).to_s
      gen_name = "gen #{surface_name}".to_s

      # add name to generator list array
      generator_list << gen_name

      # make Generator:Photovoltaic object
      string_objects << "
        Generator:Photovoltaic,
          #{gen_name},                     !- Name
          #{surface_name},                 !- Surface Name ** change to match your surface
          PhotovoltaicPerformance:Simple,  !- Photovoltaic Performance Object Type
          pvPerformanceObject,             !- Module Performance Name
          Decoupled,                       !- Heat Transfer Integration Mode
          1.0,                             !- Number of Modules in Parallel {dimensionless}
          1.0;                             !- Number of Modules in Series {dimensionless}
          "
    end

    if generator_list.empty?
      # put in a failure here if generator_list.size = 0
      exit
    end

    # add pv Always On Schedule
    string_objects << "
    Schedule:Compact,
    pv_script always On,     !- Name
    Fraction,                !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,1.0;        !- Field 3
    "

    # add ElectricLoadCenter objects
    build_elec_load_ctr_gen = []

    # start of build_elec_load_ctr_gen string
    build_elec_load_ctr_gen << "
      ElectricLoadCenter:Generators,
        PV list,                 !- Name
        "

    # middle of build_elec_load_ctr_gen string
    if generator_list.size > 1
      for generator in generator_list[0...-1]
        build_elec_load_ctr_gen << "
            #{generator},            !- Generator Name
            Generator:Photovoltaic,  !- Generator Object Type
            20000,                   !- Generator Rated Electric Power Output
            pv_script always On,     !- Generator Availability Schedule Name
            ,                        !- Generator Rated Thermal to Electrical Power Ratio
            "
      end
    end

    # last object special for ; vs , of build_elec_load_ctr_gen string
    build_elec_load_ctr_gen << "
        #{generator_list.reverse[0]},    !- Generator Name
        Generator:Photovoltaic,  !- Generator Object Type
        20000,                   !- Generator Rated Electric Power Output
        pv_script always On,     !- Generator Availability Schedule Name
        ;                        !- Generator Rated Thermal to Electrical Power Ratio
        "

    # merging the ElectricLoadCenter:Generators object into a single string
    string_objects << build_elec_load_ctr_gen.join('')

    string_objects << "
      ElectricLoadCenter:Inverter:Simple,
        Simple Ideal Inverter,   !- Name
        pv_script always On,               !- Availability Schedule Name
        ,                        !- Zone Name
        0.0,                     !- Radiative Fraction
        0.95;                     !- Inverter Efficiency
        "

    string_objects << "
      ElectricLoadCenter:Distribution,
        Simple Electric Load Center,  !- Name
        PV list,                 !- Generator List Name
        Baseload,                !- Generator Operation Scheme Type
        0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}
        ,                        !- Track Schedule Name Scheme Schedule Name
        ,                        !- Track Meter Scheme Meter Name
        DirectCurrentWithInverter,  !- Electrical Buss Type
        Simple Ideal Inverter;   !- Inverter Object Name
        "

    # add PV related variable requests
    string_objects << 'Output:Variable,*,PV Generator DC Power,hourly;'
    string_objects << 'Output:Variable,*,PV Generator DC Energy,hourly;'
    string_objects << 'Output:Variable,*,Inverter AC Energy Output,hourly;'
    string_objects << 'Output:Variable,*,Inverter AC Power Output,hourly;'
    string_objects << 'Output:Variable,*,PV Array Efficiency,hourly;'
    string_objects << 'Output:Meter,Photovoltaic:ElectricityProduced,hourly;'

    # add all of the strings to workspace
    # this script won't behave well if added multiple times in the workflow. Need to address name conflicts
    string_objects.each do |string_object|
      idfObject = OpenStudio::IdfObject.load(string_object)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end

    if costs_requested

      # add mat cost
      lcc_mat_string = "
      LifeCycleCost:RecurringCosts,
        LCC_Mat - #{shading_type} PV,           !- Name
        Replacement,                            !- Category
        #{material_cost},                       !- Cost
        ServicePeriod,                          !- Start of Costs
        0,                                      !- Years from Start
        ,                                       !- Months from Start
        #{expected_life};                       !- Repeat Period Years
        "
      idfObject = OpenStudio::IdfObject.load(lcc_mat_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      lcc_mat = wsObject.get

      runner.registerInfo("Added construction cost of $#{neat_numbers(material_cost, 0)}, with an expected life of #{lcc_mat.getString(6)} years.")

      # add o&m cost
      lcc_om_string = "
      LifeCycleCost:RecurringCosts,
        LCC_Mat - #{shading_type} PV,           !- Name
        Replacement,                            !- Category
        #{om_cost},                       !- Cost
        ServicePeriod,                          !- Start of Costs
        0,                                      !- Years from Start
        ,                                       !- Months from Start
        #{om_frequency};                       !- Repeat Period Years
        "
      idfObject = OpenStudio::IdfObject.load(lcc_om_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      lcc_om = wsObject.get

      runner.registerInfo("Added O & M cost of $#{neat_numbers(om_cost, 0)}, at a frequency of #{lcc_om.getString(6)} year(s).")

    end

    # reporting final condition of model
    final_gen_pv = workspace.getObjectsByType('Generator:Photovoltaic'.to_IddObjectType)
    runner.registerFinalCondition("The final building has #{final_gen_pv.size} PV generator objects.")

    return true
  end
end

# this allows the measure to be used by the application
AddSimplePvToShadingSurfacesByType.new.registerWithApplication
