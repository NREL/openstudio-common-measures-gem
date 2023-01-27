######################################################################
#  Copyright (c) 2008-2014, Alliance for Sustainable Energy.
#  All rights reserved.
#
#  This library is free software you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

class ReplaceModel < OpenStudio::Measure::ModelMeasure

  # override name to return the name of your script
  def name
    return "Replace OpenStudio Model"
  end

  # return a vector of arguments
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for external model
    external_model_name = OpenStudio::Measure::OSArgument::makeStringArgument("external_model_name",true)
    external_model_name.setDisplayName("External OSM File Name")
    external_model_name.setDescription("Name of the model to replalace current model. This is the filename with the extension (e.g. MyModel.osm). Optionally this can inclucde the full file path, but for most use cases should just be file name.")
    args << external_model_name

    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    if not runner.validateUserArguments(arguments(model),user_arguments)
      return false
    end

    runner.registerInitialCondition("Initial model had #{model.objects.size} objects.")

    external_model_name = runner.getStringArgumentValue("external_model_name",user_arguments)

    # find external model
    osw_file = runner.workflow.findFile(external_model_name)
    if osw_file.is_initialized
      external_model_name = osw_file.get.to_s
    else
      runner.registerError("Did not find #{external_model_name} in paths described in OSW file.")
      runner.registerInfo("Looked for #{external_model_name} in the following locations")
      runner.workflow.absoluteFilePaths.each do |path|
        runner.registerInfo("#{path}")
      end
      return false
    end

    translator = OpenStudio::OSVersion::VersionTranslator.new
    oModel = translator.loadModel(external_model_name)
    if oModel.empty?
      runner.registerError("Could not load alternative model from '" + external_model_name.to_s + "'.")
      return false
    end

    newModel = oModel.get

    # pull original weather file object over
    weatherFile = newModel.getOptionalWeatherFile
    if not weatherFile.empty?
      weatherFile.get.remove
    end
    originalWeatherFile = model.getOptionalWeatherFile
    if not originalWeatherFile.empty?
      originalWeatherFile.get.clone(newModel)
    end
    runner.registerInfo("Replacing alternate model's weather file object.")

    # pull original design days over
    newModel.getDesignDays.each { |designDay|
      designDay.remove
    }
    model.getDesignDays.each { |designDay|
      designDay.clone(newModel)
    }
    runner.registerInfo("Replacing alternate model's design day objects.")

    # pull over original water main temps
    newModel.getSiteWaterMainsTemperature.remove
    model.getSiteWaterMainsTemperature.clone(newModel)
    runner.registerInfo("Replacing alternate model's water main temperature object.")

    # pull over original climate zone
    newModel.getClimateZones.remove
    model.getClimateZones.clone(newModel)
    runner.registerInfo("Replacing alternate model's ASHRAE Climate Zone.")

    # swap underlying data in model with underlying data in newModel
    # model = newModel DOES NOT work
    # model.swap(newModel) IS NOT reliable
    
    # alternative swap
    # remove existing objects from model
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    model.removeObjects(handles)
    # add new file to empty model
    model.addObjects( newModel.toIdfFile.objects )

    runner.registerInfo("All other characteristics of alternate model are being brought over including rotation, building, site shading, exterior lights, simulation settings, and output variables requests.")

    runner.registerFinalCondition("Model replaced with alternative #{external_model_name}. Weather file, design days, water main temps, and climate zones are retained from original. Final model has #{model.objects.size} objects.")

    return true
  end

end

#this allows the measure to be used by the application
ReplaceModel.new.registerWithApplication
