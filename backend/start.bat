@echo off
echo ========================================================
echo   Starting Cook-Ed FastAPI Backend & AI Pipeline
echo ========================================================
cd /d "%~dp0"
if not exist .env (
    if exist backend.env (
        echo Creating .env from backend.env...
        copy backend.env .env
    ) else if exist .env.example (
        echo Creating .env from .env.example...
        copy .env.example .env
    )
    echo Please make sure your GEMINI_API_KEY is added to .env!
)

if exist .venv\Scripts\activate.bat (
    call .venv\Scripts\activate.bat
)

python run.py
pause
