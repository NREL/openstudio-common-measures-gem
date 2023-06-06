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

class XcelEDAReportingandQAQC < OpenStudio::Measure::ReportingMeasure
  # add electric heat rejection to electric cooling
  # add fans and lights? compare fans and cooling - greater than 5x different during peak cooling month - helps identify bad chiller curves

  # energy use for cooling and heating as percentage of total energy
  def enduse_pcts_check
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Energy Enduses Check')
    check_elems << OpenStudio::Attribute.new('category', 'Xcel EDA')
    check_elems << OpenStudio::Attribute.new('description', 'Check that heating and cooling energy make up the expected percentage of total energy consumption')

    # aggregators to hold the values
    electricity_cooling = 0
    natural_gas_cooling = 0
    other_fuel_cooling = 0
    total_site_energy = 0
    electricity_heating = 0
    natural_gas_heating = 0
    other_fuel_heating = 0

    # make sure all required data are available
    if @sql.electricityCooling.is_initialized
      electricity_cooling = @sql.electricityCooling.get
    end
    if @sql.naturalGasCooling.is_initialized
      natural_gas_cooling = @sql.naturalGasCooling.get
    end
    if @sql.totalSiteEnergy.is_initialized
      total_site_energy = @sql.totalSiteEnergy.get
    end
    if @sql.electricityHeating.is_initialized
      electricity_heating = @sql.electricityHeating.get
    end
    if @sql.naturalGasHeating.is_initialized
      natural_gas_heating = @sql.naturalGasHeating.get
    end

    other_fuels = ['gasoline', 'diesel', 'coal', 'fuelOilNo1', 'fuelOilNo2', 'propane', 'otherFuel1', 'otherFuel2']
    other_fuel_cooling = 0.0
    other_fuels.each do |fuel|
      other_energy = @sql.instance_eval(fuel + 'Cooling')
      if other_energy.is_initialized
        # sum up all of the "other" fuels
        other_fuel_cooling += other_energy.get
      end
    end
    other_fuel_heating = 0.0
    other_fuels.each do |fuel|
      other_energy = @sql.instance_eval(fuel + 'Heating')
      if other_energy.is_initialized
        # sum up all of the "other" fuels
        other_fuel_heating += other_energy.get
      end
    end

    # if @sql.otherFuelCooling.is_initialized
      # other_fuel_cooling = @sql.otherFuelCooling.get
    # end
    # if @sql.otherFuelHeating.is_initialized
      # other_fuel_heating = @sql.otherFuelHeating.get
    # end

    pct_cooling = (electricity_cooling + natural_gas_cooling + other_fuel_cooling) / total_site_energy
    pct_heating = (electricity_heating + natural_gas_heating + other_fuel_heating) / total_site_energy

    # flag if 0% < pct_cooling < 20%
    if (pct_cooling < 0.0) || (pct_cooling > 0.2)
      check_elems << OpenStudio::Attribute.new('flag', "Cooling energy = #{pct_cooling} of total energy use;  outside of 0%-20% range expected by Xcel EDA")
      @runner.registerWarning("Cooling energy = #{pct_cooling} of total energy use;  outside of 0%-20% range expected by Xcel EDA")
    end

    # flag if 30% < pct_heating < 50%
    if (pct_heating < 0.30) || (pct_heating > 0.50)
      check_elems << OpenStudio::Attribute.new('flag', "Heating energy = #{pct_heating} of total energy use; outside the 30%-50% range expected by Xcel EDA")
      @runner.registerWarning("Heating energy = #{pct_heating} of total energy use; outside the 30%-50% range expected by Xcel EDA")
    end

    check_elem = OpenStudio::Attribute.new('check', check_elems)

    return check_elem
  end
end
