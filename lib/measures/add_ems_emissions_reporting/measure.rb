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
    return 'This measure reports emissions based on user-provided future and historical years as well as future, historical hourly, and historical annual subregions.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure uses the EnergyPlus Energy Management System to log and report emissions based on user-provided future and historical years as well as future, historical hourly, and historical annual subregions.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # future subregion
    future_subregion = OpenStudio::Measure::OSArgument.makeStringArgument('future_subregion', true)
    future_subregion.setDisplayName('Future subregion')
    future_subregion.setDescription('Future subregion. Options are: AZNMc, CAMXc, ERCTc, FRCCc, MROEc, MROWc, NEWEc, NWPPc, NYSTc, RFCEc, RFCMc, RFCWc, RMPAc, SPNOc, SPSOc, SRMVc, SRMWc, SRSOc, SRTVc, and SRVCc')
    future_subregion.setDefaultValue('RMPAc')
    args << future_subregion

    # historical hourly subregion
    hourly_historical_subregion = OpenStudio::Measure::OSArgument.makeStringArgument('hourly_historical_subregion', true)
    hourly_historical_subregion.setDisplayName('Historical hourly subregion')
    hourly_historical_subregion.setDescription('Historical hourly subregion. Options are: California, Carolinas, Central, Florida, Mid-Atlantic, Midwest, New England, New York, Northwest, Rocky Mountains, Southeast, Southwest, Tennessee, and Texas')
    hourly_historical_subregion.setDefaultValue('Rocky Mountains')
    args << hourly_historical_subregion

    # historical annual subregion
    annual_historical_subregion = OpenStudio::Measure::OSArgument.makeStringArgument('annual_historical_subregion', true)
    annual_historical_subregion.setDisplayName('Historical annual subregion')
    annual_historical_subregion.setDescription('Historical annual subregion. Options are: AKGD, AKMS, AZNM, CAMX, ERCT, FRCC, HIMS, HIOA, MROE, MROW, NEWE, NWPP, NYCW, NYLI, NYUP, RFCE, RFCM, RFCW, RMPA, SPNO, SPSO, SRMV, SRMW, SRSO, SRTV, and SRVC')
    annual_historical_subregion.setDefaultValue('RMPA')
    args << annual_historical_subregion

    # future year
    future_year = OpenStudio::Measure::OSArgument.makeIntegerArgument('future_year', true)
    future_year.setDisplayName('Future Year')
    future_year.setDescription('Future Year. Options are: 2020 to 2050 in two year increments')
    future_year.setDefaultValue(2020)
    args << future_year

    # hourly historical year
    hourly_historical_year = OpenStudio::Measure::OSArgument.makeIntegerArgument('hourly_historical_year', true)
    hourly_historical_year.setDisplayName('Hourly Historical Year')
    hourly_historical_year.setDescription('Hourly Historical Year. Options are: 2019.')
    hourly_historical_year.setDefaultValue(2019)
    args << hourly_historical_year

    # annual historical year
    annual_historical_year = OpenStudio::Measure::OSArgument.makeIntegerArgument('annual_historical_year', true)
    annual_historical_year.setDisplayName('Annual Historical Year')
    annual_historical_year.setDescription('Annual Historical Year. Options are: 2007, 2009, 2010, 2012, 2014, 2016, 2018, and 2019.')
    annual_historical_year.setDefaultValue(2019)
    args << annual_historical_year

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, usr_args)
    super(model, runner, usr_args)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), usr_args)

    # assign the user inputs to variables
    future_subregion = runner.getStringArgumentValue('future_subregion', usr_args)
    hourly_historical_subregion = runner.getStringArgumentValue('hourly_historical_subregion', usr_args)
    annual_historical_subregion = runner.getStringArgumentValue('annual_historical_subregion', usr_args)
    future_year = runner.getIntegerArgumentValue('future_year', usr_args)
    hourly_historical_year = runner.getIntegerArgumentValue('hourly_historical_year', usr_args)
    annual_historical_year = runner.getIntegerArgumentValue('annual_historical_year', usr_args)

    fut_hr_path = "#{__dir__}/resources/future_hourly_co2e_#{future_year}.csv"
    his_hr_path = "#{__dir__}/resources/historical_hourly_co2e_#{hourly_historical_year}.csv"
    fut_yr_path = "#{__dir__}/resources/future_annual_co2e.csv"
    his_yr_path = "#{__dir__}/resources/historical_annual_co2e.csv"

    # find external files
    if ((File.exist?(fut_hr_path)) and (File.exist?(fut_yr_path)) and (File.exist?(his_hr_path)) and (File.exist?(his_yr_path)))
      fut_hr_file = OpenStudio::Model::ExternalFile.getExternalFile(model, fut_hr_path)
      his_hr_file = OpenStudio::Model::ExternalFile.getExternalFile(model, his_hr_path)
      fut_yr_file = OpenStudio::Model::ExternalFile.getExternalFile(model, fut_yr_path)
      his_yr_file = OpenStudio::Model::ExternalFile.getExternalFile(model, his_yr_path)
      if ((fut_hr_file.is_initialized) and (his_hr_file.is_initialized) and (fut_yr_file.is_initialized) and (his_yr_file.is_initialized))
        fut_hr_file = fut_hr_file.get
        his_hr_file = his_hr_file.get
        fut_yr_file = fut_yr_file.get
        his_yr_file = his_yr_file.get
        fut_hr_data = CSV.read(fut_hr_path, headers: true)
        his_hr_data = CSV.read(his_hr_path, headers: true)
        fut_yr_data = CSV.read(fut_yr_path, headers: true)
        his_yr_data = CSV.read(his_yr_path, headers: true)
      end
    else
      runner.registerError("Could not find CSV file at one of more of the following paths: #{fut_hr_path}, #{his_hr_path}, #{fut_yr_path}, or #{his_yr_path}")
      return false
    end

    # add schedule type limits for schedule file
    lim_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
    lim_type.setName('Emissions Sch File Type Limits')

    # add future schedule file
    sch_file = OpenStudio::Model::ScheduleFile.new(fut_hr_file)
    sch_file.setName("#{future_subregion} #{future_year} Future Hourly Emissions Sch")
    sch_file.setScheduleTypeLimits(lim_type)
    sch_file.setColumnNumber(fut_hr_data.headers.index(future_subregion) + 1)
    sch_file.setRowstoSkipatTop(1)
    sch_file.setNumberofHoursofData(8760)
    sch_file.setColumnSeparator('Comma')
    sch_file.setInterpolatetoTimestep(false)
    sch_file.setMinutesperItem(60)

    # add historical schedule file
    sch_file = OpenStudio::Model::ScheduleFile.new(his_hr_file)
    sch_file.setName("#{hourly_historical_subregion} #{hourly_historical_year} Historical Hourly Emissions Sch")
    sch_file.setScheduleTypeLimits(lim_type)
    sch_file.setColumnNumber(his_hr_data.headers.index(hourly_historical_subregion) + 1)
    sch_file.setRowstoSkipatTop(1)
    sch_file.setNumberofHoursofData(8760)
    sch_file.setColumnSeparator('Comma')
    sch_file.setInterpolatetoTimestep(false)
    sch_file.setMinutesperItem(60)

    # add EMS sensor for future schedule file
    sch_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    sch_sens.setKeyName("#{future_subregion} #{future_year} Future Hourly Emissions Sch")
    sch_sens.setName('Fut_Sen')

    # add EMS sensor for historical schedule file
    sch_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    sch_sens.setKeyName("#{hourly_historical_subregion} #{hourly_historical_year} Historical Hourly Emissions Sch")
    sch_sens.setName('His_Sen')

    # add whole-building electricity sensor
    sch_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Facility Total Purchased Electricity Energy')
    sch_sens.setKeyName('Whole Building')
    sch_sens.setName('Ele_Sen')

    ems_prgm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ems_prgm.setName('Emissions_Calc_Prgm')
    ems_prgm.addLine('SET fut_hr_val = Fut_Sen')
    ems_prgm.addLine('SET his_hr_val = His_Sen')
    fut_yr_data.each {|r| ems_prgm.addLine("SET fut_yr_val = #{r[future_subregion]}") if r[0].to_i == future_year}
    his_yr_data.each {|r| ems_prgm.addLine("SET his_yr_val = #{r[annual_historical_subregion]}") if r[0].to_i == annual_historical_year}
    ems_prgm.addLine('SET elec = Ele_Sen')
    ems_prgm.addLine('SET conv = 1000000 * 60 * 60') # J to MWh (1000000J/MJ * 60hr/min * 60 min/sec)
    ems_prgm.addLine('SET fut_hr = fut_hr_val * elec / conv')
    ems_prgm.addLine('SET his_hr = his_hr_val * elec / conv')
    ems_prgm.addLine('SET fut_yr = fut_yr_val * elec / conv')
    ems_prgm.addLine('SET his_yr = his_yr_val * elec / conv')

    # add EMS program calling manager
    mgr_prgm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    mgr_prgm.setName('Emissions Calc Prgm')
    mgr_prgm.setCallingPoint('EndOfSystemTimestepBeforeHVACReporting')
    mgr_prgm.setProgram(ems_prgm, 0)

    # add future hourly EMS output variable
    ems_var1 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'fut_hr')
    ems_var1.setName("#{future_subregion}_#{future_year}_Hourly_Emissions_Var")
    ems_var1.setEMSVariableName('fut_hr')
    ems_var1.setTypeOfDataInVariable('Summed')
    ems_var1.setUpdateFrequency('SystemTimestep')
    ems_var1.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var1.setUnits('kg')

    # add historical hourly EMS output variable
    ems_var2 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'his_hr')
    ems_var2.setName("#{hourly_historical_subregion.gsub(' ','_')}_#{hourly_historical_year}_Hourly_Emissions_Var")
    ems_var2.setEMSVariableName('his_hr')
    ems_var2.setTypeOfDataInVariable('Summed')
    ems_var2.setUpdateFrequency('SystemTimestep')
    ems_var2.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var2.setUnits('kg')

    # add future annual EMS output variable
    ems_var3 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'fut_yr')
    ems_var3.setName("#{future_subregion}_#{future_year}_Annual_Emissions_Var")
    ems_var3.setEMSVariableName('fut_yr')
    ems_var3.setTypeOfDataInVariable('Summed')
    ems_var3.setUpdateFrequency('SystemTimestep')
    ems_var3.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var3.setUnits('kg')

    # add historical annual EMS output variable
    ems_var4 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'his_yr')
    ems_var4.setName("#{annual_historical_subregion}_#{annual_historical_year}_Annual_Emissions_Var")
    ems_var4.setEMSVariableName('his_yr')
    ems_var4.setTypeOfDataInVariable('Summed')
    ems_var4.setUpdateFrequency('SystemTimestep')
    ems_var4.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var4.setUnits('kg')

    # add future hourly reporting output variable
    out_var1 = OpenStudio::Model::OutputVariable.new("#{future_subregion}_#{future_year}_Hourly_Emissions_Var", model)
    out_var1.setKeyValue('EMS')
    out_var1.setReportingFrequency('hourly')

    # add historical hourly reporting output variable
    out_var2 = OpenStudio::Model::OutputVariable.new("#{hourly_historical_subregion.gsub(' ','_')}_#{hourly_historical_year}_Hourly_Emissions_Var", model)
    out_var2.setKeyValue('EMS')
    out_var2.setReportingFrequency('hourly')

    # add future annual reporting output variable
    out_var3 = OpenStudio::Model::OutputVariable.new("#{future_subregion}_#{future_year}_Annual_Emissions_Var", model)
    out_var3.setKeyValue('EMS')
    out_var3.setReportingFrequency('hourly')

    # add historical annual reporting output variable
    out_var4 = OpenStudio::Model::OutputVariable.new("#{annual_historical_subregion}_#{annual_historical_year}_Annual_Emissions_Var", model)
    out_var4.setKeyValue('EMS')
    out_var4.setReportingFrequency('hourly')

    return true
  end
end

# register the measure to be used by the application
AddEMSEmissionsReporting.new.registerWithApplication
