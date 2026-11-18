@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

REM APD Quest — one-click game launch (no full editor).
REM Double-click this file, or: run.bat

set "PROJECT_DIR=%cd%"

if not exist "%PROJECT_DIR%\project.godot" (
  echo [BLAD] Brak project.godot w:
  echo   %PROJECT_DIR%
  echo Uruchom ten skrypt z folderu apd-quest-godot.
  pause
  exit /b 1
)

findstr /C:"run/main_scene" "%PROJECT_DIR%\project.godot" >nul 2>&1
if errorlevel 1 (
  echo [BLAD] Ten folder nie ma glownej sceny ^(run/main_scene^).
  echo To wyglada na pusty / zagniezdzony projekt Godot, nie na APD Quest.
  echo Otworz folder apd-quest-godot z plikiem project.godot o nazwie "APD Quest".
  echo Nie otwieraj podfolderow typu apd\ albo apd-gra\.
  pause
  exit /b 1
)

set "GODOT="

REM --- 1) Prefer real Godot .exe under Downloads / common installs (skip PATH wrappers first) ---
set "CANDIDATES="
set "CANDIDATES=!CANDIDATES!;%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
set "CANDIDATES=!CANDIDATES!;%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64.exe"
set "CANDIDATES=!CANDIDATES!;%USERPROFILE%\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;%USERPROFILE%\Downloads\Godot_v4.3-stable_win64\Godot_v4.3-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;%LOCALAPPDATA%\Programs\Godot\Godot.exe"
set "CANDIDATES=!CANDIDATES!;C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;C:\Program Files\Godot\Godot.exe"
set "CANDIDATES=!CANDIDATES!;C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
set "CANDIDATES=!CANDIDATES!;C:\Godot\Godot.exe"

for %%P in (!CANDIDATES!) do (
  if exist "%%~P" (
    set "GODOT=%%~P"
    goto :found
  )
)

REM --- 2) Scan Downloads for Godot 4.* win64 console (skip mono) ---
for /f "delims=" %%F in ('dir /s /b "%USERPROFILE%\Downloads\Godot_v4*_win64_console.exe" 2^>nul') do (
  echo %%F | findstr /I "mono" >nul
  if errorlevel 1 (
    set "GODOT=%%F"
    goto :found
  )
)
for /f "delims=" %%F in ('dir /s /b "%USERPROFILE%\Downloads\Godot_v4*_win64.exe" 2^>nul') do (
  echo %%F | findstr /I "mono console" >nul
  if errorlevel 1 (
    set "GODOT=%%F"
    goto :found
  )
)

REM --- 3) PATH last (godot.cmd wrappers OK as fallback) ---
for /f "delims=" %%I in ('where godot 2^>nul') do (
  set "GODOT=%%I"
  goto :found
)
for /f "delims=" %%I in ('where godot.cmd 2^>nul') do (
  set "GODOT=%%I"
  goto :found
)

echo [BLAD] Nie znaleziono Godot 4.
echo.
echo Zainstaluj Godot 4.3+ ^(zalecane 4.7.2, wersja standardowa — nie mono^)
echo   https://godotengine.org/download/windows/
echo albo rozpakuj do:
echo   %USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\
echo.
pause
exit /b 1

:found
echo.
echo === APD Quest ===
echo Projekt: %PROJECT_DIR%
echo Godot:   %GODOT%
echo Tryb:    gra ^(bez pelnego edytora^)
echo.
"%GODOT%" --path "%PROJECT_DIR%" %*
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
  echo.
  echo [BLAD] Godot zakonczyl sie kodem %ERR%.
  echo Jesli komunikat to "no main scene" — otworzyles zly folder projektu.
  echo Jesli SCRIPT ERROR / class_name — zrob git pull (preload fix).
  pause
)
exit /b %ERR%
