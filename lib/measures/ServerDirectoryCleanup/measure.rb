
# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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

# start the measure
class ServerDirectoryCleanup < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    'Server Directory Cleanup'
  end

  # file types that can be removed
  def file_types
    # key is arg name value is string for run method
    file_types = {}
    file_types['sql'] = '*.sql'
    file_types['eso'] = '*.eso'
    file_types['audit'] = '*.audit'
    file_types['osm'] = '*.osm'
    file_types['idf'] = '*.idf'
    file_types['bnd'] = '*.bnd'
    file_types['eio'] = '*.eio'
    file_types['shd'] = '*.shd'
    file_types['mdd'] = '*.mdd'
    file_types['rdd'] = '*.rdd'
    file_types['csv'] = '*.csv'
    file_types['Sizing Run Directories'] = 'Sizing Run Directories'

    return file_types
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    # loop through file types and make arguments
    file_types.each do |k, v|
      temp_var = OpenStudio::Measure::OSArgument.makeBoolArgument(k, true)
      temp_var.setDisplayName("Remove #{k} files from run directory")
      temp_var.setDefaultValue(true)
      args << temp_var
    end

    args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      false
    end

    # assign the user inputs to variables
    args = {}
    file_types.each do |k, v|
      args[k] = runner.getBoolArgumentValue(k, user_arguments)
    end

    initial_string = 'The following files were in the local run directory prior to the execution of this measure: '
    Dir.entries('./../').each do |f|
      initial_string << "#{f}, "
    end
    initial_string = initial_string[0..(initial_string.length - 3)] + '.'
    runner.registerInitialCondition(initial_string)

    # TODO: - code to remove sizing runs is not functional yet
    # delete run directories
    file_types.each do |k, v|
      next if !args[k]
      if v == 'Sizing Run Directories'

        Dir.glob('./../**/output').select { |e| File.directory? e }.each do |f|
          runner.registerInfo("Removing #{f} directory.")
          FileUtils.rm_f Dir.glob("#{f}/*")
          FileUtils.remove_dir(f, true)
        end
        # sometimes SizingRun seems to be used instead of output
        Dir.glob('./../**/SizingRun').select { |e| File.directory? e }.each do |f|
          runner.registerInfo("Removing #{f} directory.")
          FileUtils.rm_f Dir.glob("#{f}/*")
          FileUtils.remove_dir(f, true)
        end

      else
        Dir.glob("./../#{v}").each do |f|
          File.delete(f)
          runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
        end
      end
    end

    final_string = 'The following files were in the local run directory following to the execution of this measure: '
    Dir.entries('./..').each do |f|
      final_string << "#{f}, "
    end
    final_string = final_string[0..(final_string.length - 3)] + '.'
    runner.registerFinalCondition(final_string)

    true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ServerDirectoryCleanup.new.registerWithApplication
