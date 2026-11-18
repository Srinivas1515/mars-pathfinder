package worker

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestScientificWorker_QueryPointElevation(t *testing.T) {
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get working directory: %v", err)
	}

	workspaceRoot := filepath.Clean(filepath.Join(wd, ".."))
	testImg := filepath.Join(workspaceRoot, "data", "raw", "megt90n000cb.img")
	if _, err := os.Stat(testImg); os.IsNotExist(err) {
		t.Skipf("Skipping test: MOLA raster not found at %s", testImg)
	}

	w := NewScientificWorker(workspaceRoot)
	ctx := context.Background()

	// 1. Test Olympus Mons (Directly Observed)
	res, err := w.QueryPointElevation(ctx, 18.65, 226.2)
	if err != nil {
		t.Fatalf("QueryPointElevation returned unexpected error: %v", err)
	}

	if res.ElevationM < 19000.0 {
		t.Errorf("Expected Olympus Mons elevation > 19,000m, got %f", res.ElevationM)
	}

	if res.ProductID != "MEGT90N000CB.IMG" {
		t.Errorf("Expected product ID MEGT90N000CB.IMG, got %s", res.ProductID)
	}

	if !res.IsDirectlyObserved || res.ObservationStatus != "observed" || res.ObservationCount <= 0 {
		t.Errorf("Expected Olympus Mons to be directly observed with count > 0, got status=%s count=%d observed=%v",
			res.ObservationStatus, res.ObservationCount, res.IsDirectlyObserved)
	}

	// 2. Test Jezero Crater (Directly Observed)
	resJezero, err := w.QueryPointElevation(ctx, 18.4, 77.4)
	if err != nil {
		t.Fatalf("QueryPointElevation for Jezero returned error: %v", err)
	}

	if !resJezero.IsDirectlyObserved || resJezero.ObservationCount != 787 {
		t.Errorf("Expected Jezero count=787 and is_directly_observed=true, got count=%d observed=%v",
			resJezero.ObservationCount, resJezero.IsDirectlyObserved)
	}

	// 3. Test Interpolated Polar Point (lat 89.88, lon 1.38)
	resInterp, err := w.QueryPointElevation(ctx, 89.88, 1.38)
	if err != nil {
		t.Fatalf("QueryPointElevation for interpolated point returned error: %v", err)
	}

	if resInterp.IsDirectlyObserved || resInterp.ObservationStatus != "interpolated" || resInterp.ObservationCount != 0 {
		t.Errorf("Expected polar cell to be marked interpolated with count=0, got status=%s count=%d observed=%v",
			resInterp.ObservationStatus, resInterp.ObservationCount, resInterp.IsDirectlyObserved)
	}
}
