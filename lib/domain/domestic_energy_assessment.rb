module Domain
  class DomesticEnergyAssessment
    attr_reader :current_energy_efficiency_rating,
                :potential_energy_efficiency_rating,
                :assessment_id,
                :recommended_improvements

    def initialize(
      date_of_assessment,
      date_registered,
      dwelling_type,
      type_of_assessment,
      total_floor_area,
      assessment_id,
      assessor,
      address_summary,
      current_energy_efficiency_rating,
      potential_energy_efficiency_rating,
      postcode,
      date_of_expiry,
      address_line1,
      address_line2,
      address_line3,
      address_line4,
      town,
      current_space_heating_demand,
      current_water_heating_demand,
      impact_of_loft_insulation,
      impact_of_cavity_insulation,
      impact_of_solid_wall_insulation,
      recommended_improvements
    )
      @date_of_assessment = Date.strptime(date_of_assessment, '%Y-%m-%d')
      @date_registered = Date.strptime(date_registered, '%Y-%m-%d')
      @dwelling_type = dwelling_type
      @type_of_assessment = type_of_assessment
      @total_floor_area = total_floor_area.to_f
      @assessment_id = assessment_id
      @assessor = assessor
      @address_summary = address_summary
      @current_energy_efficiency_rating = current_energy_efficiency_rating
      @potential_energy_efficiency_rating = potential_energy_efficiency_rating
      @postcode = postcode
      @date_of_expiry = Date.strptime(date_of_expiry, '%Y-%m-%d')
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_line3 = address_line3
      @address_line4 = address_line4
      @town = town
      @current_space_heating_demand = current_space_heating_demand.to_f
      @current_water_heating_demand = current_water_heating_demand.to_f
      @impact_of_loft_insulation = impact_of_loft_insulation
      @impact_of_cavity_insulation = impact_of_cavity_insulation
      @impact_of_solid_wall_insulation = impact_of_solid_wall_insulation
      @recommended_improvements = recommended_improvements
    end

    def get_energy_rating_band(number)
      case number
      when 1..20
        'g'
      when 21..38
        'f'
      when 39..54
        'e'
      when 55..68
        'd'
      when 69..80
        'c'
      when 81..91
        'b'
      when 92..100
        'a'
      end
    end

    def to_hash
      {
        date_of_assessment: @date_of_assessment.strftime('%Y-%m-%d'),
        date_registered: @date_registered.strftime('%Y-%m-%d'),
        dwelling_type: @dwelling_type,
        type_of_assessment: @type_of_assessment,
        total_floor_area: @total_floor_area.to_f,
        assessment_id: @assessment_id,
        scheme_assessor_id: @assessor.scheme_assessor_id,
        address_summary: @address_summary,
        current_energy_efficiency_rating: @current_energy_efficiency_rating,
        potential_energy_efficiency_rating: @potential_energy_efficiency_rating,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry.strftime('%Y-%m-%d'),
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
        heat_demand: {
          current_space_heating_demand: @current_space_heating_demand.to_f,
          current_water_heating_demand: @current_water_heating_demand.to_f,
          impact_of_loft_insulation: @impact_of_loft_insulation,
          impact_of_cavity_insulation: @impact_of_cavity_insulation,
          impact_of_solid_wall_insulation: @impact_of_solid_wall_insulation
        },
        current_energy_efficiency_band:
          get_energy_rating_band(@current_energy_efficiency_rating),
        potential_energy_efficiency_band:
          get_energy_rating_band(@potential_energy_efficiency_rating),
        recommended_improvements: @recommended_improvements.map(&:to_hash)
      }
    end

    def to_record
      {
        date_of_assessment: @date_of_assessment,
        date_registered: @date_registered,
        dwelling_type: @dwelling_type,
        type_of_assessment: @type_of_assessment,
        total_floor_area: @total_floor_area.to_f,
        assessment_id: @assessment_id,
        scheme_assessor_id: @assessor.scheme_assessor_id,
        address_summary: @address_summary,
        current_energy_efficiency_rating:
          @current_energy_efficiency_rating.to_f,
        potential_energy_efficiency_rating:
          @potential_energy_efficiency_rating.to_f,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry,
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
        current_space_heating_demand: @current_space_heating_demand,
        current_water_heating_demand: @current_water_heating_demand,
        impact_of_loft_insulation: @impact_of_loft_insulation,
        impact_of_cavity_insulation: @impact_of_cavity_insulation,
        impact_of_solid_wall_insulation: @impact_of_solid_wall_insulation
      }
    end
  end
end
