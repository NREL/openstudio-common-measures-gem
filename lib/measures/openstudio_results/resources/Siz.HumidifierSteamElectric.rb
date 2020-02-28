class OpenStudio::Model::HumidifierSteamElectric
  def ratedPower
    if ratedPower.is_initialized #SystemStackError: stack level too deep error when this called, disabled in Siz.Model.rb
      ratedPower
    else
      ratedPowerAutosized
    end
  end

  def ratedPowerAutosized
    if ratedPower.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
