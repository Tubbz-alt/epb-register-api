module Gateway
  class RelatedAssessmentsGateway
    class Assessment < ActiveRecord::Base; end

    def by_address_id(address_id)
      sql = <<-SQL
        SELECT all_assessments.assessment_id,
               all_assessments.assessment_type,
               all_assessments.date_of_expiry,
               CASE WHEN all_assessments.cancelled_at IS NOT NULL THEN 'CANCELLED'
                    WHEN all_assessments.not_for_issue_at IS NOT NULL THEN 'NOT_FOR_ISSUE'
                    WHEN all_assessments.date_of_expiry < CURRENT_DATE THEN 'EXPIRED'
                    ELSE 'ENTERED'
                   END AS assessment_status
        FROM (
            SELECT a.assessment_id,
               a.type_of_assessment AS assessment_type,
               a.date_of_expiry,
               a.cancelled_at,
               a.not_for_issue_at
            FROM (
                WITH RECURSIVE
                forwards AS (
                  SELECT a.assessment_id, a.address_id FROM assessments a WHERE a.address_id = $1
                  UNION
                  SELECT a_forwards.assessment_id, a_forwards.address_id FROM assessments a_forwards
                  INNER JOIN forwards f ON REPLACE(a_forwards.address_id, 'RRN-', '') = f.assessment_id
                ),
                backwards AS (
                  SELECT a.assessment_id, a.address_id FROM assessments a WHERE a.address_id = $1
                  UNION
                  SELECT a_backwards.assessment_id, a_backwards.address_id FROM assessments a_backwards
                  INNER JOIN backwards b ON REPLACE(b.address_id, 'RRN-', '') = a_backwards.assessment_id
                )
                SELECT forwards.assessment_id FROM forwards
                UNION
                SELECT backwards.assessment_id FROM backwards
            ) existing_assessments
            INNER JOIN assessments a ON existing_assessments.assessment_id = a.assessment_id
            WHERE existing_assessments.assessment_id != REPLACE($1, 'RRN-', '')
        ) as all_assessments
        ORDER BY date_of_expiry DESC, assessment_id DESC
      SQL

      results =
        ActiveRecord::Base.connection.exec_query(
          sql,
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "address_id",
              address_id,
              ActiveRecord::Type::String.new,
            ),
          ],
        )

      output =
        results.map do |result|
          Domain::RelatedAssessment.new(
            assessment_id: result["assessment_id"],
            assessment_status: result["assessment_status"],
            assessment_type: result["assessment_type"],
            assessment_expiry_date: result["date_of_expiry"],
          )
        end

      output.compact
    end
  end
end
