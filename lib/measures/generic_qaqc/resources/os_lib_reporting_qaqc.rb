# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'json'

module OsLib_Reporting
  # setup - get model, sql, and setup web assets path
  def self.setup(runner)
    results = {}

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # get the last idf
    workspace = runner.lastEnergyPlusWorkspace
    if workspace.empty?
      runner.registerError('Cannot find last idf file.')
      return false
    end
    workspace = workspace.get

    # get the last sql file
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # populate hash to pass to measure
    results[:model] = model
    # results[:workspace] = workspace
    results[:sqlFile] = sqlFile
    results[:web_asset_path] = OpenStudio.getSharedResourcesPath / OpenStudio::Path.new('web_assets')

    return results
  end

  # cleanup - prep html
  def self.gen_html(html_in_path, web_asset_path, sections, name)
    # instance variables for erb
    @sections = sections
    @name = name

    # read in template
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
    end
    html_in = ''
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
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

    return html_out_path
  end

  # developer notes
  # method below is custom version of standard OpenStudio results methods. It passes an array of sections vs. a single section.
  # It doesn't use the model or SQL file. It just gets data form OpenStudio attributes passed in
  # It doesn't have a name_only section since it doesn't populate user arguments

  def self.sections_from_check_attributes(check_elems, runner)
    # inspecting check attributes
    # make single table with checks.
    # make second table with flag description (with column for where it came from)

    # array to hold sections
    sections = []

    # gather data for section
    qaqc_check_summary = {}
    qaqc_check_summary[:title] = 'List of Checks in Measure'
    qaqc_check_summary[:header] = ['Name', 'Category', 'Flags', 'Tolerance','Description']
    qaqc_check_summary[:data] = []
    qaqc_check_summary[:data_color] = []
    @qaqc_check_section = {}
    @qaqc_check_section[:title] = 'QAQC Check Summary'
    @qaqc_check_section[:tables] = [qaqc_check_summary]

    # add sections to array
    sections << @qaqc_check_section

    # counter for flags thrown
    num_flags = 0

    check_elems.each do |check|
      # gather data for section
      qaqc_flag_details = {}
      qaqc_flag_details[:title] = "List of Flags Triggered for #{check.valueAsAttributeVector.first.valueAsString}."
      qaqc_flag_details[:header] = ['Flag Detail']
      qaqc_flag_details[:data] = []
      @qaqc_flag_section = {}
      @qaqc_flag_section[:title] = check.valueAsAttributeVector.first.valueAsString.to_s
      @qaqc_flag_section[:tables] = [qaqc_flag_details]

      check_name = nil
      check_cat = nil
      check_desc = nil
      check_min_pass = nil
      check_max_pass = nil
      flags = []


      # loop through attributes (name,category,description, min tol, max tol ,then optionally one or more flag attributes)
      check.valueAsAttributeVector.each do |attribute|
        if attribute.name == "name"
          check_name = attribute.valueAsString
        elsif attribute.name == 'category'
          check_cat = attribute.valueAsString
        elsif attribute.name == 'description'
          check_desc = attribute.valueAsString
        elsif attribute.name == 'min_pass'
          if ['Double','Integer'].include? (attribute.valueType.valueDescription)
            check_min_pass = attribute.valueAsDouble
          else
            check_min_pass = attribute.valueAsString
          end
        elsif attribute.name == 'max_pass'
          if ['Double','Integer'].include? (attribute.valueType.valueDescription)
            check_max_pass = attribute.valueAsDouble
          else
            check_max_pass = attribute.valueAsString
          end
        else # should be flag
          flags << attribute.valueAsString
          qaqc_flag_details[:data] << [attribute.valueAsString]
          runner.registerWarning("#{check_name} - #{attribute.valueAsString}")
          num_flags += 1
        end          
      end

      # add row to table for this check
      # check_supply_air_and_thermostat_temp_difference should have unit for F instead of default %, can add that here or do I need to pass in from that method
      if !check_min_pass.nil? && !check_min_pass.instance_of?(String) && check_min_pass.abs > 0
        tol_val = check_min_pass
      elsif !check_max_pass.nil? && !check_min_pass.instance_of?(String) && check_max_pass.abs > 0
        tol_val = check_max_pass
      elsif
        tol_val = check_min_pass # should empty string or Var
      end

      # change units for some checks #todo - this can be changed later to use "unit" attribute
      if check_name == 'Supply and Zone Air Temperature'
        tol_val = "#{tol_val} F"        
      elsif check_name == 'Baseline Mechanical System Type'
        tol_val = "#{tol_val}"        
      else
        tol_val = "#{tol_val}%"
      end

      qaqc_check_summary[:data] << [check_name, check_cat, flags.size, tol_val ,check_desc]

      # add info message for check if no flags found (this way user still knows what ran)
      if num_flags == 0
        runner.registerInfo("#{check_name} - no flags.")
      end

      # color cells based and add runner register values based on flag status
      if !flags.empty?
        qaqc_check_summary[:data_color] << ['', '', 'indianred', '']
        runner.registerValue(check_name.downcase.tr(' ', '_'), flags.size, 'flags')
      else
        qaqc_check_summary[:data_color] << ['', '', 'lightgreen', '']
        runner.registerValue(check_name.downcase.tr(' ', '_'), flags.size, 'flags')
      end

      # add table for this check if there are flags
      if !qaqc_flag_details[:data].empty?
        sections << @qaqc_flag_section
      end
    end

    # add total flags registerValue
    runner.registerValue('total_qaqc_flags', num_flags, 'flags')

    return sections
  end
end
