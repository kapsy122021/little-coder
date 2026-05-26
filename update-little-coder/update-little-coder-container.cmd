@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "CONTAINER_NAME=%~1"
if "%CONTAINER_NAME%"=="" set "CONTAINER_NAME=little-coder"

set "TARGET_VERSION=%~2"
if "%TARGET_VERSION%"=="" set "TARGET_VERSION=latest"

set "IMAGE_REPO=%~3"
if "%IMAGE_REPO%"=="" set "IMAGE_REPO=little-coder-lock"

set "RAW_LLAMACPP_BASE_URL=%~4"
set "REQUESTED_LLAMACPP_BASE_URL=%RAW_LLAMACPP_BASE_URL%"
if "%REQUESTED_LLAMACPP_BASE_URL%"=="" set "REQUESTED_LLAMACPP_BASE_URL=http://host.docker.internal:8000/v1"

rem Ensure docker compose interpolation uses the requested value even when a
rem conflicting host-level LLAMACPP_BASE_URL is set in the parent shell/user env.
set "LLAMACPP_BASE_URL=%REQUESTED_LLAMACPP_BASE_URL%"

set "NO_PAUSE=0"
if /I "%~5"=="--no-pause" set "NO_PAUSE=1"

set "IS_DEFAULT_CONTAINER=0"
if /I "%CONTAINER_NAME%"=="little-coder" set "IS_DEFAULT_CONTAINER=1"

set "HAS_LLAMACPP_ARG=0"
if not "%RAW_LLAMACPP_BASE_URL%"=="" set "HAS_LLAMACPP_ARG=1"

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_ROOT=%%~fI"
set "COMPOSE_FILE=%REPO_ROOT%\infra\docker-compose.yml"
set "ENV_FILE=%REPO_ROOT%\infra\.env"

where docker >nul 2>&1
if errorlevel 1 (
  echo ERROR: Docker CLI not found in PATH.
  goto :exit_error
)

echo [1/13] Ensuring compose stack is running...
docker inspect -f "{{.State.Running}}" "%CONTAINER_NAME%" 2>nul | findstr /I /C:"true" >nul
if errorlevel 1 (
  if "%IS_DEFAULT_CONTAINER%"=="1" (
    if not exist "%COMPOSE_FILE%" (
      echo ERROR: Compose file not found: %COMPOSE_FILE%
      goto :exit_error
    )
    echo Container "%CONTAINER_NAME%" is not running. Starting stack from compose...
    docker compose -f "%COMPOSE_FILE%" up -d open-terminal little-coder
    if errorlevel 1 (
      echo ERROR: Could not start compose services.
      goto :exit_error
    )
  ) else (
    echo ERROR: Container "%CONTAINER_NAME%" is not running.
    echo        Auto-start is supported only for container name "little-coder".
    goto :exit_error
  )
)

echo [2/13] Enforcing LLAMACPP_BASE_URL in infra/.env...
if "%IS_DEFAULT_CONTAINER%"=="1" (
  if not exist "%ENV_FILE%" (
    echo ERROR: Missing env file: %ENV_FILE%
    echo        Create it from infra/.env.example first.
    goto :exit_error
  )

  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $path='%ENV_FILE%'; $value='%REQUESTED_LLAMACPP_BASE_URL%'; $content=Get-Content -Path $path -Raw; if($content -match '(?m)^LLAMACPP_BASE_URL='){ $content=[regex]::Replace($content,'(?m)^LLAMACPP_BASE_URL=.*$','LLAMACPP_BASE_URL='+$value); } else { if($content.Length -gt 0 -and -not $content.EndsWith([Environment]::NewLine)){ $content += [Environment]::NewLine }; $content += 'LLAMACPP_BASE_URL='+$value+[Environment]::NewLine }; Set-Content -Path $path -Value $content -NoNewline"
  if errorlevel 1 (
    echo ERROR: Failed to update LLAMACPP_BASE_URL in infra/.env.
    goto :exit_error
  )
) else (
  echo Skipping infra/.env enforcement for non-default container "%CONTAINER_NAME%".
)

echo [3/13] Recreating little-coder container so env policy is applied...
if "%IS_DEFAULT_CONTAINER%"=="1" (
  docker compose -f "%COMPOSE_FILE%" up -d --force-recreate little-coder
  if errorlevel 1 (
    echo ERROR: Failed to recreate little-coder container.
    goto :exit_error
  )
) else (
  echo Skipping compose recreate for non-default container "%CONTAINER_NAME%".
)

echo [4/13] Validating runtime policy env vars...
set "ACTUAL_USE_OPEN_TERMINAL="
set "ACTUAL_OPEN_TERMINAL_URL="
set "ACTUAL_MODELS_FILE="
set "ACTUAL_LLAMACPP_BASE_URL="

for /f "usebackq delims=" %%V in (`docker exec "%CONTAINER_NAME%" sh -lc "printf '%%s' \"$LITTLE_CODER_USE_OPEN_TERMINAL\""`) do set "ACTUAL_USE_OPEN_TERMINAL=%%V"
for /f "usebackq delims=" %%V in (`docker exec "%CONTAINER_NAME%" sh -lc "printf '%%s' \"$OPEN_TERMINAL_URL\""`) do set "ACTUAL_OPEN_TERMINAL_URL=%%V"
for /f "usebackq delims=" %%V in (`docker exec "%CONTAINER_NAME%" sh -lc "printf '%%s' \"$LITTLE_CODER_MODELS_FILE\""`) do set "ACTUAL_MODELS_FILE=%%V"
for /f "usebackq delims=" %%V in (`docker exec "%CONTAINER_NAME%" sh -lc "printf '%%s' \"$LLAMACPP_BASE_URL\""`) do set "ACTUAL_LLAMACPP_BASE_URL=%%V"

if /I not "%ACTUAL_USE_OPEN_TERMINAL%"=="1" (
  echo ERROR: Runtime policy mismatch for LITTLE_CODER_USE_OPEN_TERMINAL.
  echo        Expected: 1
  echo        Actual:   %ACTUAL_USE_OPEN_TERMINAL%
  goto :exit_error
)

if /I not "%ACTUAL_OPEN_TERMINAL_URL%"=="http://open-terminal:8000" (
  echo ERROR: Runtime policy mismatch for OPEN_TERMINAL_URL.
  echo        Expected: http://open-terminal:8000
  echo        Actual:   %ACTUAL_OPEN_TERMINAL_URL%
  goto :exit_error
)

if /I not "%ACTUAL_MODELS_FILE%"=="/app/docker.models.json" (
  echo ERROR: Runtime policy mismatch for LITTLE_CODER_MODELS_FILE.
  echo        Expected: /app/docker.models.json
  echo        Actual:   %ACTUAL_MODELS_FILE%
  goto :exit_error
)

if "%IS_DEFAULT_CONTAINER%"=="1" (
  if /I not "%ACTUAL_LLAMACPP_BASE_URL%"=="%REQUESTED_LLAMACPP_BASE_URL%" (
    echo ERROR: Runtime policy mismatch for LLAMACPP_BASE_URL.
    echo        Expected: %REQUESTED_LLAMACPP_BASE_URL%
    echo        Actual:   %ACTUAL_LLAMACPP_BASE_URL%
    goto :exit_error
  )
) else (
  if "%HAS_LLAMACPP_ARG%"=="1" (
    if /I not "%ACTUAL_LLAMACPP_BASE_URL%"=="%REQUESTED_LLAMACPP_BASE_URL%" (
      echo ERROR: Runtime policy mismatch for LLAMACPP_BASE_URL.
      echo        Expected: %REQUESTED_LLAMACPP_BASE_URL%
      echo        Actual:   %ACTUAL_LLAMACPP_BASE_URL%
      goto :exit_error
    )
  )
)

echo [5/13] Verifying local-only model source in /app/docker.models.json...
docker exec "%CONTAINER_NAME%" sh -lc "test -f /app/docker.models.json"
if errorlevel 1 (
  echo ERROR: /app/docker.models.json not found in container.
  goto :exit_error
)

docker exec "%CONTAINER_NAME%" sh -lc "grep -q '\"providers\"' /app/docker.models.json"
if errorlevel 1 (
  echo ERROR: docker.models.json missing providers key.
  goto :exit_error
)

docker exec "%CONTAINER_NAME%" sh -lc "grep -q '\"llamacpp\"' /app/docker.models.json"
if errorlevel 1 (
  echo ERROR: docker.models.json missing providers.llamacpp.
  goto :exit_error
)

docker exec "%CONTAINER_NAME%" sh -lc "grep -q '\"ollama\"' /app/docker.models.json"
if not errorlevel 1 (
  echo ERROR: docker.models.json contains disallowed provider: ollama.
  goto :exit_error
)

docker exec "%CONTAINER_NAME%" sh -lc "grep -q '\"lmstudio\"' /app/docker.models.json"
if not errorlevel 1 (
  echo ERROR: docker.models.json contains disallowed provider: lmstudio.
  goto :exit_error
)

docker exec "%CONTAINER_NAME%" sh -lc "grep -q '\"openai\"' /app/docker.models.json"
if not errorlevel 1 (
  echo ERROR: docker.models.json contains disallowed provider: openai.
  goto :exit_error
)

docker exec "%CONTAINER_NAME%" sh -lc "grep -q '\"anthropic\"' /app/docker.models.json"
if errorlevel 1 (
  rem expected: no anthropic provider
) else (
  echo ERROR: docker.models.json contains disallowed provider: anthropic.
  goto :exit_error
)

echo [6/13] Checking open-terminal external binding is loopback-only...
docker port open-terminal 8000 | findstr /B /C:"127.0.0.1:" >nul
if errorlevel 1 (
  echo ERROR: open-terminal port is not loopback-only.
  goto :exit_error
)

echo [7/13] Checking no Docker socket is mounted into containers...
docker inspect -f "{{json .Mounts}}" "%CONTAINER_NAME%" | findstr /I /C:"docker.sock" >nul
if not errorlevel 1 (
  echo ERROR: Docker socket detected in %CONTAINER_NAME% mounts.
  goto :exit_error
)
docker inspect -f "{{json .Mounts}}" open-terminal | findstr /I /C:"docker.sock" >nul
if not errorlevel 1 (
  echo ERROR: Docker socket detected in open-terminal mounts.
  goto :exit_error
)

echo [8/13] Backup key runtime files inside container...
docker exec "%CONTAINER_NAME%" sh -lc "cp -f /app/docker.models.json /tmp/docker.models.json.bak 2>/dev/null || true"
if errorlevel 1 goto :exit_error
docker exec "%CONTAINER_NAME%" sh -lc "cp -f ~/.pi/agent/settings.json /tmp/pi.settings.json.bak 2>/dev/null || true"
if errorlevel 1 goto :exit_error

echo [9/13] Uninstall previous global little-coder and clear stale bin shim...
docker exec "%CONTAINER_NAME%" sh -lc "npm uninstall -g little-coder >/dev/null 2>&1 || true"
if errorlevel 1 goto :exit_error
docker exec "%CONTAINER_NAME%" sh -lc "rm -f /usr/local/bin/little-coder"
if errorlevel 1 goto :exit_error

echo [10/13] Install little-coder@%TARGET_VERSION% inside container...
docker exec "%CONTAINER_NAME%" sh -lc "npm install -g little-coder@%TARGET_VERSION%"
if errorlevel 1 (
  echo ERROR: npm install failed.
  goto :exit_error
)

echo [11/13] Detect installed version...
set "LC_VERSION="
for /f "usebackq delims=" %%V in (`docker exec "%CONTAINER_NAME%" sh -lc "npm ls -g little-coder --depth=0 2>/dev/null | sed -n 's/.*little-coder@//p' | head -n1"`) do (
  set "LC_VERSION=%%V"
)

if "%LC_VERSION%"=="" (
  echo ERROR: Could not determine installed little-coder version in container.
  goto :exit_error
)

echo Installed little-coder version: %LC_VERSION%

echo [12/13] Lock this container state into image tags...
docker commit "%CONTAINER_NAME%" %IMAGE_REPO%:lc-v%LC_VERSION% >nul
if errorlevel 1 (
  echo ERROR: docker commit failed.
  goto :exit_error
)
docker tag %IMAGE_REPO%:lc-v%LC_VERSION% %IMAGE_REPO%:latest
if errorlevel 1 (
  echo ERROR: docker tag failed.
  goto :exit_error
)

echo [13/13] Summary
echo   Container: %CONTAINER_NAME%
echo   Installed: little-coder@%LC_VERSION%
echo   LLAMACPP_BASE_URL: %REQUESTED_LLAMACPP_BASE_URL%
echo   Locked image tags:
echo     %IMAGE_REPO%:lc-v%LC_VERSION%
echo     %IMAGE_REPO%:latest
echo.
echo Policy checks passed:
echo   - little-coder tools routed to open-terminal
echo   - local-only model list source (/app/docker.models.json)
echo   - llama egress set to requested LLAMACPP_BASE_URL
echo   - open-terminal exposed only on 127.0.0.1
echo   - no Docker socket mounted in either container
echo.
echo Tip: recreate future containers from %IMAGE_REPO%:latest to keep this locked setup.
if "%NO_PAUSE%"=="0" (
  echo.
  echo Update complete. Press any key to close this window.
  pause >nul
)
exit /b 0

:exit_error
echo.
if "%NO_PAUSE%"=="0" (
  echo Update failed. Press any key to close this window.
  pause >nul
)
exit /b 1
