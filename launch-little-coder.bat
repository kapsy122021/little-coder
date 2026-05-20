@echo off
setlocal

if /i not "%~1"=="--run" (
  start "little-coder" cmd /k call "%~f0" --run %*
  exit /b 0
)
shift

set "MODEL=%~1"
if "%MODEL%"=="" set "MODEL=llamacpp/qwen3.6:27b"

where docker >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker CLI not found in PATH.
  echo Install Docker Desktop and try again.
  pause
  exit /b 1
)

set "CONTAINER="
for /f "tokens=*" %%i in ('docker ps --filter "name=^/little-coder$" --format "{{.Names}}"') do set "CONTAINER=%%i"

if /i not "%CONTAINER%"=="little-coder" (
  echo [ERROR] Container "little-coder" is not running.
  echo Start it first with: bash infra/start.sh
  pause
  exit /b 1
)

echo Launching little-coder with model: %MODEL%
docker exec -it little-coder little-coder --model %MODEL%

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo little-coder exited with code %EXIT_CODE%.
  pause
)

exit /b %EXIT_CODE%