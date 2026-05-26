@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "CONTAINER_NAME=%~1"
if "%CONTAINER_NAME%"=="" set "CONTAINER_NAME=little-coder"

set "TARGET_VERSION=%~2"
if "%TARGET_VERSION%"=="" set "TARGET_VERSION=latest"

set "IMAGE_REPO=%~3"
if "%IMAGE_REPO%"=="" set "IMAGE_REPO=little-coder-lock"

echo [1/7] Validating container "%CONTAINER_NAME%"...
docker inspect -f "{{.State.Running}}" "%CONTAINER_NAME%" 2>nul | findstr /I /C:"true" >nul
if errorlevel 1 (
  echo ERROR: Container "%CONTAINER_NAME%" is not running.
  echo        Start it first, then rerun this script.
  exit /b 1
)

echo [2/7] Backup key runtime files inside container...
docker exec %CONTAINER_NAME% sh -lc "cp -f /app/docker.models.json /tmp/docker.models.json.bak 2>/dev/null || true"
if errorlevel 1 exit /b 1
docker exec %CONTAINER_NAME% sh -lc "cp -f ~/.pi/agent/settings.json /tmp/pi.settings.json.bak 2>/dev/null || true"
if errorlevel 1 exit /b 1

echo [3/7] Uninstall previous global little-coder and clear stale bin shim...
docker exec %CONTAINER_NAME% sh -lc "npm uninstall -g little-coder >/dev/null 2>&1 || true"
if errorlevel 1 exit /b 1
docker exec %CONTAINER_NAME% sh -lc "rm -f /usr/local/bin/little-coder"
if errorlevel 1 exit /b 1

echo [4/7] Install little-coder@%TARGET_VERSION% inside container...
docker exec %CONTAINER_NAME% sh -lc "npm install -g little-coder@%TARGET_VERSION%"
if errorlevel 1 (
  echo ERROR: npm install failed.
  exit /b 1
)

echo [5/7] Detect installed version...
set "LC_VERSION="
for /f "usebackq delims=" %%V in (`docker exec %CONTAINER_NAME% sh -lc "npm ls -g little-coder --depth=0 2>/dev/null | sed -n 's/.*little-coder@//p' | head -n1"`) do (
  set "LC_VERSION=%%V"
)

if "%LC_VERSION%"=="" (
  echo ERROR: Could not determine installed little-coder version in container.
  exit /b 1
)

echo Installed little-coder version: %LC_VERSION%

echo [6/7] Lock this container state into image tags...
docker commit %CONTAINER_NAME% %IMAGE_REPO%:lc-v%LC_VERSION% >nul
if errorlevel 1 (
  echo ERROR: docker commit failed.
  exit /b 1
)
docker tag %IMAGE_REPO%:lc-v%LC_VERSION% %IMAGE_REPO%:latest
if errorlevel 1 (
  echo ERROR: docker tag failed.
  exit /b 1
)

echo [7/7] Summary
echo   Container: %CONTAINER_NAME%
echo   Installed: little-coder@%LC_VERSION%
echo   Locked image tags:
echo     %IMAGE_REPO%:lc-v%LC_VERSION%
echo     %IMAGE_REPO%:latest
echo.
echo Tip: recreate future containers from %IMAGE_REPO%:latest to keep the locked setup.
exit /b 0
