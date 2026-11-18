-- Seed Mars exploration regions
INSERT INTO mars_regions (
    name,
    description,
    center_longitude,
    center_latitude
) VALUES
(
    'Jezero Crater',
    'Ancient crater lake and river delta system explored by Perseverance rover & Ingenuity helicopter',
    77.4,
    18.4
),
(
    'Gale Crater',
    'Curiosity rover exploration region inside Mount Sharp (Aeolis Mons) sedimentary sequence',
    137.4,
    -5.4
),
(
    'Valles Marineris',
    'Grand canyon system of Mars spanning over 4,000 km across the equator with 7 km deep chasms',
    -70.0,
    -10.0
),
(
    'Olympus Mons',
    'Largest planetary shield volcano in the solar system, standing ~22 km above datum',
    -133.8,
    18.65
),
(
    'Elysium Planitia',
    'Smooth volcanic plain and landing site of NASA InSight geophysical lander',
    155.0,
    4.5
);

-- Seed NASA data sources
INSERT INTO data_sources (
    mission_name,
    instrument_name,
    description,
    source_url
) VALUES
(
    'Mars Global Surveyor',
    'MOLA',
    'Mars Orbiter Laser Altimeter providing global topographic elevation and roughness',
    'https://pds-geosciences.wustl.edu/missions/mgs/mola.html'
),
(
    'Mars Express',
    'HRSC',
    'High Resolution Stereo Camera providing multispectral multi-angle stereo topography',
    'https://www.esa.int/Science_Exploration/Space_Science/Mars_Express'
),
(
    'Viking Orbiter 1 & 2',
    'VIS',
    'Visual Imaging Subsystem providing geodetically controlled global color imagery of Mars',
    'https://astrogeology.usgs.gov/search/map/Mars/Viking/mdim21_color'
),
(
    'Mars Global Surveyor',
    'MOC',
    'Mars Orbiter Camera wide-angle color imaging system providing global context mosaics',
    'https://www.msss.com/mgs/moc/'
),
(
    'Mars Reconnaissance Orbiter',
    'CTX',
    'Context Camera providing wide-area context images of Martian terrain (6 m/px)',
    'https://www.msss.com/mro/ctx/'
),
(
    'Mars Reconnaissance Orbiter',
    'HiRISE',
    'High Resolution Imaging Science Experiment providing sub-meter surface imagery (0.25 m/px)',
    'https://hirise.lpl.arizona.edu/'
),
(
    '2001 Mars Odyssey',
    'THEMIS',
    'Thermal Emission Imaging System mapping multispectral thermal infrared and visible properties',
    'https://themis.asu.edu/'
),
(
    'Mars Global Surveyor',
    'TES',
    'Thermal Emission Spectrometer measuring mineralogy, bolometric albedo, and atmospheric dust',
    'https://tes.asu.edu/'
);

-- Seed verified NASA global map layers (Default: Vibrant Full-Color Topographic Elevation)
INSERT INTO map_layers (
    layer_key,
    name,
    description,
    category,
    service_type,
    service_url,
    external_layer_id,
    coordinate_system,
    resolution_m,
    is_global,
    enabled,
    metadata
) VALUES
(
    'mola_color_hillshade',
    'MGS MOLA Global Color Hillshade',
    'Vibrant full-color global topographic elevation shaded relief map from Mars Orbiter Laser Altimeter',
    'elevation',
    'WMTS',
    'https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/default/default028mm/{z}/{y}/{x}.jpg',
    'Mars_MGS_MOLA_ClrShade_merge_global_463m',
    'EPSG:104905',
    463.0,
    TRUE,
    TRUE,
    '{"attribution": "NASA / GSFC / USGS Astrogeology", "product_type": "derived_hillshade", "format": "image/jpeg", "max_zoom": 7, "datum": "Martian Areoid (GMM-2B)"}'::jsonb
),
(
    'mola_hrsc_blend_200m',
    'MOLA + HRSC Blended Color Hillshade',
    'High-resolution 200m color topography blend combining MOLA vertical datum with Mars Express HRSC stereo details',
    'elevation',
    'WMTS',
    'https://trek.nasa.gov/tiles/Mars/EQ/Mars_MOLA_blend200ppx_HRSC_ClrShade_clon0dd_200mpp_lzw/1.0.0/default/default028mm/{z}/{y}/{x}.jpg',
    'Mars_MOLA_blend200ppx_HRSC_ClrShade_clon0dd_200mpp_lzw',
    'EPSG:104905',
    200.0,
    TRUE,
    TRUE,
    '{"attribution": "NASA / ESA / DLR / FU Berlin", "product_type": "derived_blend", "format": "image/jpeg", "max_zoom": 8, "datum": "Martian Areoid (GMM-2B)"}'::jsonb
),
(
    'viking_mdim21_color',
    'Viking MDIM 2.1 Global Color Mosaic',
    'USGS geodetically controlled global colorized photographic mosaic showing the natural red planet surface',
    'imagery',
    'WMTS',
    'https://trek.nasa.gov/tiles/Mars/EQ/Mars_Viking_MDIM21_ClrMosaic_global_232m/1.0.0/default/default028mm/{z}/{y}/{x}.jpg',
    'Mars_Viking_MDIM21_ClrMosaic_global_232m',
    'EPSG:104905',
    232.0,
    TRUE,
    TRUE,
    '{"attribution": "NASA / USGS Astrogeology Science Center", "product_type": "measured_observation", "format": "image/jpeg", "max_zoom": 7, "datum": "Mars IAU 2000 Sphere"}'::jsonb
),
(
    'themis_day_ir',
    'THEMIS Daytime Infrared Global Mosaic',
    'Calibrated daytime thermal infrared (Band 9, 12.57 µm) brightness temperature mosaic mapping bedrock vs mantle',
    'thermal',
    'WMTS',
    'https://trek.nasa.gov/tiles/Mars/EQ/THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018/1.0.0/default/default028mm/{z}/{y}/{x}.png',
    'THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018',
    'EPSG:104905',
    100.0,
    TRUE,
    TRUE,
    '{"attribution": "NASA / JPL / Arizona State University", "product_type": "measured_thermophysical", "format": "image/png", "max_zoom": 8, "band": "12.57 um"}'::jsonb
),
(
    'tes_albedo',
    'MGS TES Global Surface Albedo',
    'Bolometric optical surface reflectivity (0.3-2.9 µm) mapping atmospheric dust mantling and basaltic bedrock',
    'albedo',
    'WMTS',
    'https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_TES_Albedo_mosaic_global_7410m/1.0.0/default/default028mm/{z}/{y}/{x}.png',
    'Mars_MGS_TES_Albedo_mosaic_global_7410m',
    'EPSG:104905',
    7410.0,
    TRUE,
    TRUE,
    '{"attribution": "NASA / GSFC / Arizona State University", "product_type": "measured_albedo", "format": "image/png", "max_zoom": 5, "band": "0.3-2.9 um"}'::jsonb
);
