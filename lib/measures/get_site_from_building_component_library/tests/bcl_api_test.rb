

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

# test loop to look at consistency of search results
require 'open-uri'
require 'json'

# 100.times do |i|
#
#   # have seen Aberdeen show in in these zip codes
#   zipcode_choices = [63145,80304,38103]
#   zipcode = zipcode_choices[i % zipcode_choices.size]
#   #search_string = "http://bcl7.development.nrel.gov/api/search/location:'#{zipcode}'.json?fq[]=bundle:nrel_component&fq[]=sm_vid_Component_Tags:Site&api_version=2.0"
#   search_string = "http://bcl.nrel.gov/api/search/location:'#{zipcode}'.json?fq[]=bundle:nrel_component&fq[]=sm_vid_Component_Tags:Site&api_version=2.0"
#
#   # search bcl for site components for target zip code
#   responses = open(search_string).read
#   responses = JSON.parse(responses)
#   if responses['result'][0].values[0]['name'].include?("Aberdeen")
#     puts "#{responses['result'][0].values[0]['name']}, #{Time.now} #{i} #{"************ WARNING, UNEXPECTED WEATHER FILE *************"}"
#   else
#     puts "#{responses['result'][0].values[0]['name']}, #{Time.now} #{i}"
#   end
#   sleep(5)
# end
