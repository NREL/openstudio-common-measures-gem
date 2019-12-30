# test loop to look at consistency of search results
require 'open-uri'
require 'json'

=begin
100.times do |i|

  # have seen Aberdeen show in in these zip codes
  zipcode_choices = [63145,80304,38103]
  zipcode = zipcode_choices[i % zipcode_choices.size]
  #search_string = "http://bcl7.development.nrel.gov/api/search/location:'#{zipcode}'.json?fq[]=bundle:nrel_component&fq[]=sm_vid_Component_Tags:Site&api_version=2.0"
  search_string = "http://bcl.nrel.gov/api/search/location:'#{zipcode}'.json?fq[]=bundle:nrel_component&fq[]=sm_vid_Component_Tags:Site&api_version=2.0"

  # search bcl for site components for target zip code
  responses = open(search_string).read
  responses = JSON.parse(responses)
  if responses['result'][0].values[0]['name'].include?("Aberdeen")
    puts "#{responses['result'][0].values[0]['name']}, #{Time.now} #{i} #{"************ WARNING, UNEXPECTED WEATHER FILE *************"}"
  else
    puts "#{responses['result'][0].values[0]['name']}, #{Time.now} #{i}"
  end
  sleep(5)
end
=end
