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

# see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

# start the measure
class AddOutputDiagnostics < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Add Output Diagnostics'
  end

  # human readable description
  def description
    return 'Often the eplusout.err file may request output diagnostics. This measure can be used to add this to the IDF file. Re-run your project to see the requested output.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Makes Output:Diagnostics object with choice list for optional values:, DisplayAllWarnings, DisplayExtraWarnings, DisplayUnusedSchedules, DisplayUnusedObjects, DisplayAdvancedReportVariables, DisplayZoneAirHeatBalanceOffBalance, DoNotMirrorDetachedShading, DisplayWeatherMissingDataWarnings, ReportDuringWarmup, ReportDetailedWarmupConvergence.'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make choice argument for output diagnostic value
    choices = OpenStudio::StringVector.new
    choices << 'DisplayAllWarnings'
    choices << 'DisplayExtraWarnings'
    choices << 'DisplayUnusedSchedules'
    choices << 'DisplayUnusedObjects'
    choices << 'DisplayAdvancedReportVariables'
    choices << 'DisplayZoneAirHeatBalanceOffBalance'
    choices << 'DoNotMirrorDetachedShading'
    choices << 'DisplayWeatherMissingDataWarnings'
    choices << 'ReportDuringWarmup'
    choices << 'ReportDetailedWarmupConvergence'
    outputDiagnostic = OpenStudio::Measure::OSArgument.makeChoiceArgument('outputDiagnostic', choices, true)
    outputDiagnostic.setDisplayName('Output Diagnostic Value')
    outputDiagnostic.setDefaultValue('DisplayExtraWarnings')
    args << outputDiagnostic

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
    outputDiagnostic = runner.getStringArgumentValue('outputDiagnostic', user_arguments)

    # reporting initial condition of model
    starting_objects = workspace.getObjectsByType('Output:Diagnostics'.to_IddObjectType)
    runner.registerInitialCondition("The model started with #{starting_objects.size} Output:Diagnostic objects.")

    # loop through existing objects to see if value of any already matches the requested value.
    object_exists = false
    starting_objects.each do |object|
      if object.getString(0).to_s == outputDiagnostic
        object_exists = true
      end
    end

    # adding a new Output:Diagnostic object of requested value if it doesn't already exist
    if object_exists == false

      # make new string
      new_diagnostic_string = "
      Output:Diagnostics,
        #{outputDiagnostic};    !- Key 1
        "

      # make new object from string
      idfObject = OpenStudio::IdfObject.load(new_diagnostic_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_diagnostic = wsObject.get

      runner.registerInfo("An output diagnostic object with a value of #{new_diagnostic.getString(0)} has been added to your model.")

    else
      runner.registerAsNotApplicable("An output diagnostic object with a value of #{new_diagnostic.getString(0)} already existed in your model. Nothing was changed.")
      return true

    end

    # reporting final condition of model
    finishing_objects = workspace.getObjectsByType('Output:Diagnostics'.to_IddObjectType)
    runner.registerFinalCondition("The model finished with #{finishing_objects.size} Output:Diagnostic objects.")

    return true
  end
end

# this allows the measure to be use by the application
AddOutputDiagnostics.new.registerWithApplication
