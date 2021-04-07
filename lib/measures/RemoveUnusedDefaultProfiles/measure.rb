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

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class RemoveUnusedDefaultProfiles < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'RemoveUnusedDefaultProfiles'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # measure does not have any arguments

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # no user inputs assign to variables

    # reporting initial condition of model
    schedule_rulesets = model.getScheduleRulesets
    runner.registerInitialCondition("The model has #{schedule_rulesets.size} ScheduleRulesets.")

    # set start and end dates
    start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1)
    end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('December'), 31)
    # year does matter, but I'm not setting it here

    # counter for removed default profiles
    default_profiles_removed = 0

    # loop through all ScheduleRuleset objects
    schedule_rulesets.each do |schedule_ruleset|
      indices_vector = schedule_ruleset.getActiveRuleIndices(start_date, end_date)

      # line below lets you see the indices if for diagnostic purposes
      # runner.registerInfo("#{schedule_ruleset.name}: #{indices_vector}")

      if !indices_vector.include? -1

        runner.registerInfo("#{schedule_ruleset.name} does not used the default profile, it will be replaced.")

        # reset values in default ScheduleDay
        old_default_schedule_day = schedule_ruleset.defaultDaySchedule
        old_default_schedule_day.clearValues

        # get values for new default profile
        rule_vector = schedule_ruleset.scheduleRules
        new_default_daySchedule = rule_vector.reverse[0].daySchedule
        new_default_daySchedule_values = new_default_daySchedule.values
        new_default_daySchedule_times = new_default_daySchedule.times

        # update values and times for default profile
        for i in 0..(new_default_daySchedule_values.size - 1)
          old_default_schedule_day.addValue(new_default_daySchedule_times[i], new_default_daySchedule_values[i])
        end
        # note - I'm not looking at interpolatetoTimestep field.

        # confirm that changes were made
        # runner.registerInfo("Default values for #{schedule_ruleset.name}: #{old_default_schedule_day.values}")

        # remove rule object that has become the default. Also try to remove the ScheduleDay
        rule_vector.reverse[0].remove # this seems to also remove the ScheduleDay associated with the rule
        # new_default_daySchedule.remove
        default_profiles_removed += 1
      end

      # report warning if schedule is missing type limits
      if schedule_ruleset.scheduleTypeLimits.empty?
        runner.registerWarning("#{schedule_ruleset.name} does not have a type limits assigned.")
      else
        # store schedule type limits object
        desired_type_limit = schedule_ruleset.scheduleTypeLimits.get

        # set type limit for summer and winter design day objects
        default_day = schedule_ruleset.defaultDaySchedule
        summer_design_day = schedule_ruleset.summerDesignDaySchedule
        winter_design_day = schedule_ruleset.winterDesignDaySchedule

        default_day_type_limit = default_day.setScheduleTypeLimits(desired_type_limit)
        summer_design_day_type_limit = summer_design_day.setScheduleTypeLimits(desired_type_limit)
        winter_design_type_limit = winter_design_day.setScheduleTypeLimits(desired_type_limit)

        if !default_day_type_limit || !summer_design_day_type_limit || !winter_design_type_limit
          runner.registerWarning("Failed to set type limit for default or design day for #{schedule_ruleset.name}")
        else
          puts 'did something'
        end

        # get day schedules for schedule_ruleset
        schedule_rules = schedule_ruleset.scheduleRules
        schedule_rules.each do |schedule_rule|
          day_schedule = schedule_rule.daySchedule
          day_type_limit = day_schedule.setScheduleTypeLimits(desired_type_limit)
          if !day_type_limit
            runner.registerWarning("Failed to set type limit for #{day_schedule.name}, child of #{schedule_ruleset.name}.")
          end
        end

      end
    end

    # reporting final condition of model
    runner.registerFinalCondition("#{default_profiles_removed} RuleSetSchedules had unused default profiles.")

    return true
  end
end

# this allows the measure to be use by the application
RemoveUnusedDefaultProfiles.new.registerWithApplication
