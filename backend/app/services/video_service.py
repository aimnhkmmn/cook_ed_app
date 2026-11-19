import os
import tempfile
import uuid
from typing import Tuple
import yt_dlp

def detect_platform(url: str) -> str:
    url_lower = url.lower()
    if "tiktok.com" in url_lower:
        return "TikTok"
    elif "instagram.com" in url_lower:
        return "Instagram Reels"
    elif "youtube.com" in url_lower or "youtu.be" in url_lower:
        return "YouTube Shorts"
    return "Social Video"

def download_audio_from_video(url: str) -> Tuple[str, str]:
    """
    Downloads audio track from TikTok, Instagram Reels, or YouTube Shorts using yt-dlp.
    Returns (audio_file_path, video_title).
    """
    temp_dir = tempfile.gettempdir()
    file_id = str(uuid.uuid4())[:8]
    output_template = os.path.join(temp_dir, f"cooked_audio_{file_id}.%(ext)s")

    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': output_template,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '128',
        }],
        'quiet': True,
        'no_warnings': True,
        # Set common browser User-Agent
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            title = info.get('title', 'Cook-Ed Ingested Recipe')
            
            # Formatted file will be .mp3
            final_path = os.path.join(temp_dir, f"cooked_audio_{file_id}.mp3")
            if not os.path.exists(final_path):
                # Fallback to check if another extension was used
                for ext in ['.m4a', '.webm', '.wav', '.opus']:
                    candidate = os.path.join(temp_dir, f"cooked_audio_{file_id}{ext}")
                    if os.path.exists(candidate):
                        final_path = candidate
                        break

            return final_path, title
    except Exception as e:
        raise RuntimeError(f"Failed to extract audio from video link: {str(e)}")
