task :speed_test do
  latitude = 51.5296754681241.to_s
  longitude = -0.042065456864592.to_s

  db = ActiveRecord::Base.connection






  puts 'Order by distance, square within 2 lat/long'
  start = Time.now
  result = db.execute("SELECT * FROM postcode_geolocation WHERE
    latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
    AND
    longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

    ORDER BY power(longitude - "+longitude+", 2)+power(latitude - "+latitude+", 2) LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts "Get distance"
  start = Time.now
  result.map do |row|
    target = [latitude, longitude]

    assessor = [row['latitude'], row['longitude']]

    row['distance'] = Geocoder::Calculations.distance_between target, assessor, units: :mi

    row
  end
  puts(((Time.now - start)*1000).to_s+" milliseconds")

  puts "Sort"
  start = Time.now
  result.sort_by do |v|
    v[:distance]
  end
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order by distance, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (latitude - "+latitude+"), 2) + POWER(69.1 * (longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM postcode_geolocation

WHERE
latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1


ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order by distance, precise within 2 lat/long, filtered by existing assessors postcodes'
  start = Time.now
  result = db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (latitude - "+latitude+"), 2) + POWER(69.1 * (longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM postcode_geolocation

WHERE
status = true
AND latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1


ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get those within that postcode'
  start = Time.now

  postcodes = []

  result.map do |row|
    postcodes.push(row['search_results_comparison_postcode'])
  end

  result = db.execute("SELECT * FROM assessors a LEFT JOIN postcode_geolocation b ON(a.search_results_comparison_postcode = b.postcode) WHERE postcode IN('"+postcodes.join("', '")+"')")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Order those assessors'
  start = Time.now
  result.map do |row|
    target = [latitude, longitude]

    assessor = [row['latitude'], row['longitude']]

    row['distance'] = Geocoder::Calculations.distance_between target, assessor, units: :mi

    row
  end
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order assessors by internal lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (latitude - "+latitude+"), 2) + POWER(69.1 * (longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM assessors

ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order assessors by internal lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (latitude - "+latitude+"), 2) + POWER(69.1 * (longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM assessors

ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order assessors by internal lat/long, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (latitude - "+latitude+"), 2) + POWER(69.1 * (longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM assessors

WHERE
latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order assessors by internal lat/long, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (latitude - "+latitude+"), 2) + POWER(69.1 * (longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM assessors

WHERE
latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order assessors by joined lat/long, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (b.latitude - "+latitude+"), 2) + POWER(69.1 * (b.longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM assessors a
LEFT JOIN postcode_geolocation b ON(a.search_results_comparison_postcode = b.postcode)
WHERE
b.latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND b.longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get & order assessors by joined lat/long square, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *

FROM assessors a
LEFT JOIN postcode_geolocation b ON(a.search_results_comparison_postcode = b.postcode)
WHERE
b.latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND b.longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

ORDER BY power(b.longitude - "+longitude+", 2)+power(b.latitude - "+latitude+", 2) LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get assessors by inner joined postcode, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *

FROM postcode_geolocation a
INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
WHERE
a.latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND a.longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

ORDER BY power(a.longitude - "+longitude+", 2)+power(a.latitude - "+latitude+", 2) LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")






  puts 'Get assessors by inner joined postcode, precise within 2 lat/long'
  start = Time.now
  db.execute("SELECT *,

(
    sqrt(abs(POWER(69.1 * (a.latitude - "+latitude+"), 2) + POWER(69.1 * (a.longitude - "+longitude+") * cos("+latitude+" / 57.3), 2)))
) AS distance

FROM postcode_geolocation a
INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
WHERE
a.latitude BETWEEN "+latitude+"-1 AND "+latitude+"+1
AND a.longitude BETWEEN "+longitude+"-1 AND "+longitude+"+1

ORDER BY distance LIMIT 100")
  puts(((Time.now - start)*1000).to_s+" milliseconds")
end
