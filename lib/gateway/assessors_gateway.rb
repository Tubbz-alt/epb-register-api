module Gateway
  class AssessorsGateway
    class TooManyResults < Exception; end

    class Assessor < ActiveRecord::Base
      def to_hash
        Gateway::AssessorsGateway.new.to_hash(self)
      end

      def to_hash_with_scheme
        scheme = Scheme.find_by(scheme_id: self[:registered_by])
        {
          first_name: self[:first_name],
          last_name: self[:last_name],
          middle_names: self[:middle_names],
          registered_by: { name: scheme[:name], scheme_id: scheme[:scheme_id] },
          scheme_assessor_id: self[:scheme_assessor_id],
          date_of_birth:
            if self[:date_of_birth].methods.include?(:strftime)
              self[:date_of_birth].strftime('%Y-%m-%d')
            else
              Date.parse(self[:date_of_birth])
            end,
          contact_details: {
            telephone_number: self[:telephone_number], email: self[:email]
          },
          search_results_comparison_postcode:
            self[:search_results_comparison_postcode],
          qualifications: {
            domestic_energy_performance_certificates:
              if self[:domestic_energy_performance_qualification] == 'ACTIVE'
                'ACTIVE'
              else
                'INACTIVE'
              end
          }
        }
      end
    end

    class Scheme < ActiveRecord::Base; end

    def to_hash(assessor)
      {
        first_name: assessor[:first_name],
        last_name: assessor[:last_name],
        middle_names: assessor[:middle_names],
        registered_by: assessor[:registered_by],
        scheme_assessor_id: assessor[:scheme_assessor_id],
        date_of_birth:
          if assessor[:date_of_birth].methods.include?(:strftime)
            assessor[:date_of_birth].strftime('%Y-%m-%d')
          else
            Date.parse(assessor[:date_of_birth])
          end,
        contact_details: {
          telephone_number: assessor[:telephone_number], email: assessor[:email]
        },
        search_results_comparison_postcode:
          assessor[:search_results_comparison_postcode],
        qualifications: {
          domestic_energy_performance_certificates:
            if assessor[:domestic_energy_performance_qualification] == 'ACTIVE'
              'ACTIVE'
            else
              'INACTIVE'
            end
        }
      }
    end

    def fetch(scheme_assessor_id)
      assessor = Assessor.find_by(scheme_assessor_id: scheme_assessor_id)
      assessor ? assessor.to_hash_with_scheme : nil
    end

    def fetch_list(scheme_id)
      assessor = Assessor.where(registered_by: scheme_id)
      assessor.map(&:to_hash_with_scheme)
    end

    def update(scheme_assessor_id, registered_by, assessor_details)
      assessor = assessor_details.dup
      assessor[:registered_by] = registered_by
      assessor[:scheme_assessor_id] = scheme_assessor_id

      existing_assessor =
        Assessor.find_by(
          scheme_assessor_id: scheme_assessor_id, registered_by: registered_by
        )

      assessor = flatten(assessor)

      if existing_assessor
        existing_assessor.update(assessor)
      else
        Assessor.create(assessor)
      end
    end

    def search(latitude, longitude, entries = 10)
      qualification = 'domestic_energy_performance_qualification'

      response =
        Assessor.connection.execute(
          "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email, c.name AS scheme_name,
          search_results_comparison_postcode, domestic_energy_performance_qualification,
          (
            sqrt(abs(POWER(69.1 * (a.latitude - #{
            latitude.to_f
          } ), 2) +
            POWER(69.1 * (a.longitude - #{
            longitude.to_f
          } ) * cos( #{
            latitude.to_f
          } / 57.3), 2)))
          ) AS distance

        FROM postcode_geolocation a
        INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
        LEFT JOIN schemes c ON(b.registered_by = c.scheme_id)
        WHERE
          #{
            qualification
          } = 'ACTIVE'
          AND a.latitude BETWEEN #{
            (latitude - 1).to_f
          } AND #{(latitude + 1).to_f}
          AND a.longitude BETWEEN #{
            (longitude - 1).to_f
          } AND #{(longitude + 1).to_f}

        ORDER BY distance LIMIT #{
            entries
          }"
        )

      result = []
      response.each do |row|
        assessor =
          Domain::Assessor.new(
            row['scheme_assessor_id'],
            row['first_name'],
            row['last_name'],
            row['middle_names'],
            row['date_of_birth'],
            row['email'],
            row['telephone_number'],
            row['registered_by'],
            row['scheme_name'],
            row['search_results_comparison_postcode'],
            row['domestic_energy_performance_qualification']
          )

        distance_result = row['distance']
        full_hash = { assessor: assessor.to_hash, distance: distance_result }

        result.push(full_hash)
      end
      result
    end

    def search_by(
      name: '', max_response_size: 20, loose_match: false, exclude: []
    )
      sql =
        'SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email,
          search_results_comparison_postcode, domestic_energy_performance_qualification

        FROM assessors
        WHERE
          1=1
      '

      unless exclude.empty?
        sql << "AND scheme_assessor_id NOT IN('" + exclude.join("', '") + "')"
      end

      if loose_match
        names = name.split(' ')

        sql <<
          " AND((first_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[0])
          }%' AND last_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[1])
          }%')"
        sql <<
          " OR (first_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[1])
          }%' AND last_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[0])
          }%'))"
      else
        sql <<
          " AND CONCAT(first_name, ' ', last_name) ILIKE '#{
            ActiveRecord::Base.sanitize_sql(name)
          }'"
        sql << 'LIMIT ' + (max_response_size + 1).to_s if max_response_size > 0
      end

      response = Assessor.connection.execute(sql)

      result = []
      response.each { |row| result.push(to_hash(row.symbolize_keys)) }
      result
    end

    private

    def flatten(assessor)
      assessor[:telephone_number] =
        if assessor.key?(:contact_details)
          assessor[:contact_details][:telephone_number]
        else
          ''
        end
      assessor[:email] =
        if assessor.key?(:contact_details)
          assessor[:contact_details][:email]
        else
          ''
        end
      assessor[:domestic_energy_performance_qualification] =
        if (
             assessor[:qualifications] &&
               assessor[:qualifications][
                 :domestic_energy_performance_certificates
               ]
           )
          assessor[:qualifications][:domestic_energy_performance_certificates]
        else
          nil
        end
      assessor.delete(:contact_details)
      assessor.delete(:qualifications)
      assessor
    end
  end
end
