# Cook-Ed Backend & AI Pipeline (Python FastAPI)

This is the backend service for **Cook-Ed**, handling video recipe ingestion, Whisper speech-to-text, Gemini Flash multimodal OCR/NLP, portion scaling calculations, and pantry synchronization.

## 🚀 Key Features

1. **Video Recipe Ingestion**:
   - Accepts public links from **TikTok, Instagram Reels, and YouTube Shorts**.
   - Downloads audio tracks with `yt-dlp`.
   - Transcribes audio using **OpenAI Whisper** (Local/Base model).
   - Formats transcription into standardized ingredients (amounts, units, categories) and step-by-step instructions with **Gemini 2.0 Flash / 1.5 Flash**.

2. **Receipt OCR & Itemization**:
   - Takes store receipt photos.
   - Extracts item names, quantities, units, and categories in a single pass with **Gemini Flash**.

3. **Portion Scaling & Stock Reconciliation**:
   - Scales ingredients dynamically according to target diner count (pax).
   - Matches ingredients against the user's pantry in Supabase.
   - Computes status badges: `adequate` (✓), `insufficient` (!), or `missing` (✗).

4. **Meal Confirmation & Stock Deduction**:
   - Triggers atomic deduction of used items from Supabase PostgreSQL inventory.

---

## 🛠️ Setup Instructions

### 1. Requirements
- Python 3.10+
- FFmpeg installed and added to PATH (Required by `yt-dlp` and `whisper` for audio extraction).
  - On Windows with winget: `winget install Gyan.FFmpeg` or download from [ffmpeg.org](https://ffmpeg.org).

### 2. Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 3. Configure `.env`
Create a `.env` file in `backend/`:
```env
GEMINI_API_KEY=your_gemini_api_key_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
WHISPER_MODEL=base
PORT=8000
```
> **Tip**: You can get a free Gemini API key from [Google AI Studio](https://aistudio.google.com/).

### 4. Run the Server
```bash
python run.py
```
Or double-click `start.bat` on Windows.

Interactive Swagger API docs will be available at: **`http://localhost:8000/docs`**
