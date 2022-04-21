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

module OsLib_QAQC
  # include any general notes about QAQC method here

  # checks the number of unmet hours in the model
  # todo - do I need unique tolerance ranges for conductance, reflectance, and shgc
  def check_envelope_conductance(category, target_standard, min_pass, max_pass, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Envelope R-Value')
    check_elems << OpenStudio::Attribute.new('category', category)
    if target_standard == 'ICC IECC 2015'
      dislay_standard = target_standard
      check_elems << OpenStudio::Attribute.new('description', "Check envelope against Table R402.1.2 and R402.1.4 in #{dislay_standard} Residential Provisions.")
    elsif target_standard.include?('90.1-2013')
      display_standard = "ASHRAE #{target_standard}"
      check_elems << OpenStudio::Attribute.new('description', "Check envelope against #{display_standard} Table 5.5.2, Table G2.1.5 b,c,d,e, Section 5.5.3.1.1a. Roof reflectance of 55%, wall relfectance of 30%.")
    else
      # TODO: - could add more elsifs if want to dsiplay tables and sections for additional 90.1 standards
      if target_standard.include?('90.1')
        display_standard = "ASHRAE #{target_standard}"
      else
        display_standard = target_standard
      end
      check_elems << OpenStudio::Attribute.new('description', "Check envelope against #{display_standard}. Roof reflectance of 55%, wall relfectance of 30%.")
    end
    check_elems << OpenStudio::Attribute.new('min_pass', min_pass * 100)
    check_elems << OpenStudio::Attribute.new('max_pass', max_pass * 100)
    
    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems.each do |elem|
        next if ['Double','Integer'].include? (elem.valueType.valueDescription)
        results << elem.valueAsString
      end
      return results
    end

    # list of surface types to identify for each space type for surfaces and sub-surfaces
    construction_type_array = []
    construction_type_array << ['ExteriorWall', 'SteelFramed']
    construction_type_array << ['ExteriorRoof', 'IEAD']
    construction_type_array << ['ExteriorFloor', 'Mass']
    construction_type_array << ['ExteriorDoor', 'Swinging']
    construction_type_array << ['ExteriorWindow', 'Metal framing (all other)']
    construction_type_array << ['Skylight', 'Glass with Curb']
    # overhead door doesn't show in list, or glass doo

    begin

      # setup standard
      std = Standard.build(target_standard)
        
      # gather building type for summary
      bt_cz = std.model_get_building_climate_zone_and_building_type(@model)
      building_type = bt_cz['building_type']
      climate_zone = bt_cz['climate_zone']
      prototype_prefix = "#{target_standard} #{building_type} #{climate_zone}"

      # loop through all space types used in the model
      @model.getSpaceTypes.each do |space_type|
        next if space_type.floorArea <= 0
        space_type_const_properties = {}
        construction_type_array.each do |const_type|
          # gather data for exterior wall
          intended_surface_type = const_type[0]
          standards_construction_type = const_type[1]
          space_type_const_properties[intended_surface_type] = {}
          data = std.space_type_get_construction_properties(space_type, intended_surface_type, standards_construction_type)
          if data.nil?
            puts "lookup for #{target_standard},#{intended_surface_type},#{standards_construction_type}"
            check_elems << OpenStudio::Attribute.new('flag', "Didn't find construction for #{standards_construction_type} #{intended_surface_type} for #{space_type.name}.")
          elsif intended_surface_type.include? 'ExteriorWall' || 'ExteriorFloor' || 'ExteriorDoor'
            space_type_const_properties[intended_surface_type]['u_value'] = data['assembly_maximum_u_value']
            space_type_const_properties[intended_surface_type]['reflectance'] = 0.30 # hard coded value
          elsif intended_surface_type.include? 'ExteriorRoof'
            space_type_const_properties[intended_surface_type]['u_value'] = data['assembly_maximum_u_value']
            space_type_const_properties[intended_surface_type]['reflectance'] = 0.55 # hard coded value
          else
            space_type_const_properties[intended_surface_type]['u_value'] = data['assembly_maximum_u_value']
            space_type_const_properties[intended_surface_type]['shgc'] = data['assembly_maximum_solar_heat_gain_coefficient']
          end
        end

        # make array of construction details for surfaces
        surface_details = []
        missing_surface_constructions = []
        sub_surface_details = []
        missing_sub_surface_constructions = []

        # loop through spaces
        space_type.spaces.each do |space|
          space.surfaces.each do |surface|
            next if surface.outsideBoundaryCondition != 'Outdoors'
            if surface.construction.is_initialized
              surface_details << { boundary_condition: surface.outsideBoundaryCondition, surface_type: surface.surfaceType, construction: surface.construction.get }
            else
              missing_constructions << surface.name.get
            end

            # make array of construction details for sub_surfaces
            surface.subSurfaces.each do |sub_surface|
              if sub_surface.construction.is_initialized
                sub_surface_details << { boundary_condition: sub_surface.outsideBoundaryCondition, surface_type: sub_surface.subSurfaceType, construction: sub_surface.construction.get }
              else
                missing_constructions << sub_surface.name.get
              end
            end
          end
        end

        if !missing_surface_constructions.empty?
          check_elems << OpenStudio::Attribute.new('flag', "#{missing_constructions.size} surfaces are missing constructions in #{space_type.name}.")
        end

        if !missing_sub_surface_constructions.empty?
          check_elems << OpenStudio::Attribute.new('flag', "#{missing_constructions.size} sub surfaces are missing constructions in #{space_type.name}.")
        end

        # gather targer values for this space type
        # todo - address support for other surface types e.g. overhead door glass door
        target_r_value_ip = {}
        target_reflectance = {}
        target_u_value_ip = {}
        target_shgc = {}
        target_r_value_ip['Wall'] = 1.0 / space_type_const_properties['ExteriorWall']['u_value'].to_f
        target_reflectance['Wall'] = space_type_const_properties['ExteriorWall']['reflectance'].to_f
        target_r_value_ip['RoofCeiling'] = 1.0 / space_type_const_properties['ExteriorRoof']['u_value'].to_f
        target_reflectance['RoofCeiling'] = space_type_const_properties['ExteriorRoof']['reflectance'].to_f
        target_r_value_ip['Floor'] = 1.0 / space_type_const_properties['ExteriorFloor']['u_value'].to_f
        target_reflectance['Floor'] = space_type_const_properties['ExteriorFloor']['reflectance'].to_f
        target_r_value_ip['Door'] = 1.0 / space_type_const_properties['ExteriorDoor']['u_value'].to_f
        target_reflectance['Door'] = space_type_const_properties['ExteriorDoor']['reflectance'].to_f
        target_u_value_ip['FixedWindow'] = space_type_const_properties['ExteriorWindow']['u_value'].to_f
        target_shgc['FixedWindow'] = space_type_const_properties['ExteriorWindow']['shgc'].to_f
        target_u_value_ip['OperableWindow'] = space_type_const_properties['ExteriorWindow']['u_value'].to_f
        target_shgc['OperableWindow'] = space_type_const_properties['ExteriorWindow']['shgc'].to_f
        target_u_value_ip['Skylight'] = space_type_const_properties['Skylight']['u_value'].to_f
        target_shgc['Skylight'] = space_type_const_properties['Skylight']['shgc'].to_f

        # loop through unique construction arary combinations
        surface_details.uniq.each do |surface_detail|
          if surface_detail[:construction].thermalConductance.is_initialized

            # don't use intened surface type of construction, look map based on surface type and boundary condition
            boundary_condition = surface_detail[:boundary_condition]
            surface_type = surface_detail[:surface_type]
            intended_surface_type = ''
            if boundary_condition.to_s == 'Outdoors'
              if surface_type.to_s == 'Wall' then intended_surface_type = 'ExteriorWall' end
              if surface_type == 'RoofCeiling' then intended_surface_type = 'ExteriorRoof' end
              if surface_type == 'Floor' then intended_surface_type = 'ExteriorFloor' end
            else
              # currently only used for surfaces with outdoor boundary condition
            end
            film_coefficients_r_value = std.film_coefficients_r_value(intended_surface_type, includes_int_film = true, includes_ext_film = true)
            thermal_conductance = surface_detail[:construction].thermalConductance.get
            r_value_with_film = 1 / thermal_conductance + film_coefficients_r_value
            source_units = 'm^2*K/W'
            target_units = 'ft^2*h*R/Btu'
            r_value_ip = OpenStudio.convert(r_value_with_film, source_units, target_units).get
            solar_reflectance = surface_detail[:construction].to_LayeredConstruction.get.layers[0].to_OpaqueMaterial.get.solarReflectance .get # TODO: - check optional first does what happens with ext. air wall

            # stop if didn't find values (0 or infinity)
            next if target_r_value_ip[surface_detail[:surface_type]] == 0.0
            next if target_r_value_ip[surface_detail[:surface_type]] == Float::INFINITY

            # check r avlues
            if r_value_ip < target_r_value_ip[surface_detail[:surface_type]] * (1.0 - min_pass)
              check_elems << OpenStudio::Attribute.new('flag', "R value of #{r_value_ip.round(2)} (#{target_units}) for #{surface_detail[:construction].name} in #{space_type.name} is more than #{min_pass * 100} % below the value of #{target_r_value_ip[surface_detail[:surface_type]].round(2)} (#{target_units}) for #{prototype_prefix}.")
            elsif r_value_ip > target_r_value_ip[surface_detail[:surface_type]] * (1.0 + max_pass)
              check_elems << OpenStudio::Attribute.new('flag', "R value of #{r_value_ip.round(2)} (#{target_units}) for #{surface_detail[:construction].name} in #{space_type.name} is more than #{max_pass * 100} % above the value of #{target_r_value_ip[surface_detail[:surface_type]].round(2)} (#{target_units}) for #{prototype_prefix}.")
            end

            # check solar reflectance
            if (solar_reflectance < target_reflectance[surface_detail[:surface_type]] * (1.0 - min_pass)) && (target_standard != 'ICC IECC 2015')
              check_elems << OpenStudio::Attribute.new('flag', "Solar Reflectance of #{(solar_reflectance * 100).round} % for #{surface_detail[:construction].name} in #{space_type.name} is more than #{min_pass * 100} % below the value of #{(target_reflectance[surface_detail[:surface_type]] * 100).round} %.")
            elsif (solar_reflectance > target_reflectance[surface_detail[:surface_type]] * (1.0 + max_pass)) && (target_standard != 'ICC IECC 2015')
              check_elems << OpenStudio::Attribute.new('flag', "Solar Reflectance of #{(solar_reflectance * 100).round} % for #{surface_detail[:construction].name} in #{space_type.name} is more than #{max_pass * 100} % above the value of #{(target_reflectance[surface_detail[:surface_type]] * 100).round} %.")
            end

          else
            check_elems << OpenStudio::Attribute.new('flag', "Can't calculate R value for #{surface_detail[:construction].name}.")
          end
        end

        # loop through unique construction arary combinations
        sub_surface_details.uniq.each do |sub_surface_detail|
          if sub_surface_detail[:surface_type] == 'FixedWindow' || sub_surface_detail[:surface_type] == 'OperableWindow' || sub_surface_detail[:surface_type] == 'Skylight'
            # check for non opaque sub surfaces
            source_units = 'W/m^2*K'
            target_units = 'Btu/ft^2*h*R'
            u_factor_si = std.construction_calculated_u_factor(sub_surface_detail[:construction].to_LayeredConstruction.get.to_Construction.get)
            u_factor_ip = OpenStudio.convert(u_factor_si, source_units, target_units).get
            shgc = std.construction_calculated_solar_heat_gain_coefficient(sub_surface_detail[:construction].to_LayeredConstruction.get.to_Construction.get)

            # stop if didn't find values (0 or infinity)
            next if target_u_value_ip[sub_surface_detail[:surface_type]] == 0.0
            next if target_u_value_ip[sub_surface_detail[:surface_type]] == Float::INFINITY

            # check u avlues
            if u_factor_ip < target_u_value_ip[sub_surface_detail[:surface_type]] * (1.0 - min_pass)
              check_elems << OpenStudio::Attribute.new('flag', "U value of #{u_factor_ip.round(2)} (#{target_units}) for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{min_pass * 100} % below the value of #{target_u_value_ip[sub_surface_detail[:surface_type]].round(2)} (#{target_units}) for #{prototype_prefix}.")
            elsif u_factor_ip > target_u_value_ip[sub_surface_detail[:surface_type]] * (1.0 + max_pass)
              check_elems << OpenStudio::Attribute.new('flag', "U value of #{u_factor_ip.round(2)} (#{target_units}) for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{max_pass * 100} % above the value of #{target_u_value_ip[sub_surface_detail[:surface_type]].round(2)} (#{target_units}) for #{prototype_prefix}.")
            end

            # check shgc
            if shgc < target_shgc[sub_surface_detail[:surface_type]] * (1.0 - min_pass)
              check_elems << OpenStudio::Attribute.new('flag', "SHGC of #{shgc.round(2)} % for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{min_pass * 100} % below the value of #{target_shgc[sub_surface_detail[:surface_type]].round(2)} %.")
            elsif shgc > target_shgc[sub_surface_detail[:surface_type]] * (1.0 + max_pass)
              check_elems << OpenStudio::Attribute.new('flag', "SHGC of #{shgc.round(2)} % for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{max_pass * 100} % above the value of #{target_shgc[sub_surface_detail[:surface_type]].round(2)} %.")
            end

          else
            # check for opaque sub surfaces
            if sub_surface_detail[:construction].thermalConductance.is_initialized

              # don't use intened surface type of construction, look map based on surface type and boundary condition
              boundary_condition = sub_surface_detail[:boundary_condition]
              surface_type = sub_surface_detail[:surface_type]
              intended_surface_type = ''
              if boundary_condition.to_s == 'Outdoors'
                # TODO: add additional intended surface types
                if surface_type.to_s == 'Door' then intended_surface_type = 'ExteriorDoor' end
              else
                # currently only used for surfaces with outdoor boundary condition
              end
              film_coefficients_r_value = std.film_coefficients_r_value(intended_surface_type, includes_int_film = true, includes_ext_film = true)


              thermal_conductance = sub_surface_detail[:construction].thermalConductance.get
              r_value_with_film = 1 / thermal_conductance + film_coefficients_r_value
              source_units = 'm^2*K/W'
              target_units = 'ft^2*h*R/Btu'
              r_value_ip = OpenStudio.convert(r_value_with_film, source_units, target_units).get
              solar_reflectance = sub_surface_detail[:construction].to_LayeredConstruction.get.layers[0].to_OpaqueMaterial.get.solarReflectance .get # TODO: - check optional first does what happens with ext. air wall

              # stop if didn't find values (0 or infinity)
              next if target_r_value_ip[sub_surface_detail[:surface_type]] == 0.0
              next if target_r_value_ip[sub_surface_detail[:surface_type]] == Float::INFINITY

              # check r avlues
              if r_value_ip < target_r_value_ip[sub_surface_detail[:surface_type]] * (1.0 - min_pass)
                check_elems << OpenStudio::Attribute.new('flag', "R value of #{r_value_ip.round(2)} (#{target_units}) for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{min_pass * 100} % below the value of #{target_r_value_ip[sub_surface_detail[:surface_type]].round(2)} (#{target_units}) for #{prototype_prefix}.")
              elsif r_value_ip > target_r_value_ip[sub_surface_detail[:surface_type]] * (1.0 + max_pass)
                check_elems << OpenStudio::Attribute.new('flag', "R value of #{r_value_ip.round(2)} (#{target_units}) for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{max_pass * 100} % above the value of #{target_r_value_ip[sub_surface_detail[:surface_type]].round(2)} (#{target_units}) for #{prototype_prefix}.")
              end

              # check solar reflectance
              if (solar_reflectance < target_reflectance[sub_surface_detail[:surface_type]] * (1.0 - min_pass)) && (target_standard != 'ICC IECC 2015')
                check_elems << OpenStudio::Attribute.new('flag', "Solar Reflectance of #{(solar_reflectance * 100).round} % for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{min_pass * 100} % below #{(target_reflectance[sub_surface_detail[:surface_type]] * 100).round} %.")
              elsif (solar_reflectance > target_reflectance[sub_surface_detail[:surface_type]] * (1.0 + max_pass)) && (target_standard != 'ICC IECC 2015')
                check_elems << OpenStudio::Attribute.new('flag', "Solar Reflectance of #{(solar_reflectance * 100).round} % for #{sub_surface_detail[:construction].name} in #{space_type.name} is more than #{max_pass * 100} % above #{(target_reflectance[sub_surface_detail[:surface_type]] * 100).round} %.")
              end

            else
              check_elems << OpenStudio::Attribute.new('flag', "Can't calculate R value for #{sub_surface_detail[:construction].name}.")
            end

          end
        end
      end

      # check spaces without space types against Nonresidential for this climate zone
      @model.getSpaces.each do |space|
        if !space.spaceType.is_initialized

          # make array of construction details for surfaces
          surface_details = []
          missing_surface_constructions = []
          sub_surface_details = []
          missing_sub_surface_constructions = []

          space.surfaces.each do |surface|
            next if surface.outsideBoundaryCondition != 'Outdoors'
            if surface.construction.is_initialized
              surface_details << { boundary_condition: surface.outsideBoundaryCondition, surface_type: surface.surfaceType, construction: surface.construction.get }
            else
              missing_constructions << surface.name.get
            end

            # make array of construction details for sub_surfaces
            surface.subSurfaces.each do |sub_surface|
              if sub_surface.construction.is_initialized
                sub_surface_details << { boundary_condition: sub_surface.outsideBoundaryCondition, surface_type: sub_surface.subSurfaceType, construction: sub_surface.construction.get }
              else
                missing_constructions << sub_surface.name.get
              end
            end
          end

          if !missing_surface_constructions.empty?
            check_elems << OpenStudio::Attribute.new('flag', "#{missing_constructions.size} surfaces are missing constructions in #{space_type.name}. Spaces and can't be checked.")
          end

          if !missing_sub_surface_constructions.empty?
            check_elems << OpenStudio::Attribute.new('flag', "#{missing_constructions.size} sub surfaces are missing constructions in #{space_type.name}. Spaces and can't be checked.")
          end

          surface_details.uniq.each do |surface_detail|
            if surface_detail[:construction].thermalConductance.is_initialized
              # don't use intened surface type of construction, look map based on surface type and boundary condition
              boundary_condition = surface_detail[:boundary_condition]
              surface_type = surface_detail[:surface_type]
              intended_surface_type = ''
              if boundary_condition.to_s == 'Outdoors'
                if surface_type.to_s == 'Wall'
                  intended_surface_type = 'ExteriorWall'
                  standards_construction_type = 'SteelFramed'
                elsif surface_type == 'RoofCeiling'
                  intended_surface_type = 'ExteriorRoof'
                  standards_construction_type = 'IEAD'
                else surface_type == 'Floor'
                     intended_surface_type = 'ExteriorFloor'
                     standards_construction_type = 'Mass'
                end
              else
                # currently only used for surfaces with outdoor boundary condition
              end
              film_coefficients_r_value = std.film_coefficients_r_value(intended_surface_type, includes_int_film = true, includes_ext_film = true)


              thermal_conductance = surface_detail[:construction].thermalConductance.get
              r_value_with_film = 1 / thermal_conductance + film_coefficients_r_value
              source_units = 'm^2*K/W'
              target_units = 'ft^2*h*R/Btu'
              r_value_ip = OpenStudio.convert(r_value_with_film, source_units, target_units).get
              solar_reflectance = surface_detail[:construction].to_LayeredConstruction.get.layers[0].to_OpaqueMaterial.get.solarReflectance .get # TODO: - check optional first does what happens with ext. air wall

              # calculate target_r_value_ip
              target_reflectance = nil

              # model_get_construction_properties takes additional arguments now, maybe standard should update to add default
              building_type = std.model_get_standards_building_type(@model)
              construction_set_data = std.model_get_construction_set(building_type)
              building_type_category = construction_set_data['exterior_wall_building_category']

              data = std.model_get_construction_properties(@model, intended_surface_type, standards_construction_type, building_type_category)

              if data.nil?
                check_elems << OpenStudio::Attribute.new('flag', "Didn't find construction for #{standards_construction_type} #{intended_surface_type} for #{space.name}.")
                next
              elsif intended_surface_type.include? 'ExteriorWall' || 'ExteriorFloor' || 'ExteriorDoor'
                assembly_maximum_u_value = data['assembly_maximum_u_value']
                target_reflectance = 0.30
              elsif intended_surface_type.include? 'ExteriorRoof'
                assembly_maximum_u_value = data['assembly_maximum_u_value']
                target_reflectance = 0.55
              else
                assembly_maximum_u_value = data['assembly_maximum_u_value']
                assembly_maximum_solar_heat_gain_coefficient = data['assembly_maximum_solar_heat_gain_coefficient']
              end
              assembly_maximum_r_value_ip = 1 / assembly_maximum_u_value

              # stop if didn't find values (0 or infinity)
              next if assembly_maximum_r_value_ip == 0.0
              next if assembly_maximum_r_value_ip == Float::INFINITY

              # check r avlues
              if r_value_ip < assembly_maximum_r_value_ip * (1.0 - min_pass)
                check_elems << OpenStudio::Attribute.new('flag', "R value of #{r_value_ip.round(2)} (#{target_units}) for #{surface_detail[:construction].name} in #{space.name} is more than #{min_pass * 100} % below the value of #{assembly_maximum_r_value_ip.round(2)} (#{target_units}) for #{prototype_prefix}.")
              elsif r_value_ip > assembly_maximum_r_value_ip * (1.0 + max_pass)
                check_elems << OpenStudio::Attribute.new('flag', "R value of #{r_value_ip.round(2)} (#{target_units}) for #{surface_detail[:construction].name} in #{space.name} is more than #{max_pass * 100} % above the value of #{assembly_maximum_r_value_ip.round(2)} (#{target_units}) for #{prototype_prefix}.")
              end

              # check solar reflectance
              if (solar_reflectance < target_reflectance * (1.0 - min_pass)) && (target_standard != 'ICC IECC 2015')
                check_elems << OpenStudio::Attribute.new('flag', "Solar Reflectance of #{(solar_reflectance * 100).round} % for #{surface_detail[:construction].name} in #{space.name} is more than #{min_pass * 100} % below the value of #{(target_reflectance * 100).round} %.")
              elsif (solar_reflectance > target_reflectance * (1.0 + max_pass)) && (target_standard != 'ICC IECC 2015')
                check_elems << OpenStudio::Attribute.new('flag', "Solar Reflectance of #{(solar_reflectance * 100).round} % for #{surface_detail[:construction].name} in #{space.name} is more than #{max_pass * 100} % above the value of #{(target_reflectance * 100).round} %.")
              end
            else
              check_elems << OpenStudio::Attribute.new('flag', "Can't calculate R value for #{surface_detail[:construction].name}.")
            end
          end

          sub_surface_details.uniq.each do |sub_surface_detail|
            # TODO: update this so it works for doors and windows
            check_elems << OpenStudio::Attribute.new('flag', "Not setup to check sub-surfaces of spaces without space types. Can't check properties for #{sub_surface_detail[:construction].name}.")
          end

        end
      end
    rescue StandardError => e
      # brief description of ruby error
      check_elems << OpenStudio::Attribute.new('flag', "Error prevented QAQC check from running (#{e}).")

      # backtrace of ruby error for diagnostic use
      if @error_backtrace then check_elems << OpenStudio::Attribute.new('flag', e.backtrace.join("\n").to_s) end
    end

    # add check_elms to new attribute
    check_elem = OpenStudio::Attribute.new('check', check_elems)

    return check_elem
    # note: registerWarning and registerValue will be added for checks downstream using os_lib_reporting_qaqc.rb
  end
end
