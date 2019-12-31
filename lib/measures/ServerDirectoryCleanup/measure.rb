#start the measure
class ServerDirectoryCleanup < OpenStudio::Measure::ReportingMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    "Server Directory Cleanup"
  end

  # file types that can be removed
  def file_types()

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

  #define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    # loop through file types and make arguments
    file_types.each do |k,v|
      temp_var = OpenStudio::Measure::OSArgument.makeBoolArgument(k, true)
      temp_var.setDisplayName("Remove #{k} files from run directory")
      temp_var.setDefaultValue(true)
      args << temp_var
    end

    args
  end

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      false
    end

    # assign the user inputs to variables
    args = {}
    file_types.each do |k,v|
      args[k] = runner.getBoolArgumentValue(k, user_arguments)
    end

    initial_string = "The following files were in the local run directory prior to the execution of this measure: "
    Dir.entries("./../").each do |f|
      initial_string << "#{f}, "
    end
    initial_string = initial_string[0..(initial_string.length-3)]+"."
    runner.registerInitialCondition(initial_string)

    # todo - code to remove sizing runs is not functional yet
    # delete run directories
    file_types.each do |k,v|
      next if !args[k]
      if v == "Sizing Run Directories"

        Dir.glob("./../**/output").select{ |e| File.directory? e }.each do |f|
          runner.registerInfo("Removing #{f} directory.")
          FileUtils.rm_f Dir.glob("#{f}/*")
          FileUtils.remove_dir(f,true)
        end
        # sometimes SizingRun seems to be used instead of output
        Dir.glob("./../**/SizingRun").select{ |e| File.directory? e }.each do |f|
          runner.registerInfo("Removing #{f} directory.")
          FileUtils.rm_f Dir.glob("#{f}/*")
          FileUtils.remove_dir(f,true)
        end

      else
        Dir.glob("./../#{v}").each do |f|
          File.delete(f)
          runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
        end
      end
    end

    final_string = "The following files were in the local run directory following to the execution of this measure: "
    Dir.entries("./..").each do |f|
      final_string << "#{f}, "
    end
    final_string = final_string[0..(final_string.length-3)]+"."
    runner.registerFinalCondition(final_string)

    true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ServerDirectoryCleanup.new.registerWithApplication