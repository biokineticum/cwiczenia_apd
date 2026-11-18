@echo off
REM Repo-root launcher: cds into apd-quest-godot and starts the game.
cd /d "%~dp0apd-quest-godot"
if not exist "run.bat" (
  echo [BLAD] Brak apd-quest-godot\run.bat
  pause
  exit /b 1
)
call "%~dp0apd-quest-godot\run.bat" %*
exit /b %ERRORLEVEL%
