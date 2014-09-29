require_relative 'model'
require_relative 'model_version'

class ModelChoice
  attr_accessor :number
  attr_accessor :name
  attr_accessor :type
  attr_accessor :descriptions
  attr_accessor :long_descriptions
  attr_accessor :incremental_or_alternative
  attr_accessor :levels
  attr_accessor :doc
end

class DataFromModel
  attr_accessor :pathway
  
  # This connects to model.rb which
  # connects to model.c which is a 
  # translation of model.xlsx
  def excel
    @excel ||= Model.new
  end
  
  # Data that changes as the user makes choices
  # The code should be in the form i0g2dd2pp1121f1i032211p004314110433304202304320420121
  # Where each letter or digit corresponds to a choice to be set in the Excel
  def calculate_pathway(code = convert_input_values_to_code(excel.webtool_user_choices.flatten).join(''))
    # Need to make sure the Excel is ready for a new calculation
    excel.reset
    # Turn the i0g2dd2pp1121f1i032211p004314110433304202304320420121 into something like
    # [1.8,0.0,1.6,2.0,1.3,1.3,..]
    choices = convert_code_to_input_values(code.split(''))
    # Set the spreadsheet controls (input.choices is a named reference in the Excel)
    excel.webtool_user_choices = choices
    # Read out the results, where each of these refers to a named reference in the Excel
    # (e.g. excel.output_impots_quantity refers to the output.imports.quantity named reference)
    { 
      'code' => code, 
      'warming' => excel.webtool_warming_2100.flatten,
      'emissions' => excel.webtool_co2e_total_emissions.flatten,
      'costs' => excel.webtool_costs_total_range
    }
  end


  def example_pathways
    return @example_pathways if @example_pathways
    @example_pathways = {}
    excel.webtool_example_pathways.transpose.each do |pathway_data|
      name = pathway_data.shift
      code = convert_input_values_to_code(pathway_data).join
      @example_pathways[name] = code
    end
    @example_pathways
  end


  # Set the 9 decimal points between 1.1 and 3.9
  FLOAT_TO_LETTER_MAP = Hash["abcdefghijklmnopqrstuvwxyzABCD".split('').map.with_index { |l,i| [(i/10.0)+1,l] }]
  FLOAT_TO_LETTER_MAP[0.0] = '0'
  FLOAT_TO_LETTER_MAP[1.0] = '1'
  FLOAT_TO_LETTER_MAP[2.0] = '2'
  FLOAT_TO_LETTER_MAP[3.0] = '3'
  FLOAT_TO_LETTER_MAP[4.0] = '4'
  
  LETTER_TO_FLOAT_MAP = FLOAT_TO_LETTER_MAP.invert
  
  COUNTRY_TO_LETTER_MAP = {
    "US" => '1',
    "India" => '2',
    "China" => '3',
    "Central and South America / Former Soviet Union" => '4',
    "Western Europe" => '5',
    "Africa" => '6'
  }

  LETTER_TO_COUNTRY_MAP = COUNTRY_TO_LETTER_MAP.invert

  CLIMATE_SENSITIVITY_TO_LETTER_MAP = {
    "A" => '1',
    "B" => '2',
  }

  LETTER_TO_CLIMATE_SENSITIVITY_MAP = CLIMATE_SENSITIVITY_TO_LETTER_MAP.invert

  FUEL_COST_TO_LETTER_MAP = {
    "Point" => '1'
  }

  LETTER_TO_FUEL_COST_MAP = FUEL_COST_TO_LETTER_MAP.invert

  STRING_TO_LETTER_MAP = COUNTRY_TO_LETTER_MAP.merge(CLIMATE_SENSITIVITY_TO_LETTER_MAP).merge(FUEL_COST_TO_LETTER_MAP)

  def convert_input_values_to_code(array)
    array.map do |entry|
      case entry
      when String; STRING_TO_LETTER_MAP[entry] || entry
      when Float; FLOAT_TO_LETTER_MAP[entry] || entry
      when nil; 0
      else entry
      end
    end
  end
  
  def convert_code_to_input_values(array)
    array.map.with_index do |entry, index|
      case index
      when 50;
        LETTER_TO_CLIMATE_SENSITIVITY_MAP[entry]
      when 51;
        LETTER_TO_COUNTRY_MAP[entry]
      when 52..59
        LETTER_TO_FUEL_COST_MAP[entry]
      else 
        LETTER_TO_FLOAT_MAP[entry].to_f || entry.to_f
      end
    end
  end
  
end

if __FILE__ == $0
  g = DataFromModel.new
  initial_choices = g.excel.webtool_user_choices.flatten

  tests = 100
  t = Time.now
  a = []
  tests.times do
    a << g.calculate_pathway(initial_choices.map { rand(4)+1 }.join)
  end
  te = Time.now - t
  puts "#{te/tests} seconds per run"
  puts "#{tests/te} runs per second"
end
