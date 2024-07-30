# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

class OpenStudio::Model::CoilHeatingWaterToAirHeatPumpVariableSpeedEquationFit
  def maxHeatingCapacity
    if ratedHeatingCapacityAtSelectedNominalSpeedLevel.is_initialized
      ratedHeatingCapacityAtSelectedNominalSpeedLevel
    else
      autosizedRatedHeatingCapacityAtSelectedNominalSpeedLevel
    end
  end

  def maxAirFlowRate
    if ratedAirFlowRateAtSelectedNominalSpeedLevel.is_initialized
      ratedAirFlowRateAtSelectedNominalSpeedLevel
    else
      autosizedRatedAirFlowRateAtSelectedNominalSpeedLevel
    end
  end

  def maxWaterFlowRate
    if ratedWaterFlowRateAtSelectedNominalSpeedLevel.is_initialized
      ratedWaterFlowRateAtSelectedNominalSpeedLevel
    else
      autosizedRatedWaterFlowRateAtSelectedNominalSpeedLevel
    end
  end

  def maxHeatingCapacityAutosized
    if ratedHeatingCapacityAtSelectedNominalSpeedLevel.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxAirFlowRateAutosized
    if ratedAirFlowRateAtSelectedNominalSpeedLevel.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    if ratedWaterFlowRateAtSelectedNominalSpeedLevel.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def performanceCharacteristics
    effs = []
    speeds.each_with_index do |speed_data, i|
      speed_effs = speed_data.performanceCharacteristics
      speed_effs.each { |pc| pc[1] = "Speed #{i+1} #{pc[1]}"}
      effs.concat speed_effs
    end
    return effs
  end
end
