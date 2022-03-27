----- IMPORTANT COLUMNS FOR ANALYSIS

  SELECT  [county]
      ,[station]
      ,[latitude]
      ,[longitude]
      ,[date]
      ,[rain]
      ,[temp]
      ,[wdsp]
  FROM [PortfolioProject].[dbo].[hrly_Irish_weather]


  ----- COUNTIES AND LAT/LONG

  DROP TABLE PortfolioProject.dbo.counties

  SELECT county,
		ROUND(avg(latitude),5) AS latitude,
		ROUND(avg(longitude),5) AS longitude

  INTO PortfolioProject.dbo.counties
  
  FROM PortfolioProject.dbo.hrly_data_2019

  GROUP BY county



  ----- DATA SELECTION

  DROP TABLE PortfolioProject.dbo.hrly_data_2019

  SELECT county,
		station,
		CAST(latitude AS float) AS latitude, 
		CAST(longitude AS float) AS longitude,
		CAST(date AS date) AS date,
		CAST(date AS time) AS time,
		rain/10 AS rain,
		temp/10 AS temperature,
		CAST(wdsp AS float)*1.852 AS wind_speed --- knot to km/h

  INTO PortfolioProject.dbo.hrly_data_2019

  FROM PortfolioProject.dbo.hrly_Irish_weather

  WHERE date LIKE '2019%'


  ----- AGGREGATED RAIN, TEMP AND WIND SPEED PER COUNTY (AVERAGE BETWEEN STATIONS)
  
  DROP TABLE PortfolioProject.dbo.county_data_2019

  SELECT county,
		date,
		time,
		ROUND(avg(rain),2) AS county_rain,
		ROUND(avg(temperature),2) AS county_temperature,
		ROUND(avg(wind_speed),2) AS county_wind_speed
 
  INTO PortfolioProject.dbo.county_data_2019

  FROM PortfolioProject.dbo.hrly_data_2019

  GROUP BY county, date, time
  ORDER BY county, date, time

  ----- AGGREGATED RAIN, TEMP AND WIND SPEED PER DATE (SUM AND AVERAGE)

  DROP TABLE PortfolioProject.dbo.dly_data_2019

  SELECT county,
		date,
		ROUND(sum(county_rain),2) AS sum_rain,
		ROUND(avg(county_temperature),2) AS avg_temperature,
		ROUND(max(county_temperature),2) AS max_temperature,
		ROUND(min(county_temperature),2) AS min_temperature,
		ROUND(max(county_wind_speed),2) AS max_wind_speed
 
  INTO PortfolioProject.dbo.dly_data_2019

  FROM PortfolioProject.dbo.county_data_2019

  GROUP BY county, date
  ORDER BY county, date


  ----- JOIN BETWEEN AGG DATA AND GEOLOCATION

  DROP TABLE PortfolioProject.dbo.dly_data_2019_geo
  
  SELECT D.county,
		date,
		latitude,
		longitude,
		sum_rain,
		avg_temperature,
		max_temperature,
		min_temperature,
		max_wind_speed
  
  INTO PortfolioProject.dbo.dly_data_2019_geo

  FROM PortfolioProject.dbo.dly_data_2019 D
    
  LEFT JOIN PortfolioProject.dbo.counties C
  
  ON D.county = C.county




  ----- OUTPUT TABLE
 
  DROP TABLE PortfolioProject.dbo.dly_data_output

  SELECT county,
		date,
		latitude,
		longitude,
		sum_rain,
		CASE WHEN sum_rain = 0 THEN 0 
			 ELSE 1 END AS rainy_day_def,
		avg_temperature,
		max_temperature,
		min_temperature,
		max_wind_speed,
		CASE WHEN max_wind_speed < 38 THEN 'Breeze'
			 WHEN max_wind_speed >= 38 AND max_wind_speed < 49 THEN 'Strong breeze'
			 WHEN max_wind_speed >= 49 AND max_wind_speed < 88 THEN 'Gale'
			 WHEN max_wind_speed >= 88 THEN 'Storm'
			 ELSE 'No data' END AS wind_class
  
  INTO PortfolioProject.dbo.dly_data_output

  FROM PortfolioProject.dbo.dly_data_2019_geo



  ------- END