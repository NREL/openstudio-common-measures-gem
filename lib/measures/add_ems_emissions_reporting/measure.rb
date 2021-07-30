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

require 'csv'
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'

# start the measure
class AddEMSEmissionsReporting < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Add EMS to Report Emissions'
  end

  # human readable description
  def description
    return 'This measure reports emissions based on user-provided eGrid subregion.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure uses the EnergyPlus Energy Management System to log and report emissions based on user provided eGrid subregion.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # eGrid subregion
    sub_regn = OpenStudio::Measure::OSArgument.makeStringArgument('sub_regn', true)
    sub_regn.setDisplayName('eGrid subregion')
    sub_regn.setDescription('eGrid subregion. Options are: AZNM, CAMX, ERCT, FRCC, MROE, MROW, NEWE, NWPP, NYST, RFCE, RFCM, RFCW, RMPA, SPNO, SPSO, SRMV, SRMW, SRSO, SRTV, and SRVC')
    sub_regn.setDefaultValue('RMPA')
    args << sub_regn

    # future year
    fut_year = OpenStudio::Measure::OSArgument.makeIntegerArgument('fut_year', true)
    fut_year.setDisplayName('Future Year')
    fut_year.setDescription('Future Year. Options are: 2020 to 2050 in two year increments')
    fut_year.setDefaultValue(2030)
    args << fut_year

    # historical year
    his_year = OpenStudio::Measure::OSArgument.makeIntegerArgument('his_year', true)
    his_year.setDisplayName('Historial Year')
    his_year.setDescription('Historial Year. Options are: 2007, 2009, 2010, 2012, 2014, 2016, 2018, and 2019.')
    his_year.setDefaultValue(2010)
    args << his_year

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, usr_args)
    super(model, runner, usr_args)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), usr_args)

    # assign the user inputs to variables
    sub_regn = runner.getStringArgumentValue('sub_regn', usr_args)
    fut_year = runner.getStringArgumentValue('fut_year', usr_args)
    his_year = runner.getStringArgumentValue('his_year', usr_args)

    csv_path = "#{File.expand_path(File.dirname(__FILE__))}/resources/future_hourly_#{fut_year}.csv"
    fut_path = "#{File.expand_path(File.dirname(__FILE__))}/resources/future_annual_subregion.csv"
    his_path = "#{File.expand_path(File.dirname(__FILE__))}/resources/historical_annual_subregion.csv"

    # find external file
    if File.exist?(csv_path)
      csv_file = OpenStudio::Model::ExternalFile::getExternalFile(model, csv_path)
      if csv_file.is_initialized
        csv_file = csv_file.get
        csv_data = CSV.read(csv_path, headers:true)
        fut_data = CSV.read("#{File.expand_path(File.dirname(__FILE__))}/resources/future_annual_subregion.csv", headers:true)
        his_data = CSV.read("#{File.expand_path(File.dirname(__FILE__))}/resources/historical_annual_subregion.csv", headers:true)
      end
    else
      runner.registerError("Could not find CSV file at #{csv_path}")
      return false
    end

    # add schedule type limits for schedule file
    lim_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
    lim_type.setName('Emissions Sch File Type Limits')

    # add schedule file
    sch_file = OpenStudio::Model::ScheduleFile.new(csv_file)
    sch_file.setName("#{sub_regn} #{fut_year} Hourly Emissions Sch")
    sch_file.setScheduleTypeLimits(lim_type)
    sch_file.setColumnNumber(csv_data.headers.index(sub_regn) + 1)
    sch_file.setRowstoSkipatTop(1)
    sch_file.setNumberofHoursofData(8760)
    sch_file.setColumnSeparator('Comma')
    sch_file.setInterpolatetoTimestep(false)
    sch_file.setMinutesperItem(60)

    # add EMS sensor for schedule file
    sch_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    sch_sens.setKeyName("#{sub_regn} #{fut_year} Hourly Emissions Sch")
    sch_sens.setName('Hour_Sen')

    # add whole-building electricity sensor
    sch_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Facility Total Purchased Electricity Energy')
    sch_sens.setKeyName('Whole Building')
    sch_sens.setName('Elec_Sen')

    ems_prgm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ems_prgm.setName('Emissions_Calc_Prgm')
    fut_data.each {|r| ems_prgm.addLine("SET fann = #{r['co2_rate']}") if r['subregion'] == sub_regn && r['year'] == fut_year}
    his_data.each {|r| ems_prgm.addLine("SET hann = #{r['co2_rate']}") if r['subregion'] == sub_regn && r['year'] == his_year}
    ems_prgm.addLine('SET hval = Hour_Sen')
    ems_prgm.addLine('SET elec = Elec_Sen')
    ems_prgm.addLine('SET mult = 1000 * 60 * 60') # J to kWh (1000J/kJ * 60hr/min * 60 min/sec)
    ems_prgm.addLine('SET hrly = hval * elec / mult')
    ems_prgm.addLine('SET futr = fann * elec / mult')
    ems_prgm.addLine('SET hist = hann * elec / mult')

    # add EMS program calling manager
    mgr_prgm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    mgr_prgm.setName('Emissions Calc Prgm')
    mgr_prgm.setCallingPoint('EndOfSystemTimestepBeforeHVACReporting')
    mgr_prgm.setProgram(ems_prgm, 0)

    # add future hourly EMS output variable
    ems_var1 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'hrly')
    ems_var1.setName("#{sub_regn}_#{fut_year}_Hourly_Emissions_Var")
    ems_var1.setEMSVariableName('hrly')
    ems_var1.setTypeOfDataInVariable('Summed')
    ems_var1.setUpdateFrequency('SystemTimestep')
    ems_var1.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var1.setUnits('kg')

    # add future annual EMS output variable
    ems_var2 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'futr')
    ems_var2.setName("#{sub_regn}_#{fut_year}_Annual_Emissions_Var")
    ems_var2.setEMSVariableName('futr')
    ems_var2.setTypeOfDataInVariable('Summed')
    ems_var2.setUpdateFrequency('SystemTimestep')
    ems_var2.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var2.setUnits('kg')

    # add historical annual EMS output variable
    ems_var3 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'hist')
    ems_var3.setName("#{sub_regn}_#{his_year}_Annual_Emissions_Var")
    ems_var3.setEMSVariableName('hrly')
    ems_var3.setTypeOfDataInVariable('Summed')
    ems_var3.setUpdateFrequency('SystemTimestep')
    ems_var3.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var3.setUnits('kg')

    # add future hourly reporting output variable
    out_var1 = OpenStudio::Model::OutputVariable.new("#{sub_regn}_#{fut_year}_Hourly_Emissions_Var", model)
    out_var1.setKeyValue('EMS')
    out_var1.setReportingFrequency('hourly')

    # add future annual reporting output variable
    out_var2 = OpenStudio::Model::OutputVariable.new("#{sub_regn}_#{fut_year}_Annual_Emissions_Var", model)
    out_var2.setKeyValue('EMS')
    out_var2.setReportingFrequency('hourly')

    # add historical annual reporting output variable
    out_var3 = OpenStudio::Model::OutputVariable.new("#{sub_regn}_#{his_year}_Annual_Emissions_Var", model)
    out_var3.setKeyValue('EMS')
    out_var3.setReportingFrequency('hourly')

    return true
  end
end

# register the measure to be used by the application
AddEMSEmissionsReporting.new.registerWithApplication
