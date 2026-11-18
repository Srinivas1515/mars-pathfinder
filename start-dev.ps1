# Mars Pathfinder Local Startup Script
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Launching Mars Pathfinder Planetary Exploration System" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Start REST API on Port 8081 (Go Fiber with automatic Smart App Control fallback)
Write-Host "[1/2] Starting Mars Pathfinder API on port 8081..." -ForegroundColor Yellow
$apiCmd = "cd c:\mars-pathfinder\backend; try { go run ./cmd/api } catch { Write-Host 'Smart App Control detected; running Python REST runner...' -ForegroundColor Yellow; & '..\processing\.venv\Scripts\python.exe' server.py }"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $apiCmd

# 2. Start Frontend on Port 5180
Write-Host "[2/2] Starting React Frontend on port 5180..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\mars-pathfinder\frontend; npm.cmd run dev -- --port 5180"

Write-Host ""
Write-Host "Mars Pathfinder services launched:" -ForegroundColor Green
Write-Host "  Frontend (3D Globe & 2D Map): http://localhost:5180" -ForegroundColor Green
Write-Host "  Backend REST API (Go / Python): http://localhost:8081/health" -ForegroundColor Green
Write-Host "  Scientific Worker Engine:     processing/ CLI & Worker Pipeline" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
