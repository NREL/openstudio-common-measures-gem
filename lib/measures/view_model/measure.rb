# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'rubygems'
require 'json'
require 'erb'

require_relative 'resources/va3c'

# start the measure
class ViewModel < OpenStudio::Ruleset::ModelUserScript
  # define the name that a user will see
  def name
    return 'ViewModel'
  end

  # human readable description
  def description
    return 'Visualize an OpenStudio model in a web based viewer'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Converts the OpenStudio model to vA3C JSON format and renders using Three.js'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # convert the model to vA3C JSON format
    json = nil
    model_clone = model.clone(true).to_Model
    begin
      # try to use new implementation
      ft = OpenStudio::Model::ThreeJSForwardTranslator.new
      three_scene = ft.modelToThreeJS(model_clone, true)
      json = JSON.parse(three_scene.toJSON(false), symbolize_names: true)
      runner.registerInfo('Used new ThreeScene translator.')
    rescue NameError, StandardError
      # use old Ruby implementation
      runner.registerInfo('Using Ruby VA3C translator.')
      json = VA3C.convert_model(model_clone)
    end

    # write json file
    json_out_path = './report.json'
    File.open(json_out_path, 'w') do |file|
      file << JSON.generate(json, object_nl: "\n", array_nl: '', indent: '  ', space: '', space_before: '')
      # file << JSON::generate(json, {:object_nl=>"", :array_nl=>"", :indent=>"", :space=>"", :space_before=>""})
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue StandardError
        file.flush
      end
    end

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.in"
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.in"
    end
    html_in = ''
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    os_data = JSON.generate(json, object_nl: '', array_nl: '', indent: '', space: '', space_before: '')
    title = 'View Model'
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = './report.html'
    File.open(html_out_path, 'w') do |file|
      file << html_out

      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue StandardError
        file.flush
      end
    end

    html_out_path = File.absolute_path(html_out_path)

    # reporting final condition
    runner.registerFinalCondition("Report written to <a href='file:///#{html_out_path}'>report.html</a>.")

    runner.registerAsNotApplicable('No changes made to the model.')

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ViewModel.new.registerWithApplication
