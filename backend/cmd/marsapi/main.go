package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/marspathfinder/backend/internal/worker"
)

var defaultMapLayers = []fiber.Map{
	{
		"layer_key":              "mola_color_hillshade",
		"name":                   "MGS MOLA Global Color Hillshade",
		"description":            "Vibrant full-color global topographic elevation shaded relief map from Mars Orbiter Laser Altimeter",
		"category":               "elevation",
		"product_type":           "derived_hillshade",
		"mission":                "Mars Global Surveyor",
		"instrument":             "MOLA (Laser Altimeter)",
		"format":                 "image/jpeg",
		"service_type":           "WMTS",
		"service_url":            "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_MOLA_ClrShade_merge_global_463m/1.0.0/default/default028mm/{z}/{y}/{x}.jpg",
		"external_layer_id":      "Mars_MGS_MOLA_ClrShade_merge_global_463m",
		"coordinate_system":      "EPSG:104905",
		"datum":                  "Martian Areoid (MOLA GMM-2B potential, 610.5 Pa)",
		"resolution_m":           463.0,
		"max_zoom":               7,
		"is_global":              true,
		"enabled":                true,
		"attribution":            "NASA / GSFC / USGS Astrogeology",
		"observation_period":     "1997 - 2001",
		"scientific_limitations": "Qualitative colorized shaded relief. Blue = basins/lowlands (-8.2km), Green/Yellow = midlands, Orange/Red/White = volcanic summits (+21.2km).",
	},
	{
		"layer_key":              "viking_mdim21_color",
		"name":                   "Viking MDIM 2.1 Global Color Mosaic",
		"description":            "USGS geodetically controlled global colorized photographic mosaic showing the natural red planet surface",
		"category":               "imagery",
		"product_type":           "measured_observation",
		"mission":                "Viking Orbiter 1 & 2",
		"instrument":             "Visual Imaging Subsystem (VIS)",
		"format":                 "image/jpeg",
		"service_type":           "WMTS",
		"service_url":            "https://trek.nasa.gov/tiles/Mars/EQ/Mars_Viking_MDIM21_ClrMosaic_global_232m/1.0.0/default/default028mm/{z}/{y}/{x}.jpg",
		"external_layer_id":      "Mars_Viking_MDIM21_ClrMosaic_global_232m",
		"coordinate_system":      "EPSG:104905",
		"datum":                  "Mars IAU 2000 Sphere (R = 3,396,190 m)",
		"resolution_m":           232.0,
		"max_zoom":               7,
		"is_global":              true,
		"enabled":                true,
		"attribution":            "NASA / USGS Astrogeology Science Center",
		"observation_period":     "1976 - 1980",
		"scientific_limitations": "Natural Mars red/rust surface color photographic mosaic corrected for atmospheric dust scattering.",
	},
	{
		"layer_key":              "mola_hrsc_blend_200m",
		"name":                   "MOLA + HRSC Blended Color Hillshade",
		"description":            "High-resolution 200m color topography blend combining MOLA vertical datum with Mars Express HRSC stereo details",
		"category":               "elevation",
		"product_type":           "derived_blend",
		"mission":                "MGS & Mars Express",
		"instrument":             "MOLA / HRSC",
		"format":                 "image/jpeg",
		"service_type":           "WMTS",
		"service_url":            "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MOLA_blend200ppx_HRSC_ClrShade_clon0dd_200mpp_lzw/1.0.0/default/default028mm/{z}/{y}/{x}.jpg",
		"external_layer_id":      "Mars_MOLA_blend200ppx_HRSC_ClrShade_clon0dd_200mpp_lzw",
		"coordinate_system":      "EPSG:104905",
		"datum":                  "Martian Areoid (MOLA GMM-2B potential)",
		"resolution_m":           200.0,
		"max_zoom":               8,
		"is_global":              true,
		"enabled":                true,
		"attribution":            "NASA / ESA / DLR / FU Berlin",
		"observation_period":     "1999 - 2014",
		"scientific_limitations": "High-detail color topographic blend. Small localized voids interpolated with MOLA baseline.",
	},
	{
		"layer_key":              "themis_day_ir",
		"name":                   "THEMIS Daytime Infrared Global Mosaic",
		"description":            "Calibrated daytime thermal infrared (Band 9, 12.57 µm) brightness temperature mosaic mapping bedrock vs mantle",
		"category":               "thermal",
		"product_type":           "measured_thermophysical",
		"mission":                "2001 Mars Odyssey",
		"instrument":             "THEMIS",
		"format":                 "image/png",
		"service_type":           "WMTS",
		"service_url":            "https://trek.nasa.gov/tiles/Mars/EQ/THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018/1.0.0/default/default028mm/{z}/{y}/{x}.png",
		"external_layer_id":      "THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018",
		"coordinate_system":      "EPSG:104905",
		"datum":                  "Mars IAU 2000 Sphere",
		"resolution_m":           100.0,
		"max_zoom":               8,
		"is_global":              true,
		"enabled":                true,
		"attribution":            "NASA / JPL / Arizona State University",
		"observation_period":     "2002 - 2018",
		"scientific_limitations": "Radiant brightness temperature modulated by solar incidence angle and local thermophysical properties.",
	},
	{
		"layer_key":              "tes_albedo",
		"name":                   "MGS TES Global Surface Albedo",
		"description":            "Bolometric surface optical reflectivity (0.3-2.9 µm) mapping dust mantling and basaltic bedrock",
		"category":               "albedo",
		"product_type":           "measured_albedo",
		"mission":                "Mars Global Surveyor",
		"instrument":             "TES",
		"format":                 "image/png",
		"service_type":           "WMTS",
		"service_url":            "https://trek.nasa.gov/tiles/Mars/EQ/Mars_MGS_TES_Albedo_mosaic_global_7410m/1.0.0/default/default028mm/{z}/{y}/{x}.png",
		"external_layer_id":      "Mars_MGS_TES_Albedo_mosaic_global_7410m",
		"coordinate_system":      "EPSG:104905",
		"datum":                  "Mars IAU 2000 Sphere",
		"resolution_m":           7410.0,
		"max_zoom":               5,
		"is_global":              true,
		"enabled":                true,
		"attribution":            "NASA / GSFC / ASU",
		"observation_period":     "1999 - 2001",
		"scientific_limitations": "Coarse planetary albedo map (8 ppd). Reflectivity scale: 0.10 (dark basalt) to 0.35 (bright dust mantle).",
	},
}

var presetSites = []fiber.Map{
	{
		"id":          "jezero",
		"name":        "Jezero Crater",
		"latitude":    18.38,
		"longitude":   77.58,
		"elevation_m": -2530.0,
		"target_type": "Ancient Delta & Crater Lake",
		"description": "Perseverance Rover & Ingenuity landing site; rich in ancient phyllosilicate clay deltas.",
	},
	{
		"id":          "gale",
		"name":        "Gale Crater",
		"latitude":    -5.37,
		"longitude":   137.44,
		"elevation_m": -4490.0,
		"target_type": "Sedimentary Mound Sequence",
		"description": "Curiosity Rover exploration site; 5.5 km high Mount Sharp (Aeolis Mons).",
	},
	{
		"id":          "olympus",
		"name":        "Olympus Mons",
		"latitude":    18.65,
		"longitude":   -133.8,
		"elevation_m": 21229.0,
		"target_type": "Shield Volcano Summit",
		"description": "Solar system's largest shield volcano, standing ~21.2 km above datum.",
	},
	{
		"id":          "hellas",
		"name":        "Hellas Planitia",
		"latitude":    -42.7,
		"longitude":   70.0,
		"elevation_m": -7150.0,
		"target_type": "Deep Impact Basin",
		"description": "Deepest planetary basin on Mars with peak atmospheric pressure (~1150 Pa).",
	},
	{
		"id":          "valles",
		"name":        "Valles Marineris",
		"latitude":    -10.0,
		"longitude":   -70.0,
		"elevation_m": -3800.0,
		"target_type": "Tectonic Rift Canyon",
		"description": "Coprates Chasma rift valley spanning over 4,000 km along the Martian equator.",
	},
	{
		"id":          "elysium",
		"name":        "Elysium Planitia",
		"latitude":    4.5,
		"longitude":   155.0,
		"elevation_m": -2610.0,
		"target_type": "Volcanic Smooth Plain",
		"description": "InSight geophysical lander site; flat, safe basaltic plains.",
	},
	{
		"id":          "oxia",
		"name":        "Oxia Planum",
		"latitude":    18.27,
		"longitude":   -24.63,
		"elevation_m": -3050.0,
		"target_type": "Hydrated Clay Plain",
		"description": "ESA Rosalind Franklin rover exploration target; extensive Noachian clays.",
	},
	{
		"id":          "utopia",
		"name":        "Utopia Planitia",
		"latitude":    25.1,
		"longitude":   109.9,
		"elevation_m": -4000.0,
		"target_type": "Vast Subsurface Ice Plain",
		"description": "China Zhurong rover area; vast shallow ground ice sheets detected.",
	},
}

// In-memory mission store fallback
type MissionRecord struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	RoverType   string                 `json:"rover_type"`
	RoutingMode string                 `json:"routing_mode"`
	CreatedAt   string                 `json:"created_at"`
	Plan        map[string]interface{} `json:"plan"`
}

var (
	savedMissionsMu sync.RWMutex
	savedMissions   = make(map[string]MissionRecord)
)

func main() {
	databaseURL := os.Getenv("DATABASE_URL")
	var db *sql.DB
	var err error

	if databaseURL != "" {
		db, err = sql.Open("pgx", databaseURL)
		if err != nil {
			log.Printf("Warning: failed to initialize database connection pool: %v", err)
		} else {
			if err := db.Ping(); err != nil {
				log.Printf("Warning: Database ping failed at startup (service will still run): %v", err)
			} else {
				log.Println("Database connection verified successfully.")
				// Ensure missions table exists
				_, _ = db.Exec(`
					CREATE TABLE IF NOT EXISTS mars_missions (
						id VARCHAR(64) PRIMARY KEY,
						name VARCHAR(255) NOT NULL,
						rover_type VARCHAR(64) NOT NULL,
						routing_mode VARCHAR(64) NOT NULL,
						created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
						plan JSONB NOT NULL
					);
				`)
			}
			defer db.Close()
		}
	} else {
		log.Println("DATABASE_URL not set; running with persistent in-memory mission fallback.")
	}

	// Resolve workspace root for Python scientific worker
	workspaceRoot := os.Getenv("WORKSPACE_ROOT")
	if workspaceRoot == "" {
		if _, err := os.Stat("data/raw"); err == nil {
			workspaceRoot = "."
		} else {
			workspaceRoot = ".."
		}
	}
	sciWorker := worker.NewScientificWorker(workspaceRoot)

	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins: []string{
			"http://localhost:5180",
			"http://127.0.0.1:5180",
			"http://localhost:5173",
			"http://127.0.0.1:5173",
			"http://localhost:8088",
		},
		AllowMethods: []string{
			"GET",
			"POST",
			"PUT",
			"DELETE",
			"OPTIONS",
		},
	}))

	// Health check endpoint
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"service": "mars-pathfinder-api",
			"version": "1.1.0-full-application",
		})
	})

	// Database health check
	app.Get("/api/v1/health/database", func(c fiber.Ctx) error {
		if db == nil {
			return c.Status(503).JSON(fiber.Map{
				"status":  "unavailable",
				"message": "DATABASE_URL is not configured",
			})
		}
		if err := db.Ping(); err != nil {
			return c.Status(503).JSON(fiber.Map{
				"status":  "unavailable",
				"message": err.Error(),
			})
		}
		return c.JSON(fiber.Map{
			"status":   "connected",
			"database": "mars_pathfinder",
		})
	})

	// Planetary regions gazetteer endpoint
	app.Get("/api/v1/regions", func(c fiber.Ctx) error {
		return c.JSON(presetSites)
	})

	// Preset landing sites for Mission Planning & Survival Guide
	app.Get("/api/v1/mission/presets", func(c fiber.Ctx) error {
		return c.JSON(presetSites)
	})

	// NASA Map layers catalog endpoint
	app.Get("/api/v1/layers", func(c fiber.Ctx) error {
		return c.JSON(defaultMapLayers)
	})

	// Single NASA Map layer metadata endpoint
	app.Get("/api/v1/layers/:key", func(c fiber.Ctx) error {
		key := c.Params("key")
		for _, layer := range defaultMapLayers {
			if layer["layer_key"] == key {
				return c.JSON(layer)
			}
		}
		return c.Status(404).JSON(fiber.Map{
			"error": "Layer not found",
		})
	})

	// MODULE 1 & 2: Elevation Point Query with Observation Status
	app.Get("/api/v1/elevation/point", func(c fiber.Ctx) error {
		latStr := c.Query("lat")
		lonStr := c.Query("lon")
		if latStr == "" || lonStr == "" {
			return c.Status(400).JSON(fiber.Map{
				"error": "Query parameters 'lat' and 'lon' are required (degrees)",
			})
		}

		lat, err := strconv.ParseFloat(latStr, 64)
		if err != nil || lat < -90.0 || lat > 90.0 {
			return c.Status(400).JSON(fiber.Map{
				"error": "Invalid latitude: must be float between -90.0 and +90.0 degrees",
			})
		}

		lon, err := strconv.ParseFloat(lonStr, 64)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{
				"error": "Invalid longitude: must be a valid float degree value",
			})
		}

		result, err := sciWorker.QueryPointElevation(c.Context(), lat, lon)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{
				"error": err.Error(),
			})
		}

		return c.JSON(result)
	})

	// MODULE 3: Local Terrain Analysis (Horn slope, aspect, roughness, traversability)
	app.Get("/api/v1/terrain/analyze", func(c fiber.Ctx) error {
		latStr := c.Query("lat")
		lonStr := c.Query("lon")
		if latStr == "" || lonStr == "" {
			return c.Status(400).JSON(fiber.Map{
				"error": "Query parameters 'lat' and 'lon' are required (degrees)",
			})
		}

		lat, err := strconv.ParseFloat(latStr, 64)
		if err != nil || lat < -90.0 || lat > 90.0 {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid latitude (-90.0 to +90.0)"})
		}

		lon, err := strconv.ParseFloat(lonStr, 64)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid longitude"})
		}

		result, err := sciWorker.AnalyzeTerrain(c.Context(), lat, lon)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(result)
	})

	// MODULE 3: Elevation Profile Generator
	app.Get("/api/v1/terrain/profile", func(c fiber.Ctx) error {
		lat1Str := c.Query("start_lat")
		lon1Str := c.Query("start_lon")
		lat2Str := c.Query("dest_lat")
		lon2Str := c.Query("dest_lon")
		samplesStr := c.Query("samples", "50")

		if lat1Str == "" || lon1Str == "" || lat2Str == "" || lon2Str == "" {
			return c.Status(400).JSON(fiber.Map{
				"error": "start_lat, start_lon, dest_lat, and dest_lon are required query parameters",
			})
		}

		lat1, err1 := strconv.ParseFloat(lat1Str, 64)
		lon1, err2 := strconv.ParseFloat(lon1Str, 64)
		lat2, err3 := strconv.ParseFloat(lat2Str, 64)
		lon2, err4 := strconv.ParseFloat(lon2Str, 64)
		samples, _ := strconv.Atoi(samplesStr)
		if samples < 10 || samples > 200 {
			samples = 50
		}

		if err1 != nil || err2 != nil || err3 != nil || err4 != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid coordinate float parameters"})
		}

		result, err := sciWorker.QueryElevationProfile(c.Context(), lat1, lon1, lat2, lon2, samples)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(result)
	})

	// MODULE 4: Environmental & Atmospheric Point Modeling
	app.Get("/api/v1/environmental/point", func(c fiber.Ctx) error {
		latStr := c.Query("lat")
		lonStr := c.Query("lon")
		elevStr := c.Query("elevation")

		if latStr == "" || lonStr == "" {
			return c.Status(400).JSON(fiber.Map{"error": "lat and lon are required"})
		}

		lat, err1 := strconv.ParseFloat(latStr, 64)
		lon, err2 := strconv.ParseFloat(lonStr, 64)
		if err1 != nil || err2 != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid lat or lon"})
		}

		var elev float64
		if elevStr != "" {
			elev, _ = strconv.ParseFloat(elevStr, 64)
		} else {
			// Query elevation if not provided
			ptElev, err := sciWorker.QueryPointElevation(c.Context(), lat, lon)
			if err == nil && ptElev != nil {
				elev = ptElev.ElevationM
			}
		}

		result, err := sciWorker.GetEnvironment(c.Context(), lat, lon, elev)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(result)
	})

	// MODULE 5: Mission Route Planning (Direct Geodesic vs Terrain-Aware)
	type PlanRequest struct {
		StartLat    float64 `json:"start_lat"`
		StartLon    float64 `json:"start_lon"`
		DestLat     float64 `json:"dest_lat"`
		DestLon     float64 `json:"dest_lon"`
		RoverType   string  `json:"rover_type"`
		RoutingMode string  `json:"routing_mode"`
		Samples     int     `json:"samples"`
	}

	app.Post("/api/v1/mission/plan", func(c fiber.Ctx) error {
		var req PlanRequest
		if err := c.Bind().JSON(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request JSON payload"})
		}

		if req.RoverType == "" {
			req.RoverType = "heavy"
		}
		if req.RoutingMode == "" {
			req.RoutingMode = "terrain_aware"
		}
		if req.Samples <= 0 || req.Samples > 150 {
			req.Samples = 50
		}

		result, err := sciWorker.PlanRoute(
			c.Context(),
			req.StartLat,
			req.StartLon,
			req.DestLat,
			req.DestLon,
			req.RoverType,
			req.RoutingMode,
			req.Samples,
		)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(result)
	})

	// MODULE 5: Mission Save & Load Endpoints
	type SaveMissionRequest struct {
		Name        string                 `json:"name"`
		RoverType   string                 `json:"rover_type"`
		RoutingMode string                 `json:"routing_mode"`
		Plan        map[string]interface{} `json:"plan"`
	}

	app.Post("/api/v1/missions", func(c fiber.Ctx) error {
		var req SaveMissionRequest
		if err := c.Bind().JSON(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid mission payload"})
		}

		id := fmt.Sprintf("mission-%d", time.Now().UnixMilli())
		record := MissionRecord{
			ID:          id,
			Name:        req.Name,
			RoverType:   req.RoverType,
			RoutingMode: req.RoutingMode,
			CreatedAt:   time.Now().UTC().Format(time.RFC3339),
			Plan:        req.Plan,
		}

		savedMissionsMu.Lock()
		savedMissions[id] = record
		savedMissionsMu.Unlock()

		return c.Status(201).JSON(record)
	})

	app.Get("/api/v1/missions", func(c fiber.Ctx) error {
		savedMissionsMu.RLock()
		defer savedMissionsMu.RUnlock()

		list := make([]MissionRecord, 0, len(savedMissions))
		for _, m := range savedMissions {
			list = append(list, m)
		}
		return c.JSON(list)
	})

	// MODULE 6: Interplanetary Survival Guide Evaluator
	app.Get("/api/v1/survival/evaluate", func(c fiber.Ctx) error {
		latStr := c.Query("lat")
		lonStr := c.Query("lon")
		name := c.Query("name", "Custom Site")

		if latStr == "" || lonStr == "" {
			return c.Status(400).JSON(fiber.Map{"error": "lat and lon parameters are required"})
		}

		lat, err1 := strconv.ParseFloat(latStr, 64)
		lon, err2 := strconv.ParseFloat(lonStr, 64)
		if err1 != nil || err2 != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid lat or lon coordinates"})
		}

		result, err := sciWorker.EvaluateSurvival(c.Context(), lat, lon, name)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(result)
	})

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("Starting Mars Pathfinder API on :%s", port)
	log.Fatal(app.Listen(":" + port))
}
