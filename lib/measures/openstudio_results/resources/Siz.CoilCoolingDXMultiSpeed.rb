# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

class OpenStudio::Model::CoilCoolingDXMultiSpeed
  def maxCoolingCapacity
    stages.last.maxCoolingCapacity
  end

  def maxAirFlowRate
    stages.last.maxAirFlowRate
  end

  def maxCoolingCapacityAutosized
    stages.last.maxCoolingCapacityAutosized
  end

  def maxAirFlowRateAutosized
    stages.last.maxAirFlowRateAutosized
  end

  def performanceCharacteristics
    effs = []
    stages.each_with_index do |stage_data, i|
      stage_effs = stage_data.performanceCharacteristics
      stage_effs.each{|pc| pc[1] = "Stage #{i+1} #{pc[1]}"}
      effs.concat stage_effs
    end
    return effs
  end
end
