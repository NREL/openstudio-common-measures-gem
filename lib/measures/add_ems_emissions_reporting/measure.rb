# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
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
    future_subregion_chs = OpenStudio::StringVector.new
    future_subregion_chs << 'AZNMc'
    future_subregion_chs << 'CAMXc'
    future_subregion_chs << 'ERCTc'
    future_subregion_chs << 'FRCCc'
    future_subregion_chs << 'MROEc'
    future_subregion_chs << 'MROWc'
    future_subregion_chs << 'NEWEc'
    future_subregion_chs << 'NWPPc'
    future_subregion_chs << 'NYSTc'
    future_subregion_chs << 'RFCEc'
    future_subregion_chs << 'RFCMc'
    future_subregion_chs << 'RFCWc'
    future_subregion_chs << 'RMPAc'
    future_subregion_chs << 'SPNOc'
    future_subregion_chs << 'SPSOc'
    future_subregion_chs << 'SRMVc'
    future_subregion_chs << 'SRMWc'
    future_subregion_chs << 'SRSOc'
    future_subregion_chs << 'SRTVc'
    future_subregion_chs << 'SRVCc'

    future_subregion = OpenStudio::Measure::OSArgument.makeChoiceArgument('future_subregion', future_subregion_chs, true)
    future_subregion.setDisplayName('Future subregion')
    future_subregion.setDescription('Future subregion. Options are: AZNMc, CAMXc, ERCTc, FRCCc, MROEc, MROWc, NEWEc, NWPPc, NYSTc, RFCEc, RFCMc, RFCWc, RMPAc, SPNOc, SPSOc, SRMVc, SRMWc, SRSOc, SRTVc, and SRVCc')
    future_subregion.setDefaultValue('RMPAc')
    args << future_subregion

    # historical hourly subregion
    hourly_historical_subregion_chs = OpenStudio::StringVector.new
    hourly_historical_subregion_chs << 'California'
    hourly_historical_subregion_chs << 'Carolinas'
    hourly_historical_subregion_chs << 'Central'
    hourly_historical_subregion_chs << 'Florida'
    hourly_historical_subregion_chs << 'Mid-Atlantic'
    hourly_historical_subregion_chs << 'Midwest'
    hourly_historical_subregion_chs << 'New England'
    hourly_historical_subregion_chs << 'New York'
    hourly_historical_subregion_chs << 'Northwest'
    hourly_historical_subregion_chs << 'Rocky Mountains'
    hourly_historical_subregion_chs << 'Southeast'
    hourly_historical_subregion_chs << 'Southwest'
    hourly_historical_subregion_chs << 'Tennessee'
    hourly_historical_subregion_chs << 'Texas'

    hourly_historical_subregion = OpenStudio::Measure::OSArgument.makeChoiceArgument('hourly_historical_subregion', hourly_historical_subregion_chs,  true)
    hourly_historical_subregion.setDisplayName('Historical hourly subregion')
    hourly_historical_subregion.setDescription('Historical hourly subregion. Options are: California, Carolinas, Central, Florida, Mid-Atlantic, Midwest, New England, New York, Northwest, Rocky Mountains, Southeast, Southwest, Tennessee, and Texas')
    hourly_historical_subregion.setDefaultValue('Rocky Mountains')
    args << hourly_historical_subregion

    # historical annual subregion
    annual_historical_subregion_chs = OpenStudio::StringVector.new
    annual_historical_subregion_chs << 'AKGD'
    annual_historical_subregion_chs << 'AKMS'
    annual_historical_subregion_chs << 'AZNM'
    annual_historical_subregion_chs << 'CAMX'
    annual_historical_subregion_chs << 'ERCT'
    annual_historical_subregion_chs << 'FRCC'
    annual_historical_subregion_chs << 'HIMS'
    annual_historical_subregion_chs << 'HIOA'
    annual_historical_subregion_chs << 'MROE'
    annual_historical_subregion_chs << 'MROW'
    annual_historical_subregion_chs << 'NEWE'
    annual_historical_subregion_chs << 'NWPP'
    annual_historical_subregion_chs << 'NYCW'
    annual_historical_subregion_chs << 'NYLI'
    annual_historical_subregion_chs << 'NYUP'
    annual_historical_subregion_chs << 'RFCE'
    annual_historical_subregion_chs << 'RFCM'
    annual_historical_subregion_chs << 'RFCW'
    annual_historical_subregion_chs << 'RMPA'
    annual_historical_subregion_chs << 'SPNO'
    annual_historical_subregion_chs << 'SPSO'
    annual_historical_subregion_chs << 'SRMV'
    annual_historical_subregion_chs << 'SRMW'
    annual_historical_subregion_chs << 'SRSO'
    annual_historical_subregion_chs << 'SRTV'
    annual_historical_subregion_chs << 'SRVC'

    annual_historical_subregion = OpenStudio::Measure::OSArgument.makeChoiceArgument('annual_historical_subregion', annual_historical_subregion_chs, true)
    annual_historical_subregion.setDisplayName('Historical annual subregion')
    annual_historical_subregion.setDescription('Historical annual subregion. Options are: AKGD, AKMS, AZNM, CAMX, ERCT, FRCC, HIMS, HIOA, MROE, MROW, NEWE, NWPP, NYCW, NYLI, NYUP, RFCE, RFCM, RFCW, RMPA, SPNO, SPSO, SRMV, SRMW, SRSO, SRTV, and SRVC')
    annual_historical_subregion.setDefaultValue('RMPA')
    args << annual_historical_subregion

    # future year
    future_year_chs = OpenStudio::StringVector.new
    future_year_chs << '2020'
    future_year_chs << '2022'
    future_year_chs << '2024'
    future_year_chs << '2026'  
    future_year_chs << '2028'
    future_year_chs << '2030'
    future_year_chs << '2032'
    future_year_chs << '2034'
    future_year_chs << '2036'
    future_year_chs << '2038'
    future_year_chs << '2040'
    future_year_chs << '2042'
    future_year_chs << '2044'
    future_year_chs << '2046'
    future_year_chs << '2048'
    future_year_chs << '2050'


    future_year = OpenStudio::Measure::OSArgument.makeChoiceArgument('future_year', future_year_chs, true)
    future_year.setDisplayName('Future Year')
    future_year.setDescription('Future Year. Options are: 2020 to 2050 in two year increments')
    future_year.setDefaultValue('2020')
    args << future_year

    # hourly historical year
    hourly_historical_year_chs = OpenStudio::StringVector.new
    hourly_historical_year_chs << '2019'

    hourly_historical_year = OpenStudio::Measure::OSArgument.makeChoiceArgument('hourly_historical_year', hourly_historical_year_chs, true)
    hourly_historical_year.setDisplayName('Hourly Historical Year')
    hourly_historical_year.setDescription('Hourly Historical Year. Options are: 2019.')
    hourly_historical_year.setDefaultValue('2019')
    args << hourly_historical_year

    # annual historical year
    annual_historical_year_chs = OpenStudio::StringVector.new
    annual_historical_year_chs << '2007'
    annual_historical_year_chs << '2009'
    annual_historical_year_chs << '2010'
    annual_historical_year_chs << '2012'  
    annual_historical_year_chs << '2014'
    annual_historical_year_chs << '2016'
    annual_historical_year_chs << '2018'
    annual_historical_year_chs << '2019'

    annual_historical_year = OpenStudio::Measure::OSArgument.makeChoiceArgument('annual_historical_year', annual_historical_year_chs, true)

    #puts "annual_historical_year  = #{annual_historical_year}"

    annual_historical_year.setDisplayName('Annual Historical Year')
    annual_historical_year.setDescription('Annual Historical Year. Options are: 2007, 2009, 2010, 2012, 2014, 2016, 2018, and 2019.')
    annual_historical_year.setDefaultValue('2019')
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
    future_year = runner.getStringArgumentValue('future_year', usr_args).to_i
    hourly_historical_year = runner.getStringArgumentValue('hourly_historical_year', usr_args).to_i
    annual_historical_year = runner.getStringArgumentValue('annual_historical_year', usr_args).to_i

    # log errors if users select arguments not supported by the measure
    arguments(model).each do |argument|

      case argument.name
      
      when 'future_subregion'
        if !argument.choiceValues.include? future_subregion
          runner.registerError("#{future_subregion} is not a valid option. Please select from of the following future_subregion options #{argument.choiceValues}")
        end
      when 'hourly_historical_subregion'
        if !argument.choiceValues.include? hourly_historical_subregion
          runner.registerError("#{hourly_historical_subregion} is not a valid option. Please select from of the following hourly_historical_subregion options #{argument.choiceValues}")
        end
      when 'annual_historical_subregion'
        if !argument.choiceValues.include? annual_historical_subregion
          runner.registerError("#{annual_historical_subregion} is not a valid option. Please select from of the following annual_historical_subregion options #{argument.choiceValues}")
        end
      when 'future_year'
        if !argument.choiceValues.include? future_year.to_s
          runner.registerError("#{future_year} is not a valid option. Please select from of the following future_year options #{argument.choiceValues}")
        end
      when 'hourly_historical_year'
        if !argument.choiceValues.include? hourly_historical_year.to_s
          runner.registerError("#{hourly_historical_year} is not a valid option. Please select from of the following hourly_historical_year options #{argument.choiceValues}")
        end
      when 'annual_historical_year'
        if !argument.choiceValues.include? annual_historical_year.to_s
          runner.registerError("#{annual_historical_year} is not a valid option. Please select from of the following annual_historical_year options #{argument.choiceValues}")
        end

      end

    end

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
    fut_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    fut_sens.setKeyName("#{future_subregion} #{future_year} Future Hourly Emissions Sch")
    fut_sens.setName('Fut_Sen')

    # add EMS sensor for historical schedule file
    his_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    his_sens.setKeyName("#{hourly_historical_subregion} #{hourly_historical_year} Historical Hourly Emissions Sch")
    his_sens.setName('His_Sen')

    # add whole-building electricity sensor
    ele_sens = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Facility Total Purchased Electricity Energy')
    ele_sens.setKeyName('Whole Building')
    ele_sens.setName('Ele_Sen')

    ems_prgm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ems_prgm.setName('Emissions_Calc_Prgm')
    ems_prgm.addLine('SET fut_hr_val = Fut_Sen')
    ems_prgm.addLine('SET his_hr_val = His_Sen')
    fut_yr_data.each {|r| ems_prgm.addLine("SET fut_yr_val = #{r[future_subregion]}") if r[0].to_i == future_year}
    his_yr_data.each {|r| ems_prgm.addLine("SET his_yr_val = #{r[annual_historical_subregion]}") if r[0].to_i == annual_historical_year}
    ems_prgm.addLine('SET elec = Ele_Sen')
    ems_prgm.addLine('SET conv = 1000000 * 60 * 60') # J to MWh (1000000J/MJ * 60hr/min * 60 min/sec)
    ems_prgm.addLine('SET conv_kg_mt = 0.001') # kg to metric ton
    ems_prgm.addLine('SET fut_hr = (fut_hr_val * elec / conv) * conv_kg_mt')
    ems_prgm.addLine('SET his_hr = (his_hr_val * elec / conv) * conv_kg_mt')
    ems_prgm.addLine('SET fut_yr = (fut_yr_val * elec / conv) * conv_kg_mt')
    ems_prgm.addLine('SET his_yr = (his_yr_val * elec / conv) * conv_kg_mt')


    #### add emissions intensity metric
    # get building from model 
    building = model.getBuilding
    floor_area = building.floorArea * 10.764 #change from m2 to ft2
    #add metric
    ems_prgm.addLine("SET fut_hr_intensity = fut_hr * 1000 / #{floor_area}") # unit: kg/ft2 - changed mt to kg
    ems_prgm.addLine("SET his_hr_intensity = his_hr * 1000 / #{floor_area}") # unit: kg/ft2 - changed mt to kg
    ems_prgm.addLine("SET fut_yr_intensity = fut_yr * 1000 / #{floor_area}") # unit: kg/ft2 - changed mt to kg
    ems_prgm.addLine("SET his_yr_intensity = his_yr * 1000 / #{floor_area}") # unit: kg/ft2 - changed mt to kg
    
    # add EMS program calling manager
    mgr_prgm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    mgr_prgm.setName('Emissions Calc Prgm')
    mgr_prgm.setCallingPoint('EndOfSystemTimestepBeforeHVACReporting')
    mgr_prgm.setProgram(ems_prgm, 0)

    # add future hourly EMS output variable
    ems_var1 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'fut_hr')
    ems_var1.setName('Future_Hourly_Electricity_Emissions')
    ems_var1.setEMSVariableName('fut_hr')
    ems_var1.setTypeOfDataInVariable('Summed')
    ems_var1.setUpdateFrequency('SystemTimestep')
    ems_var1.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var1.setUnits('mt')

    # add historical hourly EMS output variable
    ems_var2 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'his_hr')
    ems_var2.setName('Historical_Hourly_Electricity_Emissions')
    ems_var2.setEMSVariableName('his_hr')
    ems_var2.setTypeOfDataInVariable('Summed')
    ems_var2.setUpdateFrequency('SystemTimestep')
    ems_var2.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var2.setUnits('mt')

    # add future annual EMS output variable
    ems_var3 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'fut_yr')
    ems_var3.setName('Future_Annual_Electricity_Emissions')
    ems_var3.setEMSVariableName('fut_yr')
    ems_var3.setTypeOfDataInVariable('Summed')
    ems_var3.setUpdateFrequency('SystemTimestep')
    ems_var3.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var3.setUnits('mt')

    # add historical annual EMS output variable
    ems_var4 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'his_yr')
    ems_var4.setName('Historical_Annual_Electricity_Emissions')
    ems_var4.setEMSVariableName('his_yr')
    ems_var4.setTypeOfDataInVariable('Summed')
    ems_var4.setUpdateFrequency('SystemTimestep')
    ems_var4.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var4.setUnits('mt')


    ##### add emissions intensity 
    # add future hourly EMS output variable
    ems_var5 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'fut_hr_intensity')
    ems_var5.setName('Future_Hourly_Electricity_Emissions_Intensity')
    ems_var5.setEMSVariableName('fut_hr_intensity')
    ems_var5.setTypeOfDataInVariable('Summed')
    ems_var5.setUpdateFrequency('SystemTimestep')
    ems_var5.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var5.setUnits('kg/ft2')

    # add historical hourly EMS output variable
    ems_var6 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'his_hr_intensity')
    ems_var6.setName('Historical_Hourly_Electricity_Emissions_Intensity')
    ems_var6.setEMSVariableName('his_hr_intensity')
    ems_var6.setTypeOfDataInVariable('Summed')
    ems_var6.setUpdateFrequency('SystemTimestep')
    ems_var6.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var6.setUnits('kg/ft2')

    # add future annual EMS output variable
    ems_var7 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'fut_yr_intensity')
    ems_var7.setName('Future_Annual_Electricity_Emissions_Intensity')
    ems_var7.setEMSVariableName('fut_yr_intensity')
    ems_var7.setTypeOfDataInVariable('Summed')
    ems_var7.setUpdateFrequency('SystemTimestep')
    ems_var7.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var7.setUnits('kg/ft2')

    # add historical annual EMS output variable
    ems_var8 = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'his_yr_intensity')
    ems_var8.setName('Historical_Annual_Electricity_Emissions_Intensity')
    ems_var8.setEMSVariableName('his_yr_intensity')
    ems_var8.setTypeOfDataInVariable('Summed')
    ems_var8.setUpdateFrequency('SystemTimestep')
    ems_var8.setEMSProgramOrSubroutineName(ems_prgm)
    ems_var8.setUnits('kg/ft2')

    # add future hourly reporting output variable
    out_var1 = OpenStudio::Model::OutputVariable.new('Future_Hourly_Electricity_Emissions', model)
    out_var1.setKeyValue('EMS')
    out_var1.setReportingFrequency('hourly')

    # add historical hourly reporting output variable
    out_var2 = OpenStudio::Model::OutputVariable.new('Historical_Hourly_Electricity_Emissions', model)
    out_var2.setKeyValue('EMS')
    out_var2.setReportingFrequency('hourly')

    # add future annual reporting output variable
    out_var3 = OpenStudio::Model::OutputVariable.new('Future_Annual_Electricity_Emissions', model)
    out_var3.setKeyValue('EMS')
    out_var3.setReportingFrequency('hourly')

    # add historical annual reporting output variable
    out_var4 = OpenStudio::Model::OutputVariable.new('Historical_Annual_Electricity_Emissions', model)
    out_var4.setKeyValue('EMS')
    out_var4.setReportingFrequency('hourly')

    # add future hourly intensity reporting output variable
    out_var5 = OpenStudio::Model::OutputVariable.new('Future_Hourly_Electricity_Emissions_Intensity', model)
    out_var5.setKeyValue('EMS')
    out_var5.setReportingFrequency('hourly')

    # add historical hourly intensity reporting output variable
    out_var6 = OpenStudio::Model::OutputVariable.new('Historical_Hourly_Electricity_Emissions_Intensity', model)
    out_var6.setKeyValue('EMS')
    out_var6.setReportingFrequency('hourly')

    # add future annual intensity reporting output variable
    out_var7 = OpenStudio::Model::OutputVariable.new('Future_Annual_Electricity_Emissions_Intensity', model)
    out_var7.setKeyValue('EMS')
    out_var7.setReportingFrequency('hourly')

    # add historical annual intensity reporting output variable
    out_var8 = OpenStudio::Model::OutputVariable.new('Historical_Annual_Electricity_Emissions_Intensity', model)
    out_var8.setKeyValue('EMS')
    out_var8.setReportingFrequency('hourly')

    return true
  end
end

# register the measure to be used by the application
AddEMSEmissionsReporting.new.registerWithApplication
