# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'

RSpec.describe OpenStudio::CommonMeasures do
  it 'has a version number' do
    expect(OpenStudio::CommonMeasures::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::CommonMeasures::Extension.new
    expect(File.exist?(File.join(instance.measures_dir, 'ChangeBuildingLocation/'))).to be true
  end
end
