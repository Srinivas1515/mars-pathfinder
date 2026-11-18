@echo off
title Mars Pathfinder Launcher
echo ========================================================
echo   Launching Mars Pathfinder Planetary Exploration System
echo ========================================================
echo.
echo [1/2] Starting Mars Pathfinder API on port 8081...
start "Mars Pathfinder API (Port 8081)" cmd /k "cd /d %~dp0backend && (go run ./cmd/api || ..\processing\.venv\Scripts\python.exe server.py)"

echo [2/2] Starting React Frontend on port 5180...
start "Mars Pathfinder Frontend (Port 5180)" cmd /k "cd /d %~dp0frontend && npm.cmd run dev -- --port 5180"

echo.
echo ========================================================
echo   Mars Pathfinder is up and running!
echo   * React 3D/2D Frontend: http://localhost:5180
echo   * Mars Pathfinder API:  http://localhost:8081/health
echo   * Scientific Engine:    processing/
echo ========================================================
