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
    return 'This measure reports emissions based on user-provided CSVs.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure uses EnergyPlus\' Energy Management System to log and report emissions based on user provided CSV file(s).'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    csv_path = OpenStudio::Measure::OSArgument.makeStringArgument('csv_path', true)
    csv_path.setDisplayName('Hourly emissions CSV path')
    csv_path.setDescription('Path to CSV which contains hourly emissions information')
    args << csv_path
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_args)
    super(model, runner, user_args)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_args)

    # assign the user inputs to variables
    csv_path = runner.getStringArgumentValue('csv_path', usr_args)

    # find external file
    csv_file = runner.workflow.findFile(csv_path)
    if csv_file.is_initialized
        csv = CSV.read(csv_file.get.to_s, headers:true)
    else
      runner.registerError("Did not find #{csv_path} in paths described in OSW file.")
      runner.registerInfo("Looked for #{csv_path} in the following locations")
      runner.workflow.absoluteFilePaths.each {|path| runner.registerInfo("#{path}")}
      return false
    end

    return true
  end
end

# register the measure to be used by the application
AddEMSEmissionsReporting.new.registerWithApplication
