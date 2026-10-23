-- War Room: upcoming shipments from several ports + storm history per port (real NOAA storms for the Asian ports).
-- Run AFTER war_room_real_data_pipeline.sql (it needs the table IBTRACS_RAW). Written from the Snowflake docs, NOT run in Snowflake yet.
-- All company, supplier and shipment data below is simulated. The storm history is real (NOAA IBTrACS, West Pacific).
-- "Today" in the scenario is 22 Oct 2026. Safe to run twice.
USE SCHEMA war_room.ops;

-- 1. More ports (the Asian ones are in the typhoon region)
DELETE FROM ports WHERE port_id IN ('P-SHA', 'P-PUS', 'P-YOK', 'P-MNL', 'P-HPH');
INSERT INTO ports (port_id, port_name, country, region, latitude, longitude) VALUES
('P-SHA', 'Shanghai', 'China', 'CN-EAST', 31.23, 121.47),
('P-PUS', 'Busan', 'South Korea', 'KR-SOUTH', 35.10, 129.04),
('P-YOK', 'Yokohama', 'Japan', 'JP-KANTO', 35.44, 139.64),
('P-MNL', 'Manila', 'Philippines', 'PH-LUZON', 14.60, 120.97),
('P-HPH', 'Haiphong', 'Vietnam', 'VN-NORTH', 20.86, 106.68);

-- 2. The global viewer role sees the new regions too
DELETE FROM viewer_region_access WHERE role_name = 'OPS_GLOBAL' AND region IN ('CN-EAST', 'KR-SOUTH', 'JP-KANTO', 'PH-LUZON', 'VN-NORTH');
INSERT INTO viewer_region_access (role_name, region) VALUES
('OPS_GLOBAL', 'CN-EAST'), ('OPS_GLOBAL', 'KR-SOUTH'), ('OPS_GLOBAL', 'JP-KANTO'), ('OPS_GLOBAL', 'PH-LUZON'), ('OPS_GLOBAL', 'VN-NORTH');

-- 3. Planned shipments for the coming weeks and months (simulated). To add one, INSERT a row here.
CREATE OR REPLACE TABLE planned_shipments (
  shipment_id STRING, port_id STRING, supplier_name STRING, product STRING,
  qty NUMBER, value_eur NUMBER(14,2), sail_date DATE, eta DATE
);
INSERT INTO planned_shipments VALUES
('PS-01', 'P-KHH', 'Formosa Chip Works', 'Microcontroller MCU-32', 6000, 360000, '2026-10-26', '2026-11-08'),
('PS-02', 'P-KHH', 'Formosa Chip Works', 'Power management IC', 8000, 360000, '2026-12-10', '2026-12-23'),
('PS-03', 'P-YAN', 'Shenzhen Circuit Co', 'Display driver board', 4000, 142000, '2026-10-30', '2026-11-20'),
('PS-04', 'P-YAN', 'Shenzhen Circuit Co', 'Connector kit', 6500, 98000, '2026-11-25', '2026-12-16'),
('PS-05', 'P-SHA', 'Shanghai Optics Ltd', 'Camera lens module', 3000, 210000, '2026-11-16', '2026-12-09'),
('PS-06', 'P-SHA', 'Shanghai Optics Ltd', 'Camera lens module', 3000, 210000, '2027-01-08', '2027-01-31'),
('PS-07', 'P-PUS', 'Busan Battery Co', 'Battery cell pack', 5000, 325000, '2026-11-12', '2026-12-04'),
('PS-08', 'P-PUS', 'Busan Battery Co', 'Battery cell pack', 5000, 325000, '2026-12-20', '2027-01-11'),
('PS-09', 'P-YOK', 'Kanto Sensors KK', 'Precision sensor', 2500, 187500, '2026-11-20', '2026-12-12'),
('PS-10', 'P-MNL', 'Luzon Assembly Inc', 'Wiring harness', 9000, 126000, '2026-10-29', '2026-11-22'),
('PS-11', 'P-MNL', 'Luzon Assembly Inc', 'Wiring harness', 9000, 126000, '2026-12-15', '2027-01-08'),
('PS-12', 'P-HPH', 'Red River Plastics', 'Housing shell', 12000, 96000, '2026-11-30', '2026-12-24'),
('PS-13', 'P-HPH', 'Red River Plastics', 'Housing shell', 12000, 96000, '2027-01-15', '2027-02-08'),
('PS-14', 'P-PEN', 'Penang Semicon', 'Memory module', 4000, 220320, '2026-11-10', '2026-11-30'),
('PS-15', 'P-GDN', 'Gdansk Components', 'Cable assembly', 3500, 99750, '2026-10-28', '2026-10-31');

-- 4. Storm history per port (real). A month counts as a storm month when a tropical storm came within 200 km of the port.
CREATE OR REPLACE DYNAMIC TABLE port_storm_history_real
  TARGET_LAG = '1 day' WAREHOUSE = COMPUTE_WH REFRESH_MODE = FULL
AS
WITH pts AS (
  SELECT sid, TRY_TO_TIMESTAMP(iso_time) AS t, TRY_TO_DOUBLE(lat) AS la, TRY_TO_DOUBLE(lon) AS lo
  FROM ibtracs_raw
  WHERE nature = 'TS' AND TRY_TO_DOUBLE(lat) IS NOT NULL AND TRY_TO_TIMESTAMP(iso_time) >= '2016-01-01'
),
monthly AS (
  SELECT p.port_id, YEAR(x.t) AS yr, MONTH(x.t) AS mo,
         COUNT(DISTINCT IFF(HAVERSINE(p.latitude, p.longitude, x.la, x.lo) <= 500, x.sid, NULL)) AS storms_500km,
         COUNT(DISTINCT IFF(HAVERSINE(p.latitude, p.longitude, x.la, x.lo) <= 200, DATE(x.t), NULL)) AS days_200km
  FROM ports p CROSS JOIN pts x GROUP BY 1, 2, 3
),
spine AS (
  SELECT p.port_id, y.value::INT AS yr, m.value::INT AS mo
  FROM ports p, TABLE(FLATTEN(ARRAY_GENERATE_RANGE(2016, 2026))) y, TABLE(FLATTEN(ARRAY_GENERATE_RANGE(1, 13))) m
)
SELECT s.port_id, s.yr AS storm_year, s.mo AS storm_month,
       COALESCE(m.storms_500km, 0) AS storms_500km, COALESCE(m.days_200km, 0) AS storm_days_200km
FROM spine s LEFT JOIN monthly m ON m.port_id = s.port_id AND m.yr = s.yr AND m.mo = s.mo;

ALTER DYNAMIC TABLE port_storm_history_real REFRESH;

-- Checks. Expect 11 ports x 120 months = 1320 rows; Asian ports with storm days, European ports and Penang with about none.
SELECT COUNT(*) AS rows_total FROM port_storm_history_real;
SELECT p.port_name, SUM(h.storm_days_200km) AS storm_days_10y
FROM port_storm_history_real h JOIN ports p ON p.port_id = h.port_id GROUP BY 1 ORDER BY 2 DESC;
SELECT port_id, COUNT(*) AS shipments, MIN(sail_date) AS first_sailing FROM planned_shipments GROUP BY 1 ORDER BY 3;