@echo off
REM Rickpedia V2 — doble clic para abrir la app en el navegador.
cd /d "%~dp0\build\web"
start "" "http://localhost:8081"
python -m http.server 8081
