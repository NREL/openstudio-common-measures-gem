########################################################################################################################
#  openstudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC. All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
#  following conditions are met:
#
#  (1) Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#  disclaimer.
#
#  (2) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#  following disclaimer in the documentation and/or other materials provided with the distribution.
#
#  (3) Neither the name of the copyright holder nor the names of any contributors may be used to endorse or promote
#  products derived from this software without specific prior written permission from the respective party.
#
#  (4) Other than as required in clauses (1) and (2), distributions in any form of modifications or other derivative
#  works may not use the "openstudio" trademark, "OS", "os", or any other confusingly similar designation without
#  specific prior written permission from Alliance for Sustainable Energy, LLC.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER, THE UNITED STATES GOVERNMENT, OR ANY CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
########################################################################################################################

require "openstudio/common-measures/version"
require "openstudio/extension"

module OpenStudio
  module CommonMeasures
    class CommonMeasures < OpenStudio::Extension::Extension
      # include OpenStudio::Extension
      
      # Return the version of the OpenStudio Extension Gem
      def version
        OpenStudio::CommonMeasures::VERSION
      end
      
      # Return the absolute path of the measures or nil if there is none, can be used when configuring OSWs
      def measures_dir
        return File.absolute_path(File.join(root_dir, 'lib/measures/'))
      end
      
      # Return the absolute path of the measures resources dir or nil if there is none
      def measure_resources_dir
        return File.absolute_path(File.join(root_dir, 'lib/measure_resources/'))
      end
      
      # Return the absolute path of the measures files dir or nil if there is none
      def measure_files_dir
        return File.absolute_path(File.join(root_dir, 'lib/measure_files/'))
      end
      
      # Relevant files such as weather data, design days, etc.
      # return the absolute path of the files or nil if there is none, can be used when configuring OSWs
      def files_dir
        return File.absolute_path(File.join(root_dir, 'lib/files/'))
      end

      # return the absolute path of root of this gem
      def root_dir
        return File.absolute_path(File.join(File.dirname(__FILE__), '../../'))
      end
      
    end
  end
end
