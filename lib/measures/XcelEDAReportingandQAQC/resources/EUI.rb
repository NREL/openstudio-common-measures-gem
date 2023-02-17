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
  # can we use E+'s metric directly?  E+ will only use conditioned area
  # we need to incorporate building type into the range checking - ASHRAE Standard 100
  # how many hours did the @model run for? - make sure 8760 - get from html file

  # checks the EUI for the whole building
  def eui_check
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'EUI Check')
    check_elems << OpenStudio::Attribute.new('category', 'General')
    check_elems << OpenStudio::Attribute.new('description', 'Check that the EUI of the building is reasonable')

    building = @model.getBuilding

    # make sure all required data are available
    if @sql.totalSiteEnergy.empty?
      check_elems << OpenStudio::Attribute.new('flag', 'Site energy data unavailable; check not run')
      @runner.registerWarning('Site energy data unavailable; check not run')
    end

    total_site_energy_kBtu = OpenStudio.convert(@sql.totalSiteEnergy.get, 'GJ', 'kBtu').get
    if total_site_energy_kBtu == 0
      check_elems << OpenStudio::Attribute.new('flag', 'Model site energy use = 0; likely a problem with the model')
      @runner.registerWarning('Model site energy use = 0; likely a problem with the model')
    end

    floor_area_ft2 = OpenStudio.convert(building.floorArea, 'm^2', 'ft^2').get
    if floor_area_ft2 == 0
      check_elems << OpenStudio::Attribute.new('flag', 'The building has 0 floor area')
      @runner.registerWarning('The building has 0 floor area')
    end

    site_EUI = total_site_energy_kBtu / floor_area_ft2
    if site_EUI > 200
      check_elems << OpenStudio::Attribute.new('flag', "Site EUI of #{site_EUI} looks high.  A hospital or lab (high energy buildings) are around 200 kBtu/ft^2")
      @runner.registerWarning("Site EUI of #{site_EUI} looks high.  A hospital or lab (high energy buildings) are around 200 kBtu/ft^2")
    end
    if site_EUI < 30
      check_elems << OpenStudio::Attribute.new('flag', "Site EUI of #{site_EUI} looks low.  A high efficiency office building is around 50 kBtu/ft^2")
      @runner.registerWarning("Site EUI of #{site_EUI} looks low.  A high efficiency office building is around 50 kBtu/ft^2")
    end

    check_elem = OpenStudio::Attribute.new('check', check_elems)

    return check_elem
  end
 end
