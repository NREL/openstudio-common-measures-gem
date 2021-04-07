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

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class ImportEnvelopeAndInternalLoadsFromIdf < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ImportEnvelopeAndInternalLoadsFromIdf'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for external idf
    source_idf_path = OpenStudio::Measure::OSArgument.makeStringArgument('source_idf_path', true)
    source_idf_path.setDisplayName('External IDF File Name')
    source_idf_path.setDescription('Name of the IDF file to import objects from. This is the filename with the extension (e.g. MyModel.idf). Optionally this can inclucde the full file path, but for most use cases should just be file name.')
    args << source_idf_path

    # make an argument for importing site objects
    import_site_objects = OpenStudio::Measure::OSArgument.makeBoolArgument('import_site_objects', true)
    import_site_objects.setDisplayName('Import Site Shading.')
    # import_site_objects.setDisplayName("Import Site objects (site shading and exterior lights).")  # todo - use this once exterior lights are supported
    import_site_objects.setDefaultValue(true)
    args << import_site_objects

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    import_site_objects = runner.getBoolArgumentValue('import_site_objects', user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    source_idf_path = runner.getStringArgumentValue('source_idf_path', user_arguments)

    # find source_idf_path
    osw_file = runner.workflow.findFile(source_idf_path)
    if osw_file.is_initialized
      source_idf_path = osw_file.get.to_s
    else
      runner.registerError("Did not find #{source_idf_path} in paths described in OSW file.")
      return false
    end

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")

    # translate IDF file to OSM
    workspace = OpenStudio::Workspace.load(OpenStudio::Path.new(source_idf_path))
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    model2 = rt.translateWorkspace(workspace.get)

    # remove original building
    building = model.getBuilding
    building.remove

    # clone in building from IDF
    building2 = model2.getBuilding
    building2.clone(model)

    # hash of old and new thermostats
    thermostatOldNewHash = {}

    # cloning thermostats
    thermostats = model2.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      newThermostat = thermostat.clone(model)
      # populate hash
      thermostatOldNewHash[thermostat] = newThermostat
    end

    # loop through thermal zone to match old to new and assign thermostat
    thermalZonesOld = model2.getThermalZones
    thermalZonesNew = model.getThermalZones
    thermalZonesOld.each do |thermalZoneOld|
      thermalZonesNew.each do |thermalZoneNew|
        if thermalZoneOld.name.to_s == thermalZoneNew.name.to_s
          # wire thermal zone to thermostat
          if !thermalZoneOld.thermostatSetpointDualSetpoint.empty?
            thermostatOld = thermalZoneOld.thermostatSetpointDualSetpoint.get
            thermalZoneNew.setThermostatSetpointDualSetpoint(thermostatOldNewHash[thermostatOld].to_ThermostatSetpointDualSetpoint.get)
          end
          next
        end
      end
    end

    # fix for space type and thermal zone connections
    spaces = model.getSpaces
    spaces.each do |space|
      thermalZonesNew.each do |zone|
        # since I know the names here I can look for match, but this work around only works with imported IDF's where names are known
        if zone.name.to_s == "#{space.name} Thermal Zone"
          space.setThermalZone(zone)
        end
      end
    end

    # TODO: - surface matching is also messed up, but I'll add a stand alone measure for that vs. adding it here.

    # import site objects if requested
    if import_site_objects

      # TODO: - this doesn't do anything because exterior lights don't make it through reverse translation
      # get exterior lights
      facility = model2.getFacility
      exteriorLights = facility.exteriorLights
      exteriorLights.each do |exteriorLight|
        exteriorLight.clone(model)
        runner.registerInfo("Cloning exterior light #{exteriorLight.name} into model.")
      end

      # get site shading
      shadingSurfaceGroups = model2.getShadingSurfaceGroups
      shadingSurfaceGroups.each do |group|
        if group.shadingSurfaceType == 'Site'
          group.clone(model)
          runner.registerInfo("Cloning shading group #{group.name} into model.")
        end
      end

    end

    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")

    # TODO: - see if SHW comes in, if not think of solution

    return true
  end
end

# this allows the measure to be use by the application
ImportEnvelopeAndInternalLoadsFromIdf.new.registerWithApplication
