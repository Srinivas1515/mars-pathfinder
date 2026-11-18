package worker

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// ScientificWorker defines the interface for Go to execute Python-based scientific processing tasks.
type ScientificWorker struct {
	pythonExecutable string
	workspaceRoot    string
	timeout          time.Duration
}

// ElevationResult represents the scientific elevation and observation support response.
type ElevationResult struct {
	Latitude            float64 `json:"latitude"`
	Longitude           float64 `json:"longitude"`
	ElevationM          float64 `json:"elevation_m"`
	ObservationStatus   string  `json:"observation_status"`   // "observed", "interpolated", "nodata"
	ObservationCount    int     `json:"observation_count"`    // Number of laser altimeter shots in cell
	IsDirectlyObserved  bool    `json:"is_directly_observed"` // True only when count > 0
	VerticalDatum       string  `json:"vertical_datum"`
	DatumRadiusM        float64 `json:"projection_datum_radius_m"`
	ProductID           string  `json:"product_id"`
	CountsProductID     string  `json:"counts_product_id,omitempty"`
	Error               string  `json:"error,omitempty"`
}

// NewScientificWorker initializes a worker with the local Python virtual environment.
func NewScientificWorker(workspaceRoot string) *ScientificWorker {
	pyExe := filepath.Join(workspaceRoot, "processing", ".venv", "Scripts", "python.exe")
	if _, err := os.Stat(pyExe); os.IsNotExist(err) {
		pyExe = "python"
	}

	return &ScientificWorker{
		pythonExecutable: pyExe,
		workspaceRoot:    workspaceRoot,
		timeout:          25 * time.Second,
	}
}

// executePython executes a python script snippet and returns parsed JSON output.
func (w *ScientificWorker) executePython(ctx context.Context, script string, target interface{}) error {
	ctx, cancel := context.WithTimeout(ctx, w.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, w.pythonExecutable, "-c", script)
	cmd.Dir = w.workspaceRoot

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("python worker failed: %w (stderr: %s)", err, stderr.String())
	}

	if err := json.Unmarshal(stdout.Bytes(), target); err != nil {
		return fmt.Errorf("failed to parse worker JSON output: %w (raw: %s)", err, stdout.String())
	}

	return nil
}

// QueryPointElevation invokes the Python processing engine to extract elevation and observation support.
func (w *ScientificWorker) QueryPointElevation(ctx context.Context, lat, lon float64) (*ElevationResult, error) {
	script := fmt.Sprintf(`
import json
from processing.terrain.pds_mola_reader import PDS3LabelParser, MOLAMEGDRRasterInspector
lbl_path = 'data/raw/megt90n000cb.lbl'
img_path = 'data/raw/megt90n000cb.img'
try:
    parsed = PDS3LabelParser.parse_file(lbl_path)
    inspector = MOLAMEGDRRasterInspector(parsed, label_path=lbl_path)
    raster = inspector.read_raster_array(img_path)
    counts = inspector.read_counts_array()
    res = inspector.get_elevation_and_observation_at_coords(raster, counts, %f, %f)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat, lon)

	var res ElevationResult
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if res.Error != "" {
		return nil, fmt.Errorf("worker returned error: %s", res.Error)
	}
	return &res, nil
}

// AnalyzeTerrain invokes the Horn slope, aspect, roughness, and traversability calculation.
func (w *ScientificWorker) AnalyzeTerrain(ctx context.Context, lat, lon float64) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.terrain.terrain_analysis import TerrainAnalyzer
try:
    analyzer = TerrainAnalyzer()
    res = analyzer.analyze_point(%f, %f)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat, lon)

	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if errMsg, ok := res["error"].(string); ok && errMsg != "" {
		return nil, fmt.Errorf("worker returned error: %s", errMsg)
	}
	return res, nil
}

// QueryElevationProfile generates great-circle profile between two points.
func (w *ScientificWorker) QueryElevationProfile(ctx context.Context, lat1, lon1, lat2, lon2 float64, samples int) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.terrain.elevation_profile import ElevationProfileGenerator
try:
    gen = ElevationProfileGenerator()
    res = gen.generate_profile(%f, %f, %f, %f, num_samples=%d)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat1, lon1, lat2, lon2, samples)

	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if errMsg, ok := res["error"].(string); ok && errMsg != "" {
		return nil, fmt.Errorf("worker returned error: %s", errMsg)
	}
	return res, nil
}

// GetEnvironment computes Martian surface environmental metrics.
func (w *ScientificWorker) GetEnvironment(ctx context.Context, lat, lon, elev float64) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.environmental.models import MartianEnvironmentModel
try:
    res = MartianEnvironmentModel.evaluate_point_environment(%f, %f, %f)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat, lon, elev)

	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if errMsg, ok := res["error"].(string); ok && errMsg != "" {
		return nil, fmt.Errorf("worker returned error: %s", errMsg)
	}
	return res, nil
}

// PlanRoute computes direct or terrain-aware traversal routes for rovers.
func (w *ScientificWorker) PlanRoute(ctx context.Context, startLat, startLon, destLat, destLon float64, roverType, mode string, samples int) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.mission.route_planner import MissionRoutePlanner
try:
    planner = MissionRoutePlanner()
    res = planner.plan_route(%f, %f, %f, %f, rover_type='%s', routing_mode='%s', samples=%d)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, startLat, startLon, destLat, destLon, roverType, mode, samples)

	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if errMsg, ok := res["error"].(string); ok && errMsg != "" {
		return nil, fmt.Errorf("worker returned error: %s", errMsg)
	}
	return res, nil
}

// EvaluateSurvival evaluates candidate landing sites across 6 survival pillars.
func (w *ScientificWorker) EvaluateSurvival(ctx context.Context, lat, lon float64, siteName string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.survival.evaluator import SurvivalSiteEvaluator
try:
    evaluator = SurvivalSiteEvaluator()
    res = evaluator.evaluate_site(%f, %f, site_name=%s)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat, lon, fmt.Sprintf("%q", siteName))

	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if errMsg, ok := res["error"].(string); ok && errMsg != "" {
		return nil, fmt.Errorf("worker returned error: %s", errMsg)
	}
	return res, nil
}

// GetDataSources retrieves all registered planetary scientific data sources.
func (w *ScientificWorker) GetDataSources(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    sources = [s.model_dump() for s in reg.list_sources()]
    print(json.dumps(sources))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}


// GetDataSource retrieves detailed metadata for a single data source by ID.
func (w *ScientificWorker) GetDataSource(ctx context.Context, id string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    src = reg.get_source(%q)
    if src:
        print(json.dumps(src.get_metadata().model_dump()))
    else:
        print(json.dumps({"error": "Data source not found"}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, id)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	if errMsg, ok := res["error"].(string); ok && errMsg != "" {
		return nil, fmt.Errorf("%s", errMsg)
	}
	return res, nil
}

// GetDataProducts retrieves cataloged public planetary data products.
func (w *ScientificWorker) GetDataProducts(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    products = [p.model_dump() for p in reg.list_products()]
    print(json.dumps(products))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}


// GetObservations queries scientific observations around coordinates with radius.
func (w *ScientificWorker) GetObservations(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    obs_list = [o.model_dump() for o in reg.get_observations_near(%f, %f, radius_km=%f, limit=%d)]
    print(json.dumps(obs_list))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat, lon, radiusKm, limit)
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}


// GetLatestObservations returns the most recent observation from each source.
func (w *ScientificWorker) GetLatestObservations(ctx context.Context) (map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    latest = reg.get_latest_observations()
    print(json.dumps(latest))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetObservationCoverage returns spatial coverage metrics and polygons.
func (w *ScientificWorker) GetObservationCoverage(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    coverage = [c.model_dump() for c in reg.get_coverage_summary()]
    print(json.dumps(coverage))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}


// GetDataStatus returns pipeline and ingestion freshness status.
func (w *ScientificWorker) GetDataStatus(ctx context.Context) (map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    status = reg.get_data_status()
    print(json.dumps(status))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetDataQuality returns data validation pass rate and anomaly metrics.
func (w *ScientificWorker) GetDataQuality(ctx context.Context) (map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    quality = reg.get_data_quality_report()
    print(json.dumps(quality))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetMarsConditions computes synthesized surface and space weather conditions.
func (w *ScientificWorker) GetMarsConditions(ctx context.Context, lat, lon float64) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    cond = reg.get_mars_conditions(%f, %f)
    print(json.dumps(cond))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, lat, lon)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetObservedHazards returns active planetary and space weather hazards.
func (w *ScientificWorker) GetObservedHazards(ctx context.Context) (map[string]interface{}, error) {
	script := `
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    hazards = reg.get_hazards_observed()
    print(json.dumps(hazards))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// IngestTelemetry ingests a future mission telemetry packet.
func (w *ScientificWorker) IngestTelemetry(ctx context.Context, packet map[string]interface{}) (map[string]interface{}, error) {
	pktJSON, _ := json.Marshal(packet)
	script := fmt.Sprintf(`
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    data = json.loads(%q)
    success, msg, pkt = reg.telemetry.ingest_packet(data)
    print(json.dumps({"success": success, "message": msg, "packet": pkt.model_dump() if pkt else None}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, string(pktJSON))
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetLatestTelemetry returns latest telemetry packets.
func (w *ScientificWorker) GetLatestTelemetry(ctx context.Context, entityId string) ([]map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.data_sources import DataSourceRegistry
try:
    reg = DataSourceRegistry()
    eid = %q if %q != "" else None
    packets = [p.model_dump() for p in reg.telemetry.get_latest_telemetry(eid)]
    print(json.dumps(packets))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, entityId, entityId)
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// ListCrewMissions returns all active and planned missions.
func (w *ScientificWorker) ListCrewMissions(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.crew import mission_ops_manager
try:
    missions = mission_ops_manager.list_missions()
    print(json.dumps(missions))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetCrewMission returns a single mission by ID.
func (w *ScientificWorker) GetCrewMission(ctx context.Context, missionId string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    m = mission_ops_manager.get_mission(%q)
    print(json.dumps(m.model_dump() if m else None))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// CreateCrewMission creates a new mission.
func (w *ScientificWorker) CreateCrewMission(ctx context.Context, payload map[string]interface{}) (map[string]interface{}, error) {
	payloadJSON, _ := json.Marshal(payload)
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    data = json.loads(%q)
    m = mission_ops_manager.create_mission(data)
    print(json.dumps(m.model_dump()))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, string(payloadJSON))
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// StepMissionSimulation advances the mission simulation clock.
func (w *ScientificWorker) StepMissionSimulation(ctx context.Context, missionId string, deltaSeconds float64) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    res = mission_ops_manager.step_simulation(%q, delta_seconds=%f)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId, deltaSeconds)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// TriggerEmergencyScenario injects an emergency scenario into the mission.
func (w *ScientificWorker) TriggerEmergencyScenario(ctx context.Context, missionId, scenarioType, severity, affectedCrewId string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    res = mission_ops_manager.trigger_emergency_scenario(%q, scenario_type=%q, severity=%q, affected_crew_id=%q if %q != "" else None)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId, scenarioType, severity, affectedCrewId, affectedCrewId)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetRescuePlans returns candidate rescue strategies for a mission.
func (w *ScientificWorker) GetRescuePlans(ctx context.Context, missionId string) ([]map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    plans = mission_ops_manager.get_rescue_plans(%q)
    print(json.dumps(plans))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId)
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetMissionResources returns consumable status and duration projections.
func (w *ScientificWorker) GetMissionResources(ctx context.Context, missionId string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    res = mission_ops_manager.get_resource_summary(%q)
    print(json.dumps(res))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetMissionComms returns communications network nodes and links.
func (w *ScientificWorker) GetMissionComms(ctx context.Context, missionId string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    comms = mission_ops_manager.get_comms_network(%q)
    print(json.dumps(comms))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetMissionTimeline returns timeline events stream.
func (w *ScientificWorker) GetMissionTimeline(ctx context.Context, missionId string) ([]map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    events = mission_ops_manager.get_timeline_events(%q)
    print(json.dumps(events))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId)
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetMissionAIRecommendations returns explainable AI recommendations.
func (w *ScientificWorker) GetMissionAIRecommendations(ctx context.Context, missionId string) ([]map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.crew import mission_ops_manager
try:
    recs = mission_ops_manager.get_ai_recommendations(%q)
    print(json.dumps(recs))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`, missionId)
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// ============================================================================
// PHASE 3: Hazard Intelligence, Dust Storm Simulation & Environmental Risk
// ============================================================================

// GetHazardTypes returns catalog of categorized Mars hazards.
func (w *ScientificWorker) GetHazardTypes(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.hazards import hazard_engine
print(json.dumps(hazard_engine.list_hazard_types()))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetHazardScenarios returns predefined benchmark scenarios.
func (w *ScientificWorker) GetHazardScenarios(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.hazards import hazard_engine
print(json.dumps(hazard_engine.list_scenarios()))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetHazardSimulations returns active simulations.
func (w *ScientificWorker) GetHazardSimulations(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.hazards import hazard_engine
print(json.dumps(hazard_engine.list_simulations()))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetHazardSimulation returns specific simulation by id.
func (w *ScientificWorker) GetHazardSimulation(ctx context.Context, simId string) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
sim = hazard_engine.get_simulation(%q)
print(json.dumps(sim if sim else {"error": "Not found"}))
`, simId)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// CreateHazardSimulation starts a new dust storm simulation.
func (w *ScientificWorker) CreateHazardSimulation(ctx context.Context, payload map[string]interface{}) (map[string]interface{}, error) {
	payloadJson, _ := json.Marshal(payload)
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
p = json.loads(%q)
print(json.dumps(hazard_engine.create_simulation(p)))
`, string(payloadJson))
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// StepHazardSimulation advances simulation time by delta hours.
func (w *ScientificWorker) StepHazardSimulation(ctx context.Context, simId string, deltaHours float64) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
res = hazard_engine.step_simulation(%q, delta_hours=%f)
print(json.dumps(res if res else {"error": "Not found"}))
`, simId, deltaHours)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// AssessPointRisk calculates explainable composite risk at point.
func (w *ScientificWorker) AssessPointRisk(ctx context.Context, lat, lon float64, profile string, missing []string) (map[string]interface{}, error) {
	missingJson, _ := json.Marshal(missing)
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
m = json.loads(%q)
print(json.dumps(hazard_engine.assess_point_risk(%f, %f, profile_str=%q, simulate_missing_sensors=m)))
`, string(missingJson), lat, lon, profile)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// AssessRouteRisk evaluates route waypoints against active hazards.
func (w *ScientificWorker) AssessRouteRisk(ctx context.Context, waypoints []map[string]interface{}, simId string, speed float64) (map[string]interface{}, error) {
	wpJson, _ := json.Marshal(waypoints)
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
wps = json.loads(%q)
s_id = %q if %q != "" else None
print(json.dumps(hazard_engine.assess_route_risk(wps, sim_id=s_id, transit_speed_km_h=%f)))
`, string(wpJson), simId, simId, speed)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// EvaluateTerrainProfiles assesses trafficability for all 5 mobility profiles.
func (w *ScientificWorker) EvaluateTerrainProfiles(ctx context.Context, lat, lon float64) (map[string]interface{}, error) {
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
print(json.dumps(hazard_engine.evaluate_terrain(%f, %f)))
`, lat, lon)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// ExtractMLFeatures extracts standardized training features.
func (w *ScientificWorker) ExtractMLFeatures(ctx context.Context, lat, lon *float64, batch bool) (map[string]interface{}, error) {
	latStr := "None"
	lonStr := "None"
	if lat != nil {
		latStr = fmt.Sprintf("%f", *lat)
	}
	if lon != nil {
		lonStr = fmt.Sprintf("%f", *lon)
	}
	batchStr := "False"
	if batch {
		batchStr = "True"
	}
	script := fmt.Sprintf(`
import json
from processing.hazards import hazard_engine
print(json.dumps(hazard_engine.extract_ml_features(lat=%s, lon=%s, batch=%s)))
`, latStr, lonStr, batchStr)
	var res map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}

// GetHistoricalHazards returns historical dust storm and solar flare records.
func (w *ScientificWorker) GetHistoricalHazards(ctx context.Context) ([]map[string]interface{}, error) {
	script := `
import json
from processing.hazards import hazard_engine
print(json.dumps(hazard_engine.get_historical_observations()))
`
	var res []map[string]interface{}
	if err := w.executePython(ctx, script, &res); err != nil {
		return nil, err
	}
	return res, nil
}
