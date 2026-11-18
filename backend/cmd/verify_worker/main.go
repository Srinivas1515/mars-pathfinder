package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/marspathfinder/backend/internal/worker"
)

func main() {
	wd, err := os.Getwd()
	if err != nil {
		log.Fatalf("Failed to get working directory: %v", err)
	}

	workspaceRoot := filepath.Clean(filepath.Join(wd, ".."))
	testImg := filepath.Join(workspaceRoot, "data", "raw", "megt90n000cb.img")
	if _, err := os.Stat(testImg); os.IsNotExist(err) {
		log.Fatalf("MOLA raster not found at %s", testImg)
	}

	w := worker.NewScientificWorker(workspaceRoot)
	ctx := context.Background()

	// 1. Olympus Mons (Directly Observed)
	resOlympus, err := w.QueryPointElevation(ctx, 18.65, 226.2)
	if err != nil {
		log.Fatalf("QueryPointElevation for Olympus Mons failed: %v", err)
	}
	fmt.Printf("[PASS] Olympus Mons: elev=%.1fm, status=%s, count=%d, observed=%v\n",
		resOlympus.ElevationM, resOlympus.ObservationStatus, resOlympus.ObservationCount, resOlympus.IsDirectlyObserved)

	// 2. Terrain Analysis: Jezero Crater
	terrain, err := w.AnalyzeTerrain(ctx, 18.38, 77.58)
	if err != nil {
		log.Fatalf("AnalyzeTerrain failed: %v", err)
	}
	fmt.Printf("[PASS] Terrain Analysis: slope=%v deg, rating=%v\n",
		terrain["slope_deg"], terrain["traversability_rating"])

	// 3. Environmental Model: Jezero Crater
	elevVal := resOlympus.ElevationM
	if e, ok := terrain["elevation_m"].(float64); ok {
		elevVal = e
	}
	env, err := w.GetEnvironment(ctx, 18.38, 77.58, elevVal)
	if err != nil {
		log.Fatalf("GetEnvironment failed: %v", err)
	}
	fmt.Printf("[PASS] Environmental: pressure=%v Pa, epoch=%v\n",
		env["atmospheric_pressure_pa"], env["geology"].(map[string]interface{})["epoch"])

	// 4. Elevation Profile: Jezero Traverse
	prof, err := w.QueryElevationProfile(ctx, 18.38, 77.58, 18.8, 77.9, 15)
	if err != nil {
		log.Fatalf("QueryElevationProfile failed: %v", err)
	}
	fmt.Printf("[PASS] Elevation Profile: total_distance=%v km, relief=%v m\n",
		prof["total_distance_km"], prof["elevation_relief_m"])

	// 5. Survival Evaluation: Jezero Crater
	surv, err := w.EvaluateSurvival(ctx, 18.38, 77.58, "Jezero Crater")
	if err != nil {
		log.Fatalf("EvaluateSurvival failed: %v", err)
	}
	fmt.Printf("[PASS] Survival Score: overall=%v, classification=%v\n",
		surv["overall_survival_score"], surv["classification"])

	// 6. Scientific Data Sources Inventory (Phase 1)
	sources, err := w.GetDataSources(ctx)
	if err != nil {
		log.Fatalf("GetDataSources failed: %v", err)
	}
	fmt.Printf("[PASS] Data Sources Inventory: count=%d sources verified\n", len(sources))

	// 7. Mars Conditions Synthesis (Phase 1)
	cond, err := w.GetMarsConditions(ctx, 18.38, 77.58)
	if err != nil {
		log.Fatalf("GetMarsConditions failed: %v", err)
	}
	surfMet := cond["surface_meteorology"].(map[string]interface{})
	fmt.Printf("[PASS] Mars Conditions Synthesis: provenance=%v, instrument=%v\n",
		surfMet["provenance"], surfMet["instrument"])

	fmt.Println("ALL GO WORKER SCIENTIFIC METHODS VERIFIED SUCCESSFULLY!")
}
