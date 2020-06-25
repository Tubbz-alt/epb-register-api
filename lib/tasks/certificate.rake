desc "Truncate all certificate data"

task :truncate_certificate do
  if ENV["STAGE"] == "production"
    raise StandardError, "I will not truncate the production db"
  end

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE assessments RESTART IDENTITY CASCADE")
end

desc "Import some random certificate data"

task :generate_certificate do
  if ENV["STAGE"] == "production"
    raise StandardError, "I will not seed the production db"
  end

  puts "creating assessments"

  addresses = [
    { id: "", line1: "Flat 32", line2: "11 Makup Street", line3: "", line4: "", town: "London", postcode: "E2 0SZ" },
    { id: "", line1: "Flat 34", line2: "11 Makup Street", line3: "", line4: "", town: "London", postcode: "E2 0SZ" },
    { id: "", line1: "Flat 68", line2: "11 Makup Street", line3: "", line4: "", town: "London", postcode: "E2 0SX" },
    { id: "", line1: "The Dormers", line2: "Milton Mews", line3: "", line4: "", town: "London", postcode: "NW3 2UU" },
    { id: "", line1: "8 Spooky Avenue", line2: "", line3: "", line4: "", town: "London", postcode: "SW1A 2AA" },
    { id: "", line1: "11 Makup Street", line2: "", line3: "", line4: "", town: "London", postcode: "SW1A 2AA" },
    { id: "", line1: "11 Mornington Crescent", line2: "", line3: "", line4: "", town: "London", postcode: "SE1 1TE" },
    { id: "", line1: "15", line2: "Thomas Lane", line3: "", line4: "", town: "London", postcode: "SW1X 7XL" },
    { id: "", line1: "First floor flat", line2: "7a Parkhill Road", line3: "", line4: "", town: "London", postcode: "W1B 5BT" },
    { id: "", line1: "1 Hamlet Building", line2: "", line3: "", line4: "", town: "Bournemouth", postcode: "BH2 5BH" },
  ]

  dwelling_type = ["end-terrace house", "terrace house", "flat", "bungalow", "mansion", "castle"]
  type_of_assessment = %w[RdSAP SAP CEPC]
  current_space_heating_demand = [1233, 3445, 4546, 6748, 8910, 7483, 8963]
  current_water_heating_demand = [7983, 2321, 454, 648, 8932, 6483, 72_363]
  current_carbon_emission = [5.4, 4.327, 7.8, 4.5, 6.4, 4]
  potential_carbon_emission = [1.4, 0.5, 3.5, 2.1, 3.624, 1]
  impact_of_loft_insulation = [-21, -543, -764, -836, -13, -94, -35]
  impact_of_cavity_insulation = [-21, -764, -836, -13, -94, -35]
  impact_of_solid_wall_insulation = [-4, -53, -64, -99, -23, -73, -5]
  improvement_code = %w[1 2 3 4 5 6 7 8 9 10 11 12 13].shuffle
  indicative_cost = ["£448 - £463", "£30", "£82765 - £700000", "£485 - £728", "£2000 - £3,500"]
  typical_saving = [453.45, 200, 310.49, 999.99, 1000, 550.50]
  improvement_category = %w[a b c d e f]
  improvement_type = %w[minor medium major]
  energy_performance_rating_improvement = [93, 85, 75, 62, 45]
  environmental_impact_rating_improvement = [93, 85, 75, 62, 45]
  green_deal_category_code = %w[a b c d e]
  related_party_disclosure_number = [1, 2, 3, 4, 5, 6, 7]
  related_party_disclosure_text = ["No related party",
                                   "Relative of homeowner or of occupier of the property",
                                   "Residing at the property",
                                   "Financial interest in the property",
                                   "Owner or Director of the organisation dealing with the property transaction",
                                   "Employed by the professional dealing with the property transaction",
                                   "Relative of the professional dealing with the property transaction",
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   nil]
  property_summary = [
    [
      {
        "name": "walls",
        "description": "Brick wall, no insulation",
        "energy_efficiency_rating": "4",
        "environmental_efficiency_rating": "0",
      },
      {
        "name": "secondary_heating",
        "description": "None",
        "energy_efficiency_rating": "3",
        "environmental_efficiency_rating": "0",
      },
    ].to_json,
    [
      {
        "name": "main_heating",
        "description": "Room heaters, electric",
        "energy_efficiency_rating": "3",
        "environmental_efficiency_rating": "0",
      },
      {
        "name": "hot_water",
        "description": "Gas Boiler",
        "energy_efficiency_rating": "1",
        "environmental_efficiency_rating": "0",
      },
    ].to_json,
    [
      {
        "name": "window",
        "description": "Fully double glazed",
        "energy_efficiency_rating": "3",
        "environmental_efficiency_rating": "0",
      },
      {
        "name": "floor",
        "description": "Suspended, no insulation (assumed)",
        "energy_efficiency_rating": "0",
        "environmental_efficiency_rating": "0",
      },
    ].to_json,
  ]

  result = ActiveRecord::Base.connection.execute("SELECT * FROM assessors ORDER BY random() LIMIT 2000")

  result.each_with_index do |assessor, number|
    address = addresses.sample

    assessments_at_address = ActiveRecord::Base.connection.execute("SELECT assessment_id FROM assessments WHERE address_line1 = '#{address[:line1]}' AND postcode = '#{address[:postcode]}' ORDER BY date_of_expiry DESC LIMIT 1")

    unless assessments_at_address.entries.empty?
      address[:id] = "RRN-#{assessments_at_address[0]['assessment_id']}"
    end

    scheme_assessor_id = assessor["scheme_assessor_id"]

    date_of_assessment = "20" + rand(6..19).to_s.rjust(2, "0") + rand(1..12).to_s.rjust(2, "0") + rand(1..28).to_s.rjust(2, "0")
    date_registered = (Date.parse(date_of_assessment) + rand(1..5).day).strftime("%Y-%m-%d")
    date_of_expiry = (Date.parse(date_of_assessment) + 10.year).strftime("%Y-%m-%d")
    current_energy_efficiency_rating = rand(1..99)
    internal_current_carbon_emission = current_carbon_emission.sample
    internal_potential_carbon_emission = potential_carbon_emission.sample
    internal_current_space_heating_demand = current_space_heating_demand.sample
    internal_current_water_heating_demand = current_water_heating_demand.sample
    internal_impact_of_loft_insulation = impact_of_loft_insulation.sample
    internal_impact_of_cavity_insulation = impact_of_cavity_insulation.sample
    internal_impact_of_solid_wall_insulation = impact_of_solid_wall_insulation.sample
    assessment_id = "4321-8765-0987-7654-" + number.to_s.rjust(4, "0")
    internal_related_party_disclosure_number = related_party_disclosure_number.sample
    internal_related_party_disclosure_text = related_party_disclosure_text.sample
    internal_property_summary = property_summary.sample

    unless internal_related_party_disclosure_text.nil?
      internal_related_party_disclosure_number = "NULL"
    end

    query =
      "INSERT INTO
        assessments
          (
            assessment_id,
            date_of_assessment,
            date_registered,
            dwelling_type,
            type_of_assessment,
            total_floor_area,
            current_energy_efficiency_rating,
            potential_energy_efficiency_rating,
            postcode,
            date_of_expiry,
            address_line1,
            address_line2,
            address_line3,
            address_line4,
            town,
            address_id,
            current_carbon_emission,
            potential_carbon_emission,
            current_space_heating_demand,
            current_water_heating_demand,
            impact_of_loft_insulation,
            impact_of_cavity_insulation,
            impact_of_solid_wall_insulation,
            scheme_assessor_id,
            related_party_disclosure_number,
            related_party_disclosure_text,
            property_summary
          )
        VALUES(
          '#{assessment_id}',
          '#{date_of_assessment}',
          '#{date_registered}',
          '#{dwelling_type.sample}',
          '#{type_of_assessment.sample}',
          '#{rand(20..200)}',
          '#{current_energy_efficiency_rating}',
          '#{[current_energy_efficiency_rating + rand(1..20), 99].min}',
          '#{address[:postcode]}',
          '#{date_of_expiry}',
          '#{address[:line1]}',
          '#{address[:line2]}',
          '#{address[:line3]}',
          '#{address[:line4]}',
          '#{address[:town]}',
          '#{address[:id]}',
          '#{internal_current_carbon_emission}',
          '#{internal_potential_carbon_emission}',
          '#{internal_current_space_heating_demand}',
          '#{internal_current_water_heating_demand}',
          '#{internal_impact_of_loft_insulation}',
          '#{internal_impact_of_cavity_insulation}',
          '#{internal_impact_of_solid_wall_insulation}',
          '#{scheme_assessor_id}',
          #{internal_related_party_disclosure_number},
          '#{internal_related_party_disclosure_text}',
          '#{internal_property_summary}'
        )"

    ActiveRecord::Base.connection.execute("DELETE FROM domestic_epc_energy_improvements WHERE assessment_id = '#{assessment_id}'")
    ActiveRecord::Base.connection.execute("DELETE FROM assessments WHERE assessment_id = '#{assessment_id}'")
    ActiveRecord::Base.connection.execute(query)

    rand(0..10).times do |sequence|
      internal_improvement_code = improvement_code[sequence]
      internal_indicative_cost = indicative_cost.sample
      internal_typical_saving = typical_saving.sample
      internal_improvement_category = improvement_category.sample
      internal_improvement_type = improvement_type.sample
      internal_energy_performance_rating_improvement = energy_performance_rating_improvement.sample
      internal_environmental_impact_rating_improvement = environmental_impact_rating_improvement.sample
      internal_green_deal_category_code = green_deal_category_code.sample

      recommended_improvements_query =
        "INSERT INTO
        domestic_epc_energy_improvements
          (
            assessment_id,
            sequence,
            improvement_code,
            indicative_cost,
            typical_saving,
            improvement_category,
            improvement_type,
            energy_performance_rating_improvement,
            environmental_impact_rating_improvement,
            green_deal_category_code
          )
        VALUES(
            '#{assessment_id}',
            '#{sequence}',
            '#{internal_improvement_code}',
            '#{internal_indicative_cost}',
            '#{internal_typical_saving}',
            '#{internal_improvement_category}',
            '#{internal_improvement_type}',
            '#{internal_energy_performance_rating_improvement}',
            '#{internal_environmental_impact_rating_improvement}',
            '#{internal_green_deal_category_code}'
        )"

      ActiveRecord::Base.connection.execute(recommended_improvements_query)
    end

    green_deal_plan_id = ("A" + ("A".."Z").to_a.sample + rand(100...2000).to_s.rjust(10, "0"))
    start_date = "20" + rand(14..21).to_s.rjust(2, "0") + rand(1..12).to_s.rjust(2, "0") + rand(1..28).to_s.rjust(2, "0")
    end_date = (Date.parse(start_date) + rand(5..20).year).strftime("%Y-%m-%d")
    provider_name = ["My Company", "Your Company", "Big Organisation", "Much Profit LTD", "The Business", "An Organisation"].sample
    provider_telephone = %w[019192983 93746537398 0922665 826472665 09813784].sample
    provider_email = ["testemail@email.com", "emailtest@email.com", "practiceemail@email.com", "emailpractice@email.com"].sample
    interest_rate = [14.61, 12.21, 26.30, 10.10, 15.70].sample
    fixed_interest_rate = %w[Y N].sample
    charge_uplift_amount = [0, 1.24, 1.50, 0.90, 1].sample
    charge_uplift_date = (Date.parse(start_date) + rand(1..20).year).strftime("%Y-%m-%d")
    cca_regulated = %w[Y N].sample
    structure_changed = %w[Y N].sample
    measures_removed = %w[Y N].sample
    charges = [
      [
        {
          "start_date": "2020-03-29",
          "end_date": "2030-03-29",
          "daily_charge": "0.34",
        },
        {
          "start_date": "2020-04-29",
          "end_date": "2030-12-29",
          "daily_charge": "1.34",
        },
      ].to_json,
      [
        {
          "start_date": "2022-03-29",
          "end_date": "2032-03-29",
          "daily_charge": "2.34",
        },
      ].to_json,
      [
        {
          "start_date": "2021-03-29",
          "end_date": "2032-03-29",
          "daily_charge": "0",
        },
      ].to_json,
    ]
    measures = [
      [
        {
          "product": "Hot water cylinder insulation",
          "repaid_date": "2030-03-29",
        },
      ].to_json,
      [
        {
          "product": "External wall insulation: WarmHome lagging stuff (TM)",
          "repaid_date": "2025-03-29",
        },
        {
          "product": "Hot water cylinder thermostat",
          "repaid_date": "2035-03-29",
        },
      ].to_json,
      [
        {
          "product": "Loft insulation: WarmHome lagging stuff (TM)",
          "repaid_date": "2032-03-29",
        },
      ].to_json,
    ]
    savings = [
      [
        {
          "fuel_code": "26",
          "fuel_saving": 0,
          "standing_charge_fraction": -0.3,
        },
      ].to_json,
      [
        {
          "fuel_code": "12",
          "fuel_saving": 1,
          "standing_charge_fraction": 0,
        },
      ].to_json,
      [
        {
          "fuel_code": "22",
          "fuel_saving": 10,
          "standing_charge_fraction": -0.1,
        },
        {
          "fuel_code": "34",
          "fuel_saving": 12,
          "standing_charge_fraction": -0.2,
        },
      ].to_json,
    ]

    if rand(21) == 20
      green_deal_query = "INSERT INTO
              green_deal_plans
              (
                green_deal_plan_id,
                start_date,
                end_date,
                provider_name,
                provider_telephone,
                provider_email,
                interest_rate,
                fixed_interest_rate,
                charge_uplift_amount,
                charge_uplift_date,
                cca_regulated,
                structure_changed,
                measures_removed,
                charges,
                measures,
                savings
              )
              VALUES
              (
                '#{green_deal_plan_id}',
                '#{start_date}',
                '#{end_date}',
                '#{provider_name}',
                '#{provider_telephone}',
                '#{provider_email}',
                '#{interest_rate}',
                '#{fixed_interest_rate}',
                '#{charge_uplift_amount}',
                '#{charge_uplift_date}',
                '#{cca_regulated}',
                '#{structure_changed}',
                '#{measures_removed}',
                '#{charges.sample}',
                '#{measures.sample}',
                '#{savings.sample}'
              )"

      ActiveRecord::Base.connection.execute(green_deal_query)

      green_deal_assessments_query = "INSERT INTO
              green_deal_assessments
              (
                green_deal_plan_id,
                assessment_id
              )
              VALUES (
                  '#{green_deal_plan_id}',
                  '#{assessment_id}'
              )"
      ActiveRecord::Base.connection.execute(green_deal_assessments_query)
    end
  end
end
