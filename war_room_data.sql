-- War Room: simulated data (all names, events and numbers are fictional). Run after war_room_tables.sql.
USE ROLE WAR_ROOM_ADMIN;
USE WAREHOUSE WAR_ROOM_WH;
USE SCHEMA WAR_ROOM.OPS;

-- suppliers: 6 rows
INSERT INTO suppliers (supplier_id, supplier_name, country, region, risk_tier, contact_email, port_id) VALUES
('S01', 'Formosa Chip Works', 'Taiwan', 'TW-SOUTH', 'HIGH', 'orders@formosachip.example', 'P-KHH'),
('S02', 'Penang Semicon', 'Malaysia', 'MY-PENANG', 'MEDIUM', 'sales@penangsemicon.example', 'P-PEN'),
('S03', 'Gdansk Components', 'Poland', 'PL-GDANSK', 'LOW', 'sales@gdanskcomp.example', 'P-GDN'),
('S04', 'Rhein Sensors', 'Germany', 'DE-NRW', 'LOW', 'info@rheinsensors.example', 'P-HAM'),
('S05', 'Shenzhen Circuit Co', 'China', 'CN-SOUTH', 'MEDIUM', 'export@szcircuit.example', 'P-YAN'),
('S06', 'Nordic Cable Works', 'Sweden', 'SE-GOTHENBURG', 'LOW', 'sales@nordiccable.example', 'P-GOT');

-- inventory: 25 rows
INSERT INTO inventory (sku_id, sku_name, supplier_id, region, warehouse, units_on_hand, daily_demand, unit_cost_eur, reorder_point) VALUES
('SKU-1001', 'Microcontroller MCU-32', 'S01', 'TW-SOUTH', 'GOT-DC1', 3600, 400, 60.0, 5600),
('SKU-1002', 'Power management IC', 'S01', 'TW-SOUTH', 'GOT-DC1', 3500, 250, 45.0, 3500),
('SKU-1003', 'Pressure sensor PS-7', 'S01', 'TW-SOUTH', 'GOT-DC1', 2100, 100, 30.0, 1400),
('SKU-2001', 'Memory module', 'S02', 'MY-PENANG', 'GOT-DC1', 15312, 348, 55.08, 4872),
('SKU-2002', 'Voltage regulator', 'S02', 'MY-PENANG', 'GOT-DC1', 5432, 97, 60.67, 1358),
('SKU-2003', 'Capacitor bank', 'S02', 'MY-PENANG', 'GOT-DC1', 19788, 291, 10.22, 4074),
('SKU-2004', 'RF filter', 'S02', 'MY-PENANG', 'GOT-DC1', 22500, 375, 54.24, 5250),
('SKU-2005', 'LED driver', 'S02', 'MY-PENANG', 'GOT-DC1', 19305, 429, 12.46, 6006),
('SKU-3001', 'Wiring harness', 'S03', 'PL-GDANSK', 'RTM-DC1', 9240, 140, 28.47, 1960),
('SKU-3002', 'Connector set', 'S03', 'PL-GDANSK', 'RTM-DC1', 14694, 237, 46.5, 3318),
('SKU-3003', 'Cable gland', 'S03', 'PL-GDANSK', 'RTM-DC1', 9030, 258, 33.27, 3612),
('SKU-3004', 'Terminal block', 'S03', 'PL-GDANSK', 'RTM-DC1', 12150, 450, 40.6, 6300),
('SKU-3005', 'Relay module', 'S03', 'PL-GDANSK', 'RTM-DC1', 9593, 181, 58.62, 2534),
('SKU-3006', 'Fuse holder', 'S03', 'PL-GDANSK', 'RTM-DC1', 14720, 368, 54.03, 5152),
('SKU-4001', 'Temperature sensor', 'S04', 'DE-NRW', 'RTM-DC1', 16640, 256, 68.07, 3584),
('SKU-4002', 'Proximity sensor', 'S04', 'DE-NRW', 'RTM-DC1', 13002, 394, 55.37, 5516),
('SKU-4003', 'Flow sensor', 'S04', 'DE-NRW', 'RTM-DC1', 7254, 279, 34.8, 3906),
('SKU-4004', 'Encoder', 'S04', 'DE-NRW', 'RTM-DC1', 21285, 387, 14.18, 5418),
('SKU-5001', 'Printed circuit board', 'S05', 'CN-SOUTH', 'GOT-DC1', 15028, 221, 53.15, 3094),
('SKU-5002', 'Display panel', 'S05', 'CN-SOUTH', 'GOT-DC1', 18778, 458, 25.5, 6412),
('SKU-5003', 'Battery cell', 'S05', 'CN-SOUTH', 'GOT-DC1', 13530, 410, 34.99, 5740),
('SKU-5004', 'Switch assembly', 'S05', 'CN-SOUTH', 'GOT-DC1', 16652, 362, 12.57, 5068),
('SKU-6001', 'Power cable', 'S06', 'SE-GOTHENBURG', 'GOT-DC1', 16940, 308, 18.98, 4312),
('SKU-6002', 'Shielded cable', 'S06', 'SE-GOTHENBURG', 'GOT-DC1', 8060, 130, 32.85, 1820),
('SKU-6003', 'Fibre patch cable', 'S06', 'SE-GOTHENBURG', 'GOT-DC1', 3978, 102, 50.22, 1428);

-- shipments: 60 rows
INSERT INTO shipments (shipment_id, po_number, sku_id, supplier_id, region, qty, value_eur, ship_date, eta, status, origin_port) VALUES
('SH-001', 'PO-261002', 'SKU-1001', 'S01', 'TW-SOUTH', 6000, 360000.0, '2026-10-14', '2026-10-27', 'IN_TRANSIT', 'Kaohsiung'),
('SH-002', 'PO-261003', 'SKU-1001', 'S01', 'TW-SOUTH', 5000, 300000.0, '2026-10-18', '2026-10-30', 'AT_PORT', 'Kaohsiung'),
('SH-003', 'PO-261004', 'SKU-1002', 'S01', 'TW-SOUTH', 5000, 225000.0, '2026-10-15', '2026-10-28', 'IN_TRANSIT', 'Kaohsiung'),
('SH-004', 'PO-261005', 'SKU-1003', 'S01', 'TW-SOUTH', 10500, 315000.0, '2026-10-19', '2026-10-31', 'AT_PORT', 'Kaohsiung'),
('SH-005', 'PO-261006', 'SKU-1001', 'S01', 'TW-SOUTH', 5000, 300000.0, '2026-08-20', '2026-09-02', 'DELIVERED', 'Kaohsiung'),
('SH-006', 'PO-261007', 'SKU-1002', 'S01', 'TW-SOUTH', 4000, 180000.0, '2026-09-01', '2026-09-14', 'DELIVERED', 'Kaohsiung'),
('SH-007', 'PO-261008', 'SKU-5002', 'S05', 'CN-SOUTH', 5100, 130050.0, '2026-10-07', '2026-10-29', 'IN_TRANSIT', 'Yantian'),
('SH-008', 'PO-261009', 'SKU-3004', 'S03', 'PL-GDANSK', 2000, 81200.0, '2026-10-10', '2026-10-13', 'DELIVERED', 'Gdansk'),
('SH-009', 'PO-261010', 'SKU-3001', 'S03', 'PL-GDANSK', 4000, 113880.0, '2026-09-29', '2026-10-02', 'DELIVERED', 'Gdansk'),
('SH-010', 'PO-261011', 'SKU-2004', 'S02', 'MY-PENANG', 1500, 81360.0, '2026-10-07', '2026-10-25', 'DELAYED', 'Penang'),
('SH-011', 'PO-261012', 'SKU-5003', 'S05', 'CN-SOUTH', 3000, 104970.0, '2026-10-04', '2026-10-26', 'IN_TRANSIT', 'Yantian'),
('SH-012', 'PO-261013', 'SKU-5001', 'S05', 'CN-SOUTH', 4700, 249805.0, '2026-09-08', '2026-09-30', 'DELIVERED', 'Yantian'),
('SH-013', 'PO-261014', 'SKU-4002', 'S04', 'DE-NRW', 3200, 177184.0, '2026-09-17', '2026-09-21', 'DELIVERED', 'Hamburg'),
('SH-014', 'PO-261015', 'SKU-4002', 'S04', 'DE-NRW', 1200, 66444.0, '2026-08-26', '2026-08-30', 'DELIVERED', 'Hamburg'),
('SH-015', 'PO-261016', 'SKU-3001', 'S03', 'PL-GDANSK', 2900, 82563.0, '2026-08-30', '2026-09-02', 'DELIVERED', 'Gdansk'),
('SH-016', 'PO-261017', 'SKU-4004', 'S04', 'DE-NRW', 3000, 42540.0, '2026-09-28', '2026-10-02', 'DELIVERED', 'Hamburg'),
('SH-017', 'PO-261018', 'SKU-5004', 'S05', 'CN-SOUTH', 900, 11313.0, '2026-09-23', '2026-10-15', 'DELIVERED', 'Yantian'),
('SH-018', 'PO-261019', 'SKU-5002', 'S05', 'CN-SOUTH', 3900, 99450.0, '2026-09-23', '2026-10-15', 'DELIVERED', 'Yantian'),
('SH-019', 'PO-261020', 'SKU-4002', 'S04', 'DE-NRW', 900, 49833.0, '2026-09-22', '2026-09-26', 'DELIVERED', 'Hamburg'),
('SH-020', 'PO-261021', 'SKU-4002', 'S04', 'DE-NRW', 2100, 116277.0, '2026-10-05', '2026-10-09', 'DELIVERED', 'Hamburg'),
('SH-021', 'PO-261022', 'SKU-4003', 'S04', 'DE-NRW', 2400, 83520.0, '2026-08-26', '2026-08-30', 'DELIVERED', 'Hamburg'),
('SH-022', 'PO-261023', 'SKU-3005', 'S03', 'PL-GDANSK', 1600, 93792.0, '2026-10-15', '2026-10-18', 'DELIVERED', 'Gdansk'),
('SH-023', 'PO-261024', 'SKU-3002', 'S03', 'PL-GDANSK', 5900, 274350.0, '2026-09-15', '2026-09-18', 'DELIVERED', 'Gdansk'),
('SH-024', 'PO-261025', 'SKU-5004', 'S05', 'CN-SOUTH', 1700, 21369.0, '2026-08-26', '2026-09-17', 'DELIVERED', 'Yantian'),
('SH-025', 'PO-261026', 'SKU-5004', 'S05', 'CN-SOUTH', 5200, 65364.0, '2026-08-28', '2026-09-19', 'DELIVERED', 'Yantian'),
('SH-026', 'PO-261027', 'SKU-3002', 'S03', 'PL-GDANSK', 2100, 97650.0, '2026-10-11', '2026-10-14', 'DELIVERED', 'Gdansk'),
('SH-027', 'PO-261028', 'SKU-3005', 'S03', 'PL-GDANSK', 1100, 64482.0, '2026-09-28', '2026-10-01', 'DELIVERED', 'Gdansk'),
('SH-028', 'PO-261029', 'SKU-4002', 'S04', 'DE-NRW', 4800, 265776.0, '2026-09-20', '2026-09-24', 'DELIVERED', 'Hamburg'),
('SH-029', 'PO-261030', 'SKU-6003', 'S06', 'SE-GOTHENBURG', 2700, 135594.0, '2026-09-28', '2026-09-30', 'DELIVERED', 'Gothenburg'),
('SH-030', 'PO-261031', 'SKU-3004', 'S03', 'PL-GDANSK', 4900, 198940.0, '2026-09-15', '2026-09-18', 'DELIVERED', 'Gdansk'),
('SH-031', 'PO-261032', 'SKU-3003', 'S03', 'PL-GDANSK', 2300, 76521.0, '2026-09-02', '2026-09-05', 'DELIVERED', 'Gdansk'),
('SH-032', 'PO-261033', 'SKU-2001', 'S02', 'MY-PENANG', 900, 49572.0, '2026-08-30', '2026-09-17', 'DELIVERED', 'Penang'),
('SH-033', 'PO-261034', 'SKU-5002', 'S05', 'CN-SOUTH', 4400, 112200.0, '2026-10-01', '2026-10-23', 'IN_TRANSIT', 'Yantian'),
('SH-034', 'PO-261035', 'SKU-2004', 'S02', 'MY-PENANG', 3200, 173568.0, '2026-10-10', '2026-10-28', 'IN_TRANSIT', 'Penang'),
('SH-035', 'PO-261036', 'SKU-3006', 'S03', 'PL-GDANSK', 3200, 172896.0, '2026-09-30', '2026-10-03', 'DELIVERED', 'Gdansk'),
('SH-036', 'PO-261037', 'SKU-3005', 'S03', 'PL-GDANSK', 2500, 146550.0, '2026-09-02', '2026-09-05', 'DELIVERED', 'Gdansk'),
('SH-037', 'PO-261038', 'SKU-3001', 'S03', 'PL-GDANSK', 4200, 119574.0, '2026-09-09', '2026-09-12', 'DELIVERED', 'Gdansk'),
('SH-038', 'PO-261039', 'SKU-4003', 'S04', 'DE-NRW', 2400, 83520.0, '2026-09-25', '2026-09-29', 'DELIVERED', 'Hamburg'),
('SH-039', 'PO-261040', 'SKU-6003', 'S06', 'SE-GOTHENBURG', 2300, 115506.0, '2026-08-29', '2026-08-31', 'DELIVERED', 'Gothenburg'),
('SH-040', 'PO-261041', 'SKU-2003', 'S02', 'MY-PENANG', 5700, 58254.0, '2026-09-11', '2026-09-29', 'DELIVERED', 'Penang'),
('SH-041', 'PO-261042', 'SKU-3004', 'S03', 'PL-GDANSK', 3200, 129920.0, '2026-10-11', '2026-10-14', 'DELIVERED', 'Gdansk'),
('SH-042', 'PO-261043', 'SKU-5001', 'S05', 'CN-SOUTH', 1900, 100985.0, '2026-09-17', '2026-10-09', 'DELIVERED', 'Yantian'),
('SH-043', 'PO-261044', 'SKU-5002', 'S05', 'CN-SOUTH', 1900, 48450.0, '2026-10-14', '2026-11-05', 'IN_TRANSIT', 'Yantian'),
('SH-044', 'PO-261045', 'SKU-5001', 'S05', 'CN-SOUTH', 2900, 154135.0, '2026-10-05', '2026-10-27', 'IN_TRANSIT', 'Yantian'),
('SH-045', 'PO-261046', 'SKU-2002', 'S02', 'MY-PENANG', 2900, 175943.0, '2026-08-30', '2026-09-17', 'DELIVERED', 'Penang'),
('SH-046', 'PO-261047', 'SKU-6001', 'S06', 'SE-GOTHENBURG', 3000, 56940.0, '2026-08-31', '2026-09-02', 'DELIVERED', 'Gothenburg'),
('SH-047', 'PO-261048', 'SKU-5001', 'S05', 'CN-SOUTH', 4400, 233860.0, '2026-09-04', '2026-09-26', 'DELIVERED', 'Yantian'),
('SH-048', 'PO-261049', 'SKU-3002', 'S03', 'PL-GDANSK', 3600, 167400.0, '2026-10-06', '2026-10-09', 'DELIVERED', 'Gdansk'),
('SH-049', 'PO-261050', 'SKU-4002', 'S04', 'DE-NRW', 3000, 166110.0, '2026-09-03', '2026-09-07', 'DELIVERED', 'Hamburg'),
('SH-050', 'PO-261051', 'SKU-5004', 'S05', 'CN-SOUTH', 4600, 57822.0, '2026-08-26', '2026-09-17', 'DELIVERED', 'Yantian'),
('SH-051', 'PO-261052', 'SKU-3006', 'S03', 'PL-GDANSK', 4100, 221523.0, '2026-10-01', '2026-10-04', 'DELIVERED', 'Gdansk'),
('SH-052', 'PO-261053', 'SKU-3005', 'S03', 'PL-GDANSK', 3900, 228618.0, '2026-09-10', '2026-09-13', 'DELIVERED', 'Gdansk'),
('SH-053', 'PO-261054', 'SKU-2004', 'S02', 'MY-PENANG', 1000, 54240.0, '2026-09-24', '2026-10-12', 'DELIVERED', 'Penang'),
('SH-054', 'PO-261055', 'SKU-4004', 'S04', 'DE-NRW', 900, 12762.0, '2026-09-26', '2026-09-30', 'DELIVERED', 'Hamburg'),
('SH-055', 'PO-261056', 'SKU-5002', 'S05', 'CN-SOUTH', 4800, 122400.0, '2026-09-15', '2026-10-07', 'DELIVERED', 'Yantian'),
('SH-056', 'PO-261057', 'SKU-2001', 'S02', 'MY-PENANG', 3200, 176256.0, '2026-09-03', '2026-09-21', 'DELIVERED', 'Penang'),
('SH-057', 'PO-261058', 'SKU-2005', 'S02', 'MY-PENANG', 4100, 51086.0, '2026-09-11', '2026-09-29', 'DELIVERED', 'Penang'),
('SH-058', 'PO-261059', 'SKU-2004', 'S02', 'MY-PENANG', 1000, 54240.0, '2026-09-29', '2026-10-17', 'DELIVERED', 'Penang'),
('SH-059', 'PO-261060', 'SKU-2004', 'S02', 'MY-PENANG', 4800, 260352.0, '2026-09-24', '2026-10-12', 'DELIVERED', 'Penang'),
('SH-060', 'PO-261061', 'SKU-2004', 'S02', 'MY-PENANG', 5500, 298320.0, '2026-09-09', '2026-09-27', 'DELIVERED', 'Penang');

-- news_feed: 20 rows
INSERT INTO news_feed (alert_id, published_at, source, region, event_type, severity, headline, body) VALUES
('A01', '2026-10-20 14:00', 'Simulated Weather Service', 'TW-SOUTH', 'WEATHER', 'HIGH', 'Typhoon Meilin intensifies and is expected to hit southern Taiwan within 48 hours', 'Typhoon Meilin has strengthened over the Philippine Sea. Landfall is forecast near Kaohsiung on 22 October with sustained winds above 170 km/h. Authorities urge industry to prepare.'),
('A02', '2026-10-21 08:30', 'Simulated Port Authority', 'TW-SOUTH', 'PORT', 'HIGH', 'Kaohsiung port to suspend operations for 48 to 72 hours', 'The port authority will suspend container operations from 21 October as Typhoon Meilin approaches. Vessels are being redirected and cargo handling will stop until the all-clear.'),
('A03', '2026-10-21 16:45', 'Simulated Logistics Wire', 'TW-SOUTH', 'LOGISTICS', 'HIGH', 'Airlines cancel Kaohsiung cargo flights as typhoon nears', 'Major carriers cancelled air cargo flights to and from Kaohsiung through 24 October, limiting expedited shipping options out of southern Taiwan.'),
('A04', '2026-10-21 14:00', 'Simulated Wire', 'NL-ROTTERDAM', 'PORT', 'MEDIUM', 'Rotterdam terminal workers announce a 24-hour strike', 'Strike action planned next week may delay container pickups for one day.'),
('A05', '2026-10-17 10:00', 'Simulated Wire', 'PL-GDANSK', 'WEATHER', 'LOW', 'Light rain forecast for Gdansk this week', 'No disruption to port operations expected.'),
('A06', '2026-10-18 14:00', 'Simulated Wire', 'GLOBAL', 'FUEL', 'MEDIUM', 'Bunker fuel prices rise 4% week on week', 'Freight rates may edge up on long-haul routes.'),
('A07', '2026-10-16 06:00', 'Simulated Wire', 'DE-NRW', 'LOGISTICS', 'LOW', 'Rail freight timetable update for the Rhine corridor', 'Minor schedule changes from November.'),
('A08', '2026-10-15 19:00', 'Simulated Wire', 'CN-SOUTH', 'PORT', 'MEDIUM', 'Yantian terminal reports moderate congestion', 'Waiting time for berths is about 2 days.'),
('A09', '2026-10-17 12:00', 'Simulated Wire', 'MY-PENANG', 'WEATHER', 'LOW', 'Seasonal monsoon showers in northern Malaysia', 'No impact on port operations expected.'),
('A10', '2026-10-17 16:00', 'Simulated Wire', 'SE-GOTHENBURG', 'PORT', 'LOW', 'Gothenburg port opens a new rail shuttle', 'Extra capacity for inland transport from December.'),
('A11', '2026-10-14 07:00', 'Simulated Wire', 'GLOBAL', 'TRADE', 'MEDIUM', 'Customs authorities update electronics declaration form', 'New form required from January for some components.'),
('A12', '2026-10-16 12:00', 'Simulated Wire', 'TW-NORTH', 'WEATHER', 'LOW', 'Cloudy weather in northern Taiwan', 'No disruption to Keelung or Taipei operations.'),
('A13', '2026-10-19 12:00', 'Simulated Wire', 'PL-GDANSK', 'LABOR', 'LOW', 'Union talks at Polish manufacturers continue', 'No strike notice has been issued.'),
('A14', '2026-10-17 19:00', 'Simulated Wire', 'CN-SOUTH', 'POLICY', 'MEDIUM', 'Export licence review for some semiconductors', 'Review expected to take two weeks.'),
('A15', '2026-10-15 14:00', 'Simulated Wire', 'SE-GOTHENBURG', 'WEATHER', 'LOW', 'Cold snap forecast for western Sweden', 'Road transport may slow slightly.'),
('A16', '2026-10-18 12:00', 'Simulated Wire', 'GLOBAL', 'MARKET', 'LOW', 'Container spot rates steady this week', 'Asia to Europe rates broadly flat.'),
('A17', '2026-10-20 09:00', 'Simulated Wire', 'MY-PENANG', 'LABOR', 'MEDIUM', 'Penang free trade zone worker shortage reported', 'Some suppliers report slower hiring.'),
('A18', '2026-10-21 10:00', 'Simulated Wire', 'DE-NRW', 'WEATHER', 'LOW', 'Low water levels on the Rhine', 'Barge loads reduced by about 10%.'),
('A19', '2026-10-18 13:00', 'Simulated Wire', 'NL-ROTTERDAM', 'PORT', 'LOW', 'Rotterdam extends gate hours', 'Longer pickup windows next month.'),
('A20', '2026-10-20 12:00', 'Simulated Wire', 'CN-SOUTH', 'WEATHER', 'LOW', 'Light fog near Shenzhen harbour', 'Ferry delays of up to 1 hour.');

-- supplier_documents: 10 rows
INSERT INTO supplier_documents (doc_id, supplier_id, region, doc_type, file_name, doc_date, content) VALUES
('D01', 'S01', 'TW-SOUTH', 'CONTRACT', 'formosa_master_supply_agreement.pdf', '2025-04-01', 'MASTER SUPPLY AGREEMENT
Between Nordlys Electronics AB (Buyer) and Formosa Chip Works Ltd (Supplier).

5.1 Pricing. Unit prices are fixed in EUR for 12 months: SKU-1001 EUR 60.00, SKU-1002 EUR 45.00, SKU-1003 EUR 30.00.
7.1 Delivery. Supplier ships within 10 business days of a purchase order.
7.2 Expedited shipping. On written request from Buyer, Supplier shall arrange expedited shipping of any open order. Buyer bears the additional freight cost.
9.4 Quality. Defective lots are replaced at Supplier''s expense within 30 days.
11.3 Force majeure. Supplier''s obligations are suspended for the duration of a typhoon declared by the national weather authority. Supplier must notify Buyer within 24 hours and resume shipments within 5 business days of the all-clear.
12.1 Termination. Either party may terminate with 90 days written notice.'),
('D02', 'S02', 'MY-PENANG', 'CONTRACT', 'penang_frame_agreement.pdf', '2025-06-15', 'FRAME AGREEMENT
Between Nordlys Electronics AB (Buyer) and Penang Semicon Sdn Bhd (Supplier).

3.1 Capacity. Supplier reserves up to 10,000 units per month for Buyer at agreed prices.
3.2 Surge orders. Orders above reserved capacity are accepted subject to availability and a quote.
6.1 Payment. 45 days net.
8.2 Force majeure. Standard clause; suspension limited to the duration of the event.'),
('D03', 'S03', 'PL-GDANSK', 'CONTRACT', 'gdansk_supply_contract.pdf', '2025-02-10', 'SUPPLY CONTRACT
Between Nordlys Electronics AB (Buyer) and Gdansk Components Sp. z o.o. (Supplier).

4.1 Delivery. Weekly deliveries by road, 3 days transit.
4.4 Late delivery. A penalty of 0.5 percent per day applies after 3 days of delay, capped at 5 percent.
9.1 Force majeure. Applies to events beyond reasonable control; notice within 48 hours.'),
('D04', 'S01', 'TW-SOUTH', 'EMAIL', 'email_formosa_typhoon_notice.eml', '2026-10-21', 'From: orders@formosachip.example
To: supply@nordlys.example
Date: 21 Oct 2026
Subject: Typhoon Meilin: preparedness notice

Dear Nordlys team,
Typhoon Meilin is expected to reach Kaohsiung on 22 October. The port will be closed for an estimated 48 to 72 hours. two of your open orders are still at the port. If you wish to use expedited shipping under clause 7.2, please send a written request today. Please note that under clause 11.3 our obligations are suspended during the typhoon.
Regards, Formosa Chip Works'),
('D05', 'S01', 'TW-SOUTH', 'EMAIL', 'email_formosa_capacity_update.eml', '2026-09-12', 'From: orders@formosachip.example
To: supply@nordlys.example
Date: 12 Sep 2026
Subject: Capacity update

Our production lines run at 92 percent utilisation. Lead time for new orders is currently 10 business days. We can absorb a 10 percent increase in your monthly volume.'),
('D06', 'S03', 'PL-GDANSK', 'EMAIL', 'email_gdansk_price_update.eml', '2026-10-05', 'From: sales@gdanskcomp.example
To: supply@nordlys.example
Date: 5 Oct 2026
Subject: Price update

Copper costs have risen. We will raise prices on cable products by 2 percent from 1 January. Existing orders keep their current price.'),
('D07', 'S04', 'DE-NRW', 'EMAIL', 'email_rhein_delivery_schedule.eml', '2026-10-08', 'From: info@rheinsensors.example
To: supply@nordlys.example
Date: 8 Oct 2026
Subject: Delivery schedule for November

We confirm four deliveries in November, every Tuesday. Please send your forecast by 25 October.'),
('D08', 'S02', 'MY-PENANG', 'QUOTE', 'penang_quote_backup_supply.pdf', '2026-10-21', 'QUOTATION
Penang Semicon Sdn Bhd to Nordlys Electronics AB
Date: 21 Oct 2026. Valid for 14 days.

Items: equivalent parts for SKU-1001, SKU-1002 and SKU-1003.
Unit prices: SKU-1001 EUR 69.00, SKU-1002 EUR 51.75, SKU-1003 EUR 34.50. This is 15 percent above your current prices from Formosa.
Capacity: up to 40,000 units per month.
Lead time: 21 days from order confirmation.
Shipping: by sea from Penang, 18 days transit.'),
('D09', 'S04', 'DE-NRW', 'QUOTE', 'rhein_quote_sensors.pdf', '2026-09-28', 'QUOTATION
Rhein Sensors GmbH to Nordlys Electronics AB
Date: 28 Sep 2026. Valid for 30 days.

Item: Temperature sensor SKU-4001, volume 5,000 units. Unit price EUR 66.40. Lead time 7 days.'),
('D10', 'S03', 'PL-GDANSK', 'QUOTE', 'gdansk_quote_connectors.pdf', '2026-10-02', 'QUOTATION
Gdansk Components to Nordlys Electronics AB
Date: 2 Oct 2026. Valid for 30 days.

Item: Connector set SKU-3002, volume 8,000 units. Unit price EUR 45.10. Lead time 5 days.');

-- viewer_region_access: 9 rows
INSERT INTO viewer_region_access (role_name, region) VALUES
('OPS_GLOBAL', 'TW-SOUTH'),
('OPS_GLOBAL', 'MY-PENANG'),
('OPS_GLOBAL', 'PL-GDANSK'),
('OPS_GLOBAL', 'DE-NRW'),
('OPS_GLOBAL', 'CN-SOUTH'),
('OPS_GLOBAL', 'SE-GOTHENBURG'),
('OPS_EMEA', 'PL-GDANSK'),
('OPS_EMEA', 'DE-NRW'),
('OPS_EMEA', 'SE-GOTHENBURG');

-- typhoon_history: 120 rows
INSERT INTO typhoon_history (typhoon_year, typhoon_month, region, warnings_issued, landfalls, port_closure_days, data_source) VALUES
(2016, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 7, 'TW-SOUTH', 1, 1, 3, 'SIMULATED'),
(2016, 8, 'TW-SOUTH', 1, 1, 3, 'SIMULATED'),
(2016, 9, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2016, 10, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2016, 11, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2016, 12, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2017, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 6, 'TW-SOUTH', 4, 2, 3, 'SIMULATED'),
(2017, 7, 'TW-SOUTH', 2, 0, 0, 'SIMULATED'),
(2017, 8, 'TW-SOUTH', 1, 1, 3, 'SIMULATED'),
(2017, 9, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 10, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2017, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2017, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 4, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2018, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 7, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2018, 8, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2018, 9, 'TW-SOUTH', 2, 1, 1, 'SIMULATED'),
(2018, 10, 'TW-SOUTH', 2, 0, 0, 'SIMULATED'),
(2018, 11, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2018, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 2, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2019, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 7, 'TW-SOUTH', 2, 2, 4, 'SIMULATED'),
(2019, 8, 'TW-SOUTH', 2, 0, 0, 'SIMULATED'),
(2019, 9, 'TW-SOUTH', 2, 1, 2, 'SIMULATED'),
(2019, 10, 'TW-SOUTH', 2, 1, 1, 'SIMULATED'),
(2019, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2019, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 6, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2020, 7, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2020, 8, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2020, 9, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2020, 10, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2020, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 7, 'TW-SOUTH', 2, 0, 0, 'SIMULATED'),
(2021, 8, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2021, 9, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2021, 10, 'TW-SOUTH', 1, 1, 3, 'SIMULATED'),
(2021, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2021, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 4, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2022, 5, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2022, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 7, 'TW-SOUTH', 2, 1, 2, 'SIMULATED'),
(2022, 8, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2022, 9, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2022, 10, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2022, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2023, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2023, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2023, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2023, 4, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2023, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2023, 6, 'TW-SOUTH', 2, 1, 3, 'SIMULATED'),
(2023, 7, 'TW-SOUTH', 1, 1, 1, 'SIMULATED'),
(2023, 8, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2023, 9, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2023, 10, 'TW-SOUTH', 1, 1, 1, 'SIMULATED'),
(2023, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2023, 12, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2024, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 7, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2024, 8, 'TW-SOUTH', 2, 1, 3, 'SIMULATED'),
(2024, 9, 'TW-SOUTH', 3, 1, 3, 'SIMULATED'),
(2024, 10, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 11, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2024, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 1, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 2, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 3, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 4, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 5, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 6, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 7, 'TW-SOUTH', 1, 0, 0, 'SIMULATED'),
(2025, 8, 'TW-SOUTH', 0, 0, 0, 'SIMULATED'),
(2025, 9, 'TW-SOUTH', 2, 1, 2, 'SIMULATED'),
(2025, 10, 'TW-SOUTH', 2, 1, 1, 'SIMULATED'),
(2025, 11, 'TW-SOUTH', 1, 1, 2, 'SIMULATED'),
(2025, 12, 'TW-SOUTH', 0, 0, 0, 'SIMULATED');

-- past_disruptions: 8 rows
INSERT INTO past_disruptions (event_id, event_date, region, event_type, port_closed_days, shipments_delayed, cost_eur, lesson) VALUES
('D-001', '2019-09-12', 'TW-SOUTH', 'TYPHOON', 2, 3, 85000, 'Port closed 2 days. Reorder was placed after the warning, not before. Lesson: reorder when a storm is named, not when it is declared.'),
('D-002', '2021-10-03', 'TW-SOUTH', 'TYPHOON', 3, 5, 140000, 'Three shipments missed the vessel. Lesson: keep two extra weeks of stock for Taiwan-sourced parts from July to October.'),
('D-003', '2022-03-28', 'CN-SOUTH', 'LOCKDOWN', 9, 7, 210000, 'Shenzhen lockdown closed the terminal 9 days. Lesson: qualify a second supplier outside the region.'),
('D-004', '2023-07-20', 'TW-SOUTH', 'TYPHOON', 1, 2, 40000, 'Short closure, limited impact. Lesson: expedited shipping under the contract worked when requested early.'),
('D-005', '2023-12-05', 'NL-ROTTERDAM', 'STRIKE', 4, 4, 60000, 'Rotterdam strike delayed pickups. Lesson: route urgent parts through Hamburg.'),
('D-006', '2024-09-09', 'TW-SOUTH', 'TYPHOON', 3, 6, 410000, 'Port closed 3 days; SKU-1001 ran out on day 9 because cover was already low. Lesson: do not let cover on single-source parts fall below 20 days in typhoon season.'),
('D-007', '2025-08-14', 'PL-GDANSK', 'FLOOD', 2, 2, 25000, 'Flooding closed a road for 2 days. Lesson: Gdansk has a quick alternative by rail.'),
('D-008', '2025-09-22', 'TW-SOUTH', 'TYPHOON', 2, 4, 120000, 'Early expedite request under clause 7.2 saved two shipments. Lesson: send the written request the same day as the alert.');

-- ports: 6 rows
INSERT INTO ports (port_id, port_name, country, region, latitude, longitude) VALUES
('P-KHH', 'Kaohsiung', 'Taiwan', 'TW-SOUTH', 22.62, 120.3),
('P-PEN', 'Penang', 'Malaysia', 'MY-PENANG', 5.42, 100.33),
('P-GDN', 'Gdansk', 'Poland', 'PL-GDANSK', 54.35, 18.65),
('P-HAM', 'Hamburg', 'Germany', 'DE-NRW', 53.55, 9.97),
('P-YAN', 'Yantian', 'China', 'CN-SOUTH', 22.57, 114.28),
('P-GOT', 'Gothenburg', 'Sweden', 'SE-GOTHENBURG', 57.71, 11.97);

-- typhoon_track: 6 rows
INSERT INTO typhoon_track (track_id, point_order, observed_at, latitude, longitude, wind_kph) VALUES
('MEILIN-2026', 1, '2026-10-20 06:00', 19.8, 128.4, 150),
('MEILIN-2026', 2, '2026-10-20 18:00', 20.6, 126.0, 160),
('MEILIN-2026', 3, '2026-10-21 06:00', 21.3, 123.9, 175),
('MEILIN-2026', 4, '2026-10-21 18:00', 21.9, 122.1, 185),
('MEILIN-2026', 5, '2026-10-22 06:00', 22.4, 120.9, 170),
('MEILIN-2026', 6, '2026-10-22 12:00', 22.6, 120.3, 150);

SELECT 'suppliers' t, COUNT(*) n FROM suppliers UNION ALL SELECT 'inventory',COUNT(*) FROM inventory UNION ALL SELECT 'shipments',COUNT(*) FROM shipments UNION ALL SELECT 'news_feed',COUNT(*) FROM news_feed UNION ALL SELECT 'supplier_documents',COUNT(*) FROM supplier_documents UNION ALL SELECT 'viewer_region_access',COUNT(*) FROM viewer_region_access UNION ALL SELECT 'typhoon_history',COUNT(*) FROM typhoon_history UNION ALL SELECT 'past_disruptions',COUNT(*) FROM past_disruptions UNION ALL SELECT 'ports',COUNT(*) FROM ports UNION ALL SELECT 'typhoon_track',COUNT(*) FROM typhoon_track;


-- Check 1: history matches past disruptions. Expect 0 rows.
SELECT d.event_id, d.port_closed_days, h.port_closure_days
FROM past_disruptions d JOIN typhoon_history h
  ON h.typhoon_year = YEAR(d.event_date) AND h.typhoon_month = MONTH(d.event_date) AND h.region = d.region
WHERE d.event_type = 'TYPHOON' AND d.port_closed_days <> h.port_closure_days;

-- Check 2: every history row has the new region. Expect 1 row: TW-SOUTH, 120
SELECT region, COUNT(*) FROM typhoon_history GROUP BY region;

-- Check 3: quote prices. Expect D09 'EUR 66.40', D10 'EUR 45.10'
SELECT doc_id, REGEXP_SUBSTR(content, 'EUR [0-9.]+') AS price FROM supplier_documents WHERE doc_id IN ('D09','D10');