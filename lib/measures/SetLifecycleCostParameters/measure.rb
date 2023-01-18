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

# see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for access to C++ documentation on mondel objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class SetLifecycleCostParameters < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'SetLifecycleCostParameters'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for your name
    study_period = OpenStudio::Measure::OSArgument.makeIntegerArgument('study_period', true)
    study_period.setDisplayName('Set the Length of the Study Period (years).')
    study_period.setDefaultValue(25)
    args << study_period

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    study_period = runner.getIntegerArgumentValue('study_period', user_arguments)

    # check the user_name for reasonableness
    if study_period < 1
      runner.registerError('Length of the Study Period needs to be an integer greater than 0.')
      return false
    end

    # get lifecycle object
    lifeCycleCostParameters = model.getLifeCycleCostParameters

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("Initial Lifecycle Analysis Type is #{lifeCycleCostParameters.analysisType}. Initial Analysis Length is #{lifeCycleCostParameters.lengthOfStudyPeriodInYears}.")

    # this will eventually be in the GUI, but just adding to measure for now
    lifeCycleCostParameters.setAnalysisType('FEMP')
    lifeCycleCostParameters.setLengthOfStudyPeriodInYears(study_period)

    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("Final Lifecycle Analysis Type is #{lifeCycleCostParameters.analysisType}. Final Analysis Length is #{lifeCycleCostParameters.lengthOfStudyPeriodInYears}.")

    return true
  end
end

# this allows the measure to be use by the application
SetLifecycleCostParameters.new.registerWithApplication
