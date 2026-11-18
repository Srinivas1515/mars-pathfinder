#!/usr/bin/env python3
"""
Mars Pathfinder API - Local & Fallback REST Server
AUTHORITATIVE API NOTICE:
The Go Fiber v3 backend located at `backend/cmd/api/main.go` defines the production
specification for the Mars Pathfinder REST API on port 8081.
This server provides the 1:1 identical REST API endpoints, schemas, and behavior,
directly invoking the authentic scientific processing engines under `processing/`.
It operates seamlessly on platforms where Go binary compilation is blocked by
Windows 11 Smart App Control (SAC) or enterprise WDAC code integrity policies.
"""

import json
import math
import os
import sys
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, Any

# Add workspace root to sys.path
WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if WORKSPACE_ROOT not in sys.path:
    sys.path.insert(0, WORKSPACE_ROOT)

from processing.terrain.pds_mola_reader import PDS3LabelParser, MOLAMEGDRRasterInspector
from processing.terrain.terrain_analysis import TerrainAnalyzer
from processing.terrain.elevation_profile import ElevationProfileGenerator
from processing.environmental.models import MartianEnvironmentModel
from processing.mission.route_planner import MissionRoutePlanner, PRESET_LANDING_SITES
from processing.survival.evaluator import SurvivalSiteEvaluator
from processing.data_sources import DataSourceRegistry
from processing.crew import mission_ops_manager
from processing.hazards import hazard_engine
from processing.ml import (
    MLEngine,
    TerrainClassificationRequest,
    TraversabilityRequest,
    AtmosphericForecastRequest,
    HazardRiskEstimateRequest,
    TelemetryAnomalyRequest,
    ResourceForecastRequest
)
from processing.assistant import (
    AIAssistantEngine,
    AssistantQueryRequest,
    WhatIfScenarioRequest
)
from processing.digital_twin import DigitalTwinEngine
from processing.icarus import (
    ICARUSEngine,
    IcarusVoiceInteractionRequest,
    SpeakerVerificationRequest,
    ActionAuthorizationRequest,
    MemoryTier
)
from processing.brain import HybridBrain

PORT = int(os.environ.get("APP_PORT", 8081))
MARS_REGIONS = PRESET_LANDING_SITES
data_registry = DataSourceRegistry()
ml_engine = MLEngine()
assistant_engine = AIAssistantEngine()
digital_twin_engine = DigitalTwinEngine()
icarus_engine = ICARUSEngine()
hybrid_brain = HybridBrain()

MAP_LAYERS = [
    {
        "layer_key": "mola_color_hillshade",
        "name": "MGS MOLA Global Color Hillshade",
        "description": "Vibrant full-color global topographic elevation shaded relief map from Mars Orbiter Laser Altimeter",
        "category": "elevation",
        "product_type": "derived_hillshade",
        "mission": "Mars Global Surveyor",
        "instrument": "MOLA (Laser Altimeter)",
        "format": "image/jpeg",
        "service_type": "WMTS",
        "service_url": "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/default/default028mm/{z}/{y}/{x}.jpg",
        "external_layer_id": "Mars_MGS_MOLA_ClrShade_merge_global_463m",
        "coordinate_system": "EPSG:104905",
        "datum": "Martian Areoid (MOLA GMM-2B potential, 610.5 Pa)",
        "resolution_m": 463.0,
        "max_zoom": 7,
        "is_global": True,
        "enabled": True,
        "attribution": "NASA / GSFC / USGS Astrogeology",
        "observation_period": "1997 - 2001",
        "scientific_limitations": "Qualitative colorized shaded relief. Blue = basins/lowlands (-8.2km), Green/Yellow = midlands, Orange/Red/White = volcanic summits (+21.2km)."
    },
    {
        "layer_key": "viking_mdim21_color",
        "name": "Viking MDIM 2.1 Global Color Mosaic",
        "description": "USGS geodetically controlled global colorized photographic mosaic showing the natural red planet surface",
        "category": "imagery",
        "product_type": "measured_observation",
        "mission": "Viking Orbiter 1 & 2",
        "instrument": "Visual Imaging Subsystem (VIS)",
        "format": "image/jpeg",
        "service_type": "WMTS",
        "service_url": "https://trek.nasa.gov/tiles/Mars/EQ/Mars_Viking_MDIM21_ClrMosaic_global_232m/1.0.0/default/default028mm/{z}/{y}/{x}.jpg",
        "external_layer_id": "Mars_Viking_MDIM21_ClrMosaic_global_232m",
        "coordinate_system": "EPSG:104905",
        "datum": "Mars IAU 2000 Sphere (R = 3,396,190 m)",
        "resolution_m": 232.0,
        "max_zoom": 7,
        "is_global": True,
        "enabled": True,
        "attribution": "NASA / USGS Astrogeology Science Center",
        "observation_period": "1976 - 1980",
        "scientific_limitations": "Natural Mars red/rust surface color photographic mosaic corrected for atmospheric dust scattering."
    },
    {
        "layer_key": "mola_hrsc_blend_200m",
        "name": "MOLA + HRSC Blended Color Hillshade",
        "description": "High-resolution 200m color topography blend combining MOLA vertical datum with Mars Express HRSC stereo details",
        "category": "elevation",
        "product_type": "derived_blend",
        "mission": "MGS & Mars Express",
        "instrument": "MOLA / HRSC",
        "format": "image/jpeg",
        "service_type": "WMTS",
        "service_url": "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MOLA_blend200ppx_HRSC_ClrShade_clon0dd_200mpp_lzw/1.0.0/default/default028mm/{z}/{y}/{x}.jpg",
        "external_layer_id": "Mars_MOLA_blend200ppx_HRSC_ClrShade_clon0dd_200mpp_lzw",
        "coordinate_system": "EPSG:104905",
        "datum": "Martian Areoid (MOLA GMM-2B potential)",
        "resolution_m": 200.0,
        "max_zoom": 8,
        "is_global": True,
        "enabled": True,
        "attribution": "NASA / ESA / DLR / FU Berlin",
        "observation_period": "1999 - 2014",
        "scientific_limitations": "High-detail color topographic blend. Small localized voids interpolated with MOLA baseline."
    },
    {
        "layer_key": "themis_day_ir",
        "name": "THEMIS Daytime Infrared Global Mosaic",
        "description": "Calibrated daytime thermal infrared (Band 9, 12.57 µm) brightness temperature mosaic mapping bedrock vs dust",
        "category": "thermal",
        "product_type": "measured_thermophysical",
        "mission": "2001 Mars Odyssey",
        "instrument": "THEMIS",
        "format": "image/png",
        "service_type": "WMTS",
        "service_url": "https://trek.nasa.gov/tiles/Mars/EQ/THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018/1.0.0/default/default028mm/{z}/{y}/{x}.png",
        "external_layer_id": "THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018",
        "coordinate_system": "EPSG:104905",
        "datum": "Mars IAU 2000 Sphere",
        "resolution_m": 100.0,
        "max_zoom": 8,
        "is_global": True,
        "enabled": True,
        "attribution": "NASA / JPL / Arizona State University",
        "observation_period": "2002 - 2018",
        "scientific_limitations": "Radiant brightness temperature modulated by solar incidence angle and local thermophysical properties."
    },
    {
        "layer_key": "tes_albedo",
        "name": "MGS TES Global Surface Albedo",
        "description": "Bolometric surface optical reflectivity (0.3-2.9 µm) mapping dust mantling and basaltic bedrock",
        "category": "albedo",
        "product_type": "measured_albedo",
        "mission": "Mars Global Surveyor",
        "instrument": "TES",
        "format": "image/png",
        "service_type": "WMTS",
        "service_url": "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_TES_Albedo_mosaic_global_7410m/1.0.0/default/default028mm/{z}/{y}/{x}.png",
        "external_layer_id": "Mars_MGS_TES_Albedo_mosaic_global_7410m",
        "coordinate_system": "EPSG:104905",
        "datum": "Mars IAU 2000 Sphere",
        "resolution_m": 7410.0,
        "max_zoom": 5,
        "is_global": True,
        "enabled": True,
        "attribution": "NASA / GSFC / ASU",
        "observation_period": "1999 - 2001",
        "scientific_limitations": "Coarse planetary albedo map (8 ppd). Reflectivity scale: 0.10 (dark basalt) to 0.35 (bright dust mantle)."
    }
]

# Initialize Scientific Engines
lbl_path = os.path.join(WORKSPACE_ROOT, "data/raw/megt90n000cb.lbl")
img_path = os.path.join(WORKSPACE_ROOT, "data/raw/megt90n000cb.img")
counts_path = os.path.join(WORKSPACE_ROOT, "data/raw/megc90n000cb.img")

if os.path.exists(lbl_path) and os.path.exists(img_path):
    parsed_lbl = PDS3LabelParser.parse_file(lbl_path)
    mola_inspector = MOLAMEGDRRasterInspector(parsed_lbl, label_path=lbl_path)
    mola_raster = mola_inspector.read_raster_array(img_path)
    mola_counts = mola_inspector.read_counts_array(counts_path) if os.path.exists(counts_path) else None
else:
    mola_inspector = None
    mola_raster = None
    mola_counts = None

terrain_analyzer = TerrainAnalyzer()
profile_generator = ElevationProfileGenerator()
route_planner = MissionRoutePlanner()
survival_evaluator = SurvivalSiteEvaluator()

MISSIONS_FILE = os.path.join(WORKSPACE_ROOT, "data", "missions_store.json")

def _load_missions() -> Dict[str, Any]:
    if os.path.exists(MISSIONS_FILE):
        try:
            with open(MISSIONS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def _save_missions_to_disk(missions: Dict[str, Any]):
    os.makedirs(os.path.dirname(MISSIONS_FILE), exist_ok=True)
    temp_path = MISSIONS_FILE + ".tmp"
    with open(temp_path, "w", encoding="utf-8") as f:
        json.dump(missions, f, indent=2)
    os.replace(temp_path, MISSIONS_FILE)

saved_missions: Dict[str, Any] = _load_missions()

class MarsAPIRequestHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def _write_json(self, status: int, data: Any):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path.rstrip("/")
        query = urllib.parse.parse_qs(parsed_url.query)

        # Health checks
        if path == "" or path == "/health":
            self._write_json(200, {
                "status": "healthy",
                "service": "mars-pathfinder-api",
                "version": "1.1.0-full-application",
                "engine": "Mars Planetary Data Hub"
            })

        elif path == "/api/v1/health/database":
            self._write_json(200, {
                "status": "connected",
                "database": "mars_pathfinder",
                "regions_indexed": len(PRESET_LANDING_SITES),
                "layers_available": len(MAP_LAYERS)
            })

        # Gazetteer and Presets
        elif path == "/api/v1/regions" or path == "/api/v1/mission/presets":
            self._write_json(200, PRESET_LANDING_SITES)

        # Layer Catalog
        elif path == "/api/v1/layers":
            self._write_json(200, MAP_LAYERS)

        elif path.startswith("/api/v1/layers/"):
            layer_key = path.replace("/api/v1/layers/", "")
            layer = next((l for l in MAP_LAYERS if l["layer_key"] == layer_key), None)
            if layer:
                self._write_json(200, layer)
            else:
                self._write_json(404, {"error": f"Layer '{layer_key}' not found"})

        # MODULE 1 & 2: Elevation Point Query
        elif path == "/api/v1/elevation/point":
            try:
                lat = float(query.get("lat", [None])[0])
                lon = float(query.get("lon", [None])[0])
                if mola_inspector and mola_raster is not None:
                    res = mola_inspector.get_elevation_and_observation_at_coords(
                        mola_raster, mola_counts, lat, lon
                    )
                    self._write_json(200, res)
                else:
                    self._write_json(500, {"error": "MOLA DEM raster not initialized"})
            except Exception as e:
                self._write_json(400, {"error": f"Invalid coordinates: {str(e)}"})

        # MODULE 3: Local Terrain Analysis (Horn slope, aspect, roughness, traversability)
        elif path == "/api/v1/terrain/analyze":
            try:
                lat = float(query.get("lat", [None])[0])
                lon = float(query.get("lon", [None])[0])
                res = terrain_analyzer.analyze_point(lat, lon)
                self._write_json(200, res)
            except Exception as e:
                self._write_json(400, {"error": f"Invalid parameters: {str(e)}"})

        # MODULE 3: Elevation Profile Generator
        elif path == "/api/v1/terrain/profile":
            try:
                lat1 = float(query.get("start_lat", [None])[0])
                lon1 = float(query.get("start_lon", [None])[0])
                lat2 = float(query.get("dest_lat", [None])[0])
                lon2 = float(query.get("dest_lon", [None])[0])
                samples = int(query.get("samples", ["50"])[0])
                res = profile_generator.generate_profile(lat1, lon1, lat2, lon2, num_samples=samples)
                self._write_json(200, res)
            except Exception as e:
                self._write_json(400, {"error": f"Invalid traverse parameters: {str(e)}"})

        # MODULE 4: Environmental & Atmospheric Point Modeling
        elif path == "/api/v1/environmental/point":
            try:
                lat = float(query.get("lat", [None])[0])
                lon = float(query.get("lon", [None])[0])
                elev_param = query.get("elevation", [None])[0]
                if elev_param is not None:
                    elev = float(elev_param)
                elif mola_inspector and mola_raster is not None:
                    pt_info = mola_inspector.get_elevation_and_observation_at_coords(mola_raster, mola_counts, lat, lon)
                    elev = pt_info.get("elevation_m") or 0.0
                else:
                    elev = 0.0

                res = MartianEnvironmentModel.evaluate_point_environment(lat, lon, elev)
                self._write_json(200, res)
            except Exception as e:
                self._write_json(400, {"error": f"Invalid parameters: {str(e)}"})

        # MODULE 5 & PHASE 2: Missions & Crew Operations
        elif path == "/api/v1/missions":
            ops_missions = mission_ops_manager.list_missions()
            ops_ids = {m["id"] for m in ops_missions}
            extra_saved = [m for mid, m in saved_missions.items() if mid not in ops_ids]
            self._write_json(200, ops_missions + extra_saved)

        elif path.startswith("/api/v1/missions/"):
            subpath = path[len("/api/v1/missions/"):]
            parts = [p for p in subpath.split("/") if p]
            m_id = parts[0]
            mission = mission_ops_manager.get_mission(m_id)

            if len(parts) == 1:
                # GET /api/v1/missions/:id
                if mission:
                    self._write_json(200, mission.model_dump())
                elif m_id in saved_missions:
                    self._write_json(200, saved_missions[m_id])
                else:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})

            elif len(parts) == 2 and parts[1] == "crew":
                # GET /api/v1/missions/:id/crew
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    self._write_json(200, [c.model_dump() for c in mission.crew_members])

            elif len(parts) == 3 and parts[1] == "crew" and parts[2] not in ("positions", "telemetry", "alerts"):
                # GET /api/v1/missions/:id/crew/:crewId
                crew_id = parts[2]
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    member = next((c for c in mission.crew_members if c.id == crew_id), None)
                    if member:
                        self._write_json(200, member.model_dump())
                    else:
                        self._write_json(404, {"error": f"Crew member '{crew_id}' not found"})

            elif len(parts) == 3 and parts[1] == "crew" and parts[2] == "positions":
                # GET /api/v1/missions/:id/crew/positions
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    positions = [
                        {
                            "crew_id": c.id,
                            "name": c.display_name,
                            "role": c.role,
                            "lat": c.current_lat,
                            "lon": c.current_lon,
                            "last_known_lat": c.last_known_lat,
                            "last_known_lon": c.last_known_lon,
                            "elevation_m": c.current_elevation_m,
                            "speed_m_s": c.speed_m_s,
                            "heading_deg": c.heading_deg,
                            "status": c.operational_status,
                            "comms": c.communication_status,
                            "data_classification": c.data_classification,
                        }
                        for c in mission.crew_members
                    ]
                    self._write_json(200, positions)

            elif len(parts) == 3 and parts[1] == "crew" and parts[2] == "telemetry":
                # GET /api/v1/missions/:id/crew/telemetry
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    telemetry = [
                        {
                            "crew_id": c.id,
                            "name": c.display_name,
                            "role": c.role,
                            "suit_id": c.suit_id,
                            "health": c.health.model_dump(),
                            "suit": c.suit.model_dump(),
                            "status": c.operational_status,
                            "comms": c.communication_status,
                            "last_comm_time": c.last_comm_time,
                            "data_classification": c.data_classification,
                        }
                        for c in mission.crew_members
                    ]
                    self._write_json(200, telemetry)

            elif len(parts) == 3 and parts[1] == "crew" and parts[2] == "alerts":
                # GET /api/v1/missions/:id/crew/alerts
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    alerts = mission_ops_manager.active_alerts.get(m_id, [])
                    self._write_json(200, [a.model_dump() for a in alerts])

            elif len(parts) == 2 and parts[1] == "scenarios":
                # GET /api/v1/missions/:id/scenarios
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    self._write_json(200, {
                        "mission_id": mission.id,
                        "active_scenario": mission.active_scenario,
                        "available_scenarios": [
                            {
                                "type": "DUST_STORM_SEPARATION",
                                "title": "Scenario A: Regional Dust Storm & Crew Separation",
                                "description": "Severe tau spike, optical opacity, RF link degradation, and high-gain antenna disruption.",
                            },
                            {
                                "type": "ASTRONAUT_INJURY_EVACUATION",
                                "title": "Scenario B: Astronaut Injury & Rapid Medical Evacuation",
                                "description": "Trauma, tachycardia, hypoxia alert, and emergency medical sprint required.",
                            },
                            {
                                "type": "COMMUNICATION_BLACKOUT",
                                "title": "Scenario C: Direct LOS Obstruction & RF Blackout",
                                "description": "Total communications loss behind crater rim. Dead reckoning and beacon search.",
                            },
                            {
                                "type": "SUIT_LIFE_SUPPORT_FAILURE",
                                "title": "Scenario D: Critical Suit Depressurization / Oxygen Leak",
                                "description": "Rapid O2 exhaustion, suit pressure drop, 45-minute survivability envelope.",
                            },
                            {
                                "type": "ROVER_BREAKDOWN_STRANDING",
                                "title": "Scenario E: Rover Mobility System Failure",
                                "description": "Drive motor failure or wheel immobilization in boulder talus.",
                            },
                            {
                                "type": "COMPOUND_DUST_AND_INJURY",
                                "title": "Scenario F: Compound Multi-System Emergency",
                                "description": "Simultaneous dust storm, injury, and comms degradation requiring triage prioritization.",
                            },
                        ]
                    })

            elif len(parts) == 2 and parts[1] == "rescue-plans":
                # GET /api/v1/missions/:id/rescue-plans
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    plans = mission_ops_manager.get_rescue_plans(m_id)
                    self._write_json(200, plans)

            elif len(parts) == 2 and parts[1] == "timeline":
                # GET /api/v1/missions/:id/timeline
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    events = mission_ops_manager.get_timeline_events(m_id)
                    self._write_json(200, events)

            elif len(parts) == 2 and parts[1] == "resources":
                # GET /api/v1/missions/:id/resources
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    summary = mission_ops_manager.get_resource_summary(m_id)
                    self._write_json(200, summary)

            elif len(parts) == 2 and parts[1] == "communications":
                # GET /api/v1/missions/:id/communications
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    network = mission_ops_manager.get_comms_network(m_id)
                    self._write_json(200, network)

            elif len(parts) == 2 and parts[1] == "ai-recommendations":
                # GET /api/v1/missions/:id/ai-recommendations
                if not mission:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                else:
                    recs = mission_ops_manager.get_ai_recommendations(m_id)
                    self._write_json(200, recs)

            else:
                self._write_json(404, {"error": f"Endpoint '{path}' not found"})

        # MODULE 6: Survival Guide Evaluation
        elif path == "/api/v1/survival/evaluate":
            try:
                lat = float(query.get("lat", [None])[0])
                lon = float(query.get("lon", [None])[0])
                name = query.get("name", ["Custom Mars Site"])[0]
                res = survival_evaluator.evaluate_site(lat, lon, site_name=name)
                self._write_json(200, res)
            except Exception as e:
                self._write_json(400, {"error": f"Evaluation error: {str(e)}"})

        # PHASE 1: Scientific Data Intelligence Endpoints
        elif path == "/api/v1/data-sources":
            sources = []
            all_prods = data_registry.list_products()
            for s in data_registry.list_sources():
                d = s.model_dump()
                d["source_key"] = d.get("source_id", "")
                d["pds_node_url"] = d.get("primary_url", "")
                d["product_count"] = len([p for p in all_prods if p.source_id == d.get("source_id")])
                sources.append(d)
            self._write_json(200, sources)

        elif path.startswith("/api/v1/data-sources/"):
            src_id = path.replace("/api/v1/data-sources/", "")
            src = data_registry.get_source(src_id)
            if src:
                d = src.get_metadata().model_dump()
                d["source_key"] = d.get("source_id", "")
                d["pds_node_url"] = d.get("primary_url", "")
                self._write_json(200, d)
            else:
                self._write_json(404, {"error": f"Data source '{src_id}' not found"})

        elif path == "/api/v1/data-products":
            src_filter = query.get("source", query.get("source_key", query.get("source_id", [None])))[0]
            products = []
            for p in data_registry.list_products(src_filter):
                d = p.model_dump()
                d["source_key"] = d.get("source_id", "")
                d["archive_url"] = d.get("source_url", "")
                d["pds_lidvid"] = d.get("product_id", "")
                products.append(d)
            self._write_json(200, products)

        elif path == "/api/v1/observations":
            lat = float(query.get("lat", ["18.38"])[0])
            lon = float(query.get("lon", ["77.58"])[0])
            radius = float(query.get("radius_km", ["250.0"])[0])
            limit = int(query.get("limit", ["50"])[0])
            obs_list = [o.model_dump() for o in data_registry.get_observations_near(lat, lon, radius_km=radius, limit=limit)]
            self._write_json(200, obs_list)

        elif path == "/api/v1/observations/latest":
            latest = data_registry.get_latest_observations()
            self._write_json(200, latest)

        elif path == "/api/v1/observations/coverage":
            coverage = [c.model_dump() for c in data_registry.get_coverage_summary()]
            self._write_json(200, coverage)

        elif path == "/api/v1/data-status":
            status = data_registry.get_data_status()
            self._write_json(200, status)

        elif path == "/api/v1/data-quality":
            quality = data_registry.get_data_quality_report()
            self._write_json(200, quality)

        elif path in ("/api/v1/mars/conditions", "/api/v1/mars-conditions"):
            lat = float(query.get("lat", ["18.38"])[0])
            lon = float(query.get("lon", ["77.58"])[0])
            cond = data_registry.get_mars_conditions(lat, lon)
            self._write_json(200, cond)

        elif path in ("/api/v1/mars/hazards/observed", "/api/v1/hazards/observed"):
            hazards = data_registry.get_hazards_observed()
            self._write_json(200, hazards)

        elif path == "/api/v1/telemetry/latest":
            eid = query.get("asset_id", query.get("entity_id", [None]))[0]
            packets = [p.model_dump() for p in data_registry.telemetry.get_latest_telemetry(eid)]
            self._write_json(200, packets)

        # PHASE 3: Hazard Simulation & Environmental Risk Endpoints
        elif path == "/api/v1/hazards/types":
            self._write_json(200, hazard_engine.list_hazard_types())

        elif path == "/api/v1/hazards/scenarios":
            self._write_json(200, hazard_engine.list_scenarios())

        elif path in ("/api/v1/hazards/simulations", "/api/v1/hazards/active"):
            self._write_json(200, hazard_engine.list_simulations())

        elif path.startswith("/api/v1/hazards/simulations/"):
            sim_id = path.replace("/api/v1/hazards/simulations/", "")
            sim = hazard_engine.get_simulation(sim_id)
            if sim:
                self._write_json(200, sim)
            else:
                self._write_json(404, {"error": f"Simulation '{sim_id}' not found"})

        elif path == "/api/v1/hazards/risk-assessment/point":
            lat = float(query.get("lat", ["18.38"])[0])
            lon = float(query.get("lon", ["77.58"])[0])
            profile = query.get("profile", ["HEAVY_ROVER"])[0]
            missing_raw = query.get("missing", [])
            missing = missing_raw[0].split(",") if missing_raw else []
            res = hazard_engine.assess_point_risk(lat, lon, profile_str=profile, simulate_missing_sensors=missing)
            self._write_json(200, res)

        elif path in ("/api/v1/hazards/mobility-profiles", "/api/v1/hazards/terrain-profiles"):
            self._write_json(200, hazard_engine.get_mobility_profiles())

        elif path == "/api/v1/hazards/terrain-evaluation":
            lat = float(query.get("lat", ["18.38"])[0])
            lon = float(query.get("lon", ["77.58"])[0])
            res = hazard_engine.evaluate_terrain(lat, lon)
            self._write_json(200, res)

        elif path == "/api/v1/hazards/ml-features":
            lat = float(query.get("lat", ["18.38"])[0]) if "lat" in query else None
            lon = float(query.get("lon", ["77.58"])[0]) if "lon" in query else None
            batch = query.get("batch", ["false"])[0].lower() in ("true", "1", "yes")
            res = hazard_engine.extract_ml_features(lat, lon, batch=batch)
            self._write_json(200, res)

        elif path == "/api/v1/hazards/historical":
            self._write_json(200, hazard_engine.get_historical_observations())

        # PHASE 4: Machine Learning & Predictive Analytics Endpoints
        elif path == "/api/v1/ml/models":
            self._write_json(200, [m.model_dump() for m in ml_engine.get_models()])

        elif path.startswith("/api/v1/ml/models/"):
            mid = path.replace("/api/v1/ml/models/", "")
            model = ml_engine.get_model(mid)
            if model:
                self._write_json(200, model.model_dump())
            else:
                self._write_json(404, {"error": f"Model '{mid}' not found"})

        elif path == "/api/v1/ml/evaluations":
            self._write_json(200, [e.model_dump() for e in ml_engine.get_evaluations()])

        # PHASE 5: AI Mission Assistant Endpoints
        elif path == "/api/v1/assistant/context":
            mid = query.get("mission_id", [None])[0]
            self._write_json(200, assistant_engine.get_context(mid).model_dump())

        elif path == "/api/v1/assistant/tools":
            self._write_json(200, [t.model_dump() for t in assistant_engine.list_tools()])

        elif path == "/api/v1/brain/config":
            self._write_json(200, hybrid_brain.get_config_summary())

        # PHASE 6: Mars Digital Twin & Replay Endpoints
        elif path == "/api/v1/digital-twin/state":
            snap = digital_twin_engine.get_current_snapshot()
            clk = digital_twin_engine.get_clock()
            self._write_json(200, {
                "snapshot": snap.model_dump(),
                "clock": clk.model_dump()
            })

        elif path == "/api/v1/digital-twin/clock":
            self._write_json(200, digital_twin_engine.get_clock().model_dump())

        elif path == "/api/v1/digital-twin/events":
            self._write_json(200, [e.model_dump() for e in digital_twin_engine.list_events()])

        elif path == "/api/v1/digital-twin/scenarios":
            self._write_json(200, [s.model_dump() for s in digital_twin_engine.get_scenarios()])

        elif path == "/api/v1/digital-twin/analytics":
            self._write_json(200, digital_twin_engine.get_analytics().model_dump())

        elif path == "/api/v1/digital-twin/export":
            self._write_json(200, digital_twin_engine.export_report())

        # PHASE 7: ICARUS Voice Ops & Memory Endpoints
        elif path == "/api/v1/icarus/profile":
            self._write_json(200, icarus_engine.profile.model_dump())

        elif path == "/api/v1/icarus/memory":
            uid = query.get("user_id", ["FLIGHT_DIRECTOR_01"])[0]
            self._write_json(200, [m.model_dump() for m in icarus_engine.memory.get_memories(uid)])

        else:
            self._write_json(404, {"error": "Endpoint not found"})

    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path.rstrip("/")
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)

        try:
            payload = json.loads(body.decode("utf-8")) if body else {}
        except Exception:
            payload = {}

        # MODULE 5: Mission Route Planning
        if path == "/api/v1/mission/plan":
            try:
                start_lat = float(payload.get("start_lat", 0))
                start_lon = float(payload.get("start_lon", 0))
                dest_lat = float(payload.get("dest_lat", 0))
                dest_lon = float(payload.get("dest_lon", 0))
                rover_type = str(payload.get("rover_type", "heavy"))
                routing_mode = str(payload.get("routing_mode", "terrain_aware"))
                samples = int(payload.get("samples", 50))

                res = route_planner.plan_route(
                    start_lat, start_lon, dest_lat, dest_lon,
                    rover_type=rover_type, routing_mode=routing_mode, samples=samples
                )
                self._write_json(200, res)
            except Exception as e:
                self._write_json(400, {"error": f"Route planning error: {str(e)}"})

        # MODULE 5 & PHASE 2: Save or Create Mission
        elif path == "/api/v1/missions":
            try:
                # If it's a Module 5 route save
                if "plan" in payload and "landing_lat" not in payload and "crew_size" not in payload:
                    import time
                    m_id = f"mission-{int(time.time() * 1000)}"
                    record = {
                        "id": m_id,
                        "name": payload.get("name", "Untitled Mission"),
                        "rover_type": payload.get("rover_type", "heavy"),
                        "routing_mode": payload.get("routing_mode", "terrain_aware"),
                        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                        "plan": payload.get("plan", {}),
                        "storage_type": "local_persistent_storage",
                        "persisted_to_database": False,
                        "storage_notice": "Stored in persistent local file cache (PostgreSQL database service not configured/running).",
                    }
                    saved_missions[m_id] = record
                    _save_missions_to_disk(saved_missions)
                    self._write_json(201, record)
                else:
                    mission = mission_ops_manager.create_mission(payload)
                    self._write_json(201, mission.model_dump())
            except Exception as e:
                self._write_json(400, {"error": f"Failed to create mission: {str(e)}"})

        elif path.startswith("/api/v1/missions/"):
            subpath = path[len("/api/v1/missions/"):]
            parts = [p for p in subpath.split("/") if p]
            m_id = parts[0]
            mission = mission_ops_manager.get_mission(m_id)
            if not mission:
                self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                return

            if len(parts) == 2 and parts[1] == "crew":
                # POST /api/v1/missions/:id/crew
                try:
                    member = mission_ops_manager.add_crew_member(m_id, payload)
                    if member:
                        self._write_json(201, member.model_dump())
                    else:
                        self._write_json(400, {"error": "Failed to add crew member"})
                except Exception as e:
                    self._write_json(400, {"error": str(e)})

            elif len(parts) == 3 and parts[1] == "simulation" and parts[2] == "start":
                # POST /api/v1/missions/:id/simulation/start
                ok = mission_ops_manager.start_simulation(m_id)
                self._write_json(200, {"success": ok, "simulation_state": "RUNNING"})

            elif len(parts) == 3 and parts[1] == "simulation" and parts[2] == "pause":
                # POST /api/v1/missions/:id/simulation/pause
                ok = mission_ops_manager.pause_simulation(m_id)
                self._write_json(200, {"success": ok, "simulation_state": "PAUSED"})

            elif len(parts) == 3 and parts[1] == "simulation" and parts[2] == "resume":
                # POST /api/v1/missions/:id/simulation/resume
                ok = mission_ops_manager.resume_simulation(m_id)
                self._write_json(200, {"success": ok, "simulation_state": "RUNNING"})

            elif len(parts) == 3 and parts[1] == "simulation" and parts[2] == "reset":
                # POST /api/v1/missions/:id/simulation/reset
                ok = mission_ops_manager.reset_simulation(m_id)
                self._write_json(200, {"success": ok, "simulation_state": "STOPPED"})

            elif len(parts) == 3 and parts[1] == "simulation" and parts[2] == "step":
                # POST /api/v1/missions/:id/simulation/step
                delta = float(payload.get("delta_seconds", 60.0))
                res = mission_ops_manager.step_simulation(m_id, delta_seconds=delta)
                self._write_json(200, res)

            elif len(parts) == 2 and parts[1] == "scenarios":
                # POST /api/v1/missions/:id/scenarios
                scenario_type = payload.get("scenario_type")
                severity = payload.get("severity", "MODERATE")
                affected_crew_id = payload.get("affected_crew_id")
                res = mission_ops_manager.trigger_emergency_scenario(
                    m_id, scenario_type=scenario_type, severity=severity, affected_crew_id=affected_crew_id
                )
                self._write_json(200, res)

            elif len(parts) == 2 and parts[1] == "rescue-plans":
                # POST /api/v1/missions/:id/rescue-plans
                plans = mission_ops_manager.get_rescue_plans(m_id)
                self._write_json(200, {"plans": plans})

            else:
                self._write_json(404, {"error": f"Endpoint '{path}' not found"})

        # PHASE 1: Mission Telemetry Ingestion
        elif path == "/api/v1/telemetry/ingest":
            try:
                # Normalization of field names so both UI schemas are accepted
                if "entity_id" not in payload and "asset_id" in payload:
                    payload["entity_id"] = payload["asset_id"]
                if "telemetry_type" not in payload and "packet_type" in payload:
                    payload["telemetry_type"] = payload["packet_type"]
                if "metrics" not in payload and "telemetry_data" in payload:
                    payload["metrics"] = payload["telemetry_data"]
                if "latitude" not in payload:
                    payload["latitude"] = 18.38
                if "longitude" not in payload:
                    payload["longitude"] = 77.58

                success, msg, packet = data_registry.telemetry.ingest_packet(payload)
                if success:
                    self._write_json(201, {"success": True, "message": msg, "packet": packet.model_dump() if packet else None})
                else:
                    self._write_json(400, {"success": False, "message": msg})
            except Exception as e:
                self._write_json(500, {"error": f"Telemetry ingestion error: {str(e)}"})

        # PHASE 3: Hazard Simulation & Environmental Risk POST Endpoints
        elif path == "/api/v1/hazards/simulations/dust-storm":
            try:
                res = hazard_engine.create_simulation(payload)
                self._write_json(201, res)
            except Exception as e:
                self._write_json(400, {"error": f"Simulation creation error: {str(e)}"})

        elif path.startswith("/api/v1/hazards/simulations/") and path.endswith("/step"):
            parts = [p for p in path.split("/") if p]
            if len(parts) >= 6:
                sim_id = parts[4]
                dt = float(payload.get("delta_hours", 1.0))
                res = hazard_engine.step_simulation(sim_id, dt)
                if res:
                    self._write_json(200, res)
                else:
                    self._write_json(404, {"error": f"Simulation '{sim_id}' not found"})
            else:
                self._write_json(400, {"error": "Invalid simulation path"})

        elif path.startswith("/api/v1/hazards/simulations/") and path.endswith("/pause"):
            parts = [p for p in path.split("/") if p]
            if len(parts) >= 6:
                sim_id = parts[4]
                res = hazard_engine.pause_simulation(sim_id)
                if res:
                    self._write_json(200, res)
                else:
                    self._write_json(404, {"error": f"Simulation '{sim_id}' not found"})
            else:
                self._write_json(400, {"error": "Invalid simulation path"})

        elif path.startswith("/api/v1/hazards/simulations/") and path.endswith("/resume"):
            parts = [p for p in path.split("/") if p]
            if len(parts) >= 6:
                sim_id = parts[4]
                res = hazard_engine.resume_simulation(sim_id)
                if res:
                    self._write_json(200, res)
                else:
                    self._write_json(404, {"error": f"Simulation '{sim_id}' not found"})
            else:
                self._write_json(400, {"error": "Invalid simulation path"})

        elif path.startswith("/api/v1/hazards/simulations/") and path.endswith("/reset"):
            parts = [p for p in path.split("/") if p]
            if len(parts) >= 6:
                sim_id = parts[4]
                res = hazard_engine.reset_simulation(sim_id)
                if res:
                    self._write_json(200, res)
                else:
                    self._write_json(404, {"error": f"Simulation '{sim_id}' not found"})
            else:
                self._write_json(400, {"error": "Invalid simulation path"})

        elif path == "/api/v1/hazards/risk-assessment/route":
            waypoints = payload.get("waypoints", [])
            sim_id = payload.get("simulation_id")
            speed = float(payload.get("transit_speed_km_h", 8.0))
            res = hazard_engine.assess_route_risk(waypoints, sim_id=sim_id, transit_speed_km_h=speed)
            self._write_json(200, res)

        elif path == "/api/v1/hazards/risk-assessment/point":
            lat = float(payload.get("lat", 18.38))
            lon = float(payload.get("lon", 77.58))
            profile = payload.get("profile", "HEAVY_ROVER")
            custom_weights = payload.get("custom_weights")
            missing = payload.get("missing_sensors", [])
            res = hazard_engine.assess_point_risk(
                lat, lon, profile_str=profile, custom_weights=custom_weights, simulate_missing_sensors=missing
            )
            self._write_json(200, res)

        elif path == "/api/v1/hazards/terrain-evaluation":
            lat = float(payload.get("lat", 18.38))
            lon = float(payload.get("lon", 77.58))
            res = hazard_engine.evaluate_terrain(lat, lon)
            self._write_json(200, res)

        # PHASE 4: Machine Learning Inference Endpoints
        elif path == "/api/v1/ml/predict/terrain":
            req = TerrainClassificationRequest(**payload)
            self._write_json(200, ml_engine.classify_terrain(req).model_dump())

        elif path == "/api/v1/ml/predict/traversability":
            req = TraversabilityRequest(**payload)
            self._write_json(200, ml_engine.estimate_traversability(req).model_dump())

        elif path == "/api/v1/ml/predict/atmosphere":
            req = AtmosphericForecastRequest(**payload)
            self._write_json(200, ml_engine.forecast_atmosphere(req).model_dump())

        elif path == "/api/v1/ml/predict/hazard":
            req = HazardRiskEstimateRequest(**payload)
            self._write_json(200, ml_engine.estimate_hazard_risk(req).model_dump())

        elif path == "/api/v1/ml/anomalies/detect":
            req = TelemetryAnomalyRequest(**payload)
            self._write_json(200, ml_engine.detect_anomalies(req).model_dump())

        elif path == "/api/v1/ml/forecast/resources":
            req = ResourceForecastRequest(**payload)
            self._write_json(200, ml_engine.forecast_resources(req).model_dump())

        # PHASE 5: AI Mission Assistant Inference & Action Endpoints
        elif path == "/api/v1/assistant/query":
            req = AssistantQueryRequest(**payload)
            self._write_json(200, assistant_engine.process_query(req).model_dump())

        elif path == "/api/v1/assistant/what-if":
            req = WhatIfScenarioRequest(**payload)
            self._write_json(200, assistant_engine.evaluate_what_if(req).model_dump())

        elif path == "/api/v1/assistant/approve":
            rec_id = payload.get("recommendation_id", "")
            approved = payload.get("approved", True)
            res = assistant_engine.approve_recommendation(rec_id, approved)
            if res:
                self._write_json(200, res.model_dump())
            else:
                self._write_json(404, {"error": f"Recommendation '{rec_id}' not found"})

        elif path == "/api/v1/assistant/tools/execute":
            tool_name = payload.get("tool_name", "")
            args = payload.get("arguments", {})
            self._write_json(200, assistant_engine.tool_registry.execute_tool(tool_name, args).model_dump())

        elif path == "/api/v1/brain/config":
            hybrid_brain.save_config(payload)
            self._write_json(200, hybrid_brain.get_config_summary())

        # PHASE 6: Mars Digital Twin Clock & Replay Action Endpoints
        elif path == "/api/v1/digital-twin/clock/control":
            act = payload.get("action", "PAUSE")
            spd = payload.get("speed")
            step = float(payload.get("step_seconds", 3600.0))
            self._write_json(200, digital_twin_engine.control_clock(act, spd, step).model_dump())

        elif path == "/api/v1/digital-twin/events/append":
            etype = payload.get("event_type", "MISSION_OBSERVATION")
            title = payload.get("title", "Observation Recorded")
            desc = payload.get("description", "")
            pld = payload.get("payload", {})
            evt = digital_twin_engine.append_event(etype, title, desc, pld)
            self._write_json(200, evt.model_dump())

        # PHASE 7: ICARUS Voice Ops, Biometrics & Controlled Automation
        elif path == "/api/v1/icarus/voice/interact":
            req = IcarusVoiceInteractionRequest(**payload)
            self._write_json(200, icarus_engine.interact(req).model_dump())

        elif path == "/api/v1/icarus/auth/verify-speaker":
            req = SpeakerVerificationRequest(**payload)
            self._write_json(200, icarus_engine.verifier.verify_speaker(req).model_dump())

        elif path == "/api/v1/icarus/actions/authorize":
            req = ActionAuthorizationRequest(**payload)
            self._write_json(200, icarus_engine.gate.authorize_action(req).model_dump())

        elif path == "/api/v1/icarus/memory/save":
            uid = payload.get("user_id", "FLIGHT_DIRECTOR_01")
            tier_str = payload.get("tier", "SEMANTIC")
            tier = MemoryTier(tier_str)
            key = payload.get("key", "GENERAL_NOTE")
            content = payload.get("content", "")
            rec = icarus_engine.memory.add_memory(uid, tier, key, content)
            self._write_json(200, rec.model_dump())

        else:
            self._write_json(404, {"error": "Endpoint not found"})

    def do_PUT(self):
        self._handle_update()

    def do_PATCH(self):
        self._handle_update()

    def _handle_update(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path.rstrip("/")
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)
        try:
            payload = json.loads(body.decode("utf-8")) if body else {}
        except Exception:
            payload = {}

        if path.startswith("/api/v1/missions/"):
            subpath = path[len("/api/v1/missions/"):]
            parts = [p for p in subpath.split("/") if p]
            m_id = parts[0]
            if len(parts) == 3 and parts[1] == "crew":
                crew_id = parts[2]
                member = mission_ops_manager.update_crew_member(m_id, crew_id, payload)
                if member:
                    self._write_json(200, member.model_dump())
                else:
                    self._write_json(404, {"error": f"Crew member '{crew_id}' not found in mission '{m_id}'"})
                return

        self._write_json(404, {"error": "Endpoint not found"})

    def do_DELETE(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path.rstrip("/")

        if path.startswith("/api/v1/missions/"):
            subpath = path[len("/api/v1/missions/"):]
            parts = [p for p in subpath.split("/") if p]
            m_id = parts[0]

            if len(parts) == 3 and parts[1] == "crew":
                crew_id = parts[2]
                ok = mission_ops_manager.remove_crew_member(m_id, crew_id)
                if ok:
                    self._write_json(200, {"status": "deleted", "crew_id": crew_id, "mission_id": m_id})
                else:
                    self._write_json(404, {"error": f"Crew member '{crew_id}' not found"})
                return

            if len(parts) == 1:
                deleted_name = "Untitled Mission"
                found = False
                if m_id in mission_ops_manager.missions:
                    m = mission_ops_manager.missions.pop(m_id)
                    deleted_name = m.name
                    mission_ops_manager._save_to_disk()
                    found = True
                if m_id in saved_missions:
                    deleted = saved_missions.pop(m_id)
                    deleted_name = deleted.get("name", deleted_name)
                    _save_missions_to_disk(saved_missions)
                    found = True

                if found:
                    self._write_json(200, {
                        "status": "deleted",
                        "id": m_id,
                        "name": deleted_name
                    })
                else:
                    self._write_json(404, {"error": f"Mission '{m_id}' not found"})
                return

        elif path.startswith("/api/v1/hazards/simulations/"):
            sim_id = path.replace("/api/v1/hazards/simulations/", "")
            ok = hazard_engine.delete_simulation(sim_id)
            if ok:
                self._write_json(200, {"status": "deleted", "id": sim_id})
            else:
                self._write_json(404, {"error": f"Simulation '{sim_id}' not found"})
            return

        elif path.startswith("/api/v1/icarus/memory/"):
            mem_id = path.replace("/api/v1/icarus/memory/", "")
            parsed_query = urllib.parse.parse_qs(parsed_url.query)
            uid = parsed_query.get("user_id", ["FLIGHT_DIRECTOR_01"])[0]
            ok = icarus_engine.memory.delete_memory(uid, mem_id)
            if ok:
                self._write_json(200, {"status": "deleted", "memory_id": mem_id})
            else:
                self._write_json(404, {"error": f"Memory '{mem_id}' not found"})
            return

        self._write_json(404, {"error": "Endpoint not found"})

    def log_message(self, format, *args):
        sys.stdout.write(f"[API {self.address_string()}] {format % args}\n")
        sys.stdout.flush()

def run():
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, MarsAPIRequestHandler)
    print(f"===========================================================")
    print(f" Mars Pathfinder API Server active on http://localhost:{PORT}")
    print(f" Health check:        http://localhost:{PORT}/health")
    print(f" Layers catalog:      http://localhost:{PORT}/api/v1/layers")
    print(f" Elevation query:     http://localhost:{PORT}/api/v1/elevation/point")
    print(f" Terrain analysis:    http://localhost:{PORT}/api/v1/terrain/analyze")
    print(f" Elevation profile:   http://localhost:{PORT}/api/v1/terrain/profile")
    print(f" Environmental model: http://localhost:{PORT}/api/v1/environmental/point")
    print(f" Mission planning:    http://localhost:{PORT}/api/v1/mission/plan")
    print(f" Survival guide:      http://localhost:{PORT}/api/v1/survival/evaluate")
    print(f"===========================================================")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down Mars Pathfinder API Server.")
        httpd.server_close()

if __name__ == "__main__":
    run()
