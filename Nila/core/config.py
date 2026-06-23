"""
Nila Configuration — YearZero AI Agent
Loads environment variables and exposes configuration constants.
No backend server — all config is local.
"""

import os
import sys
from dotenv import load_dotenv

# Load .env from the project root
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))

# --- API Configuration (Primary: Gemini) ---
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")
MODEL_NAME = "gemini-2.5-flash"
MAX_TOKENS = 2048

# --- Free Online Providers ---
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "openrouter/free")

# --- Online Provider Priority (waterfall order) ---
ONLINE_PROVIDER_PRIORITY = ["gemini", "groq", "openrouter"]

# --- Paths ---
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKSPACE_DIR = os.path.dirname(PROJECT_DIR)
DATA_DIR = os.path.join(PROJECT_DIR, "data")
MEMORY_FILE = os.path.join(DATA_DIR, "memory.json")

# --- Local LLM Configuration ---
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1:8b")
MAX_LOCAL_TOKENS = 2048
LOCAL_MODEL_CONTEXT_LENGTH = 8192
LOCAL_LLM_TEMPERATURE = 0.7

# --- Council Configuration ---
# Force offline usage of the local Ollama server
FORCE_MODEL = "ollama"
COUNCIL_MODE_AUTO = False  # skip auto‑switching to cloud providers
# Base local model name; can be overridden via env var
LOCAL_MODEL = os.getenv("LOCAL_MODEL", "llama3.1:8b")
LOCAL_MODEL_FALLBACK = "phi3:instruct"

# Model capabilities (for routing decisions)
GEMINI_CAN_SEARCH_WEB = True
OLLAMA_CAN_SEARCH_WEB = False
OLLAMA_HANDLES_PERSONAL = True
GEMINI_HANDLES_RESEARCH = True
DATA_QUERY_BYPASS_AI = True  # data queries NEVER go to any AI

# --- RAG Configuration ---
CHROMA_DB_PATH = os.path.join(DATA_DIR, "chroma_db")
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
RAG_TOP_K = 5
EMBEDDING_REINDEX_FREQUENCY = 100

# --- Fine-tuning Configuration ---
AUTO_FINE_TUNE = os.getenv("AUTO_FINE_TUNE", "true").lower() == "true"
FINE_TUNE_FREQUENCY = 50
FINE_TUNE_LEARNING_RATE = 2e-4
TRAINING_DATA_FILE = os.path.join(DATA_DIR, "training_samples.jsonl")

# --- Voice Pipeline Configuration ---
VOICE_MODE_DEFAULT = False          # Start in text mode; type "voice" to switch
WAKE_WORD = "hey nila"              # Wake word phrase
PICOVOICE_ACCESS_KEY = os.getenv("PICOVOICE_ACCESS_KEY", "")
STT_MODEL = os.getenv("STT_MODEL", "base.en")  # faster-whisper model size
TTS_VOICE = os.getenv("TTS_VOICE", "en-IN-NeerjaNeural")
VOICE_CHIME_ENABLED = True          # Play chimes on wake/sleep
VOICE_SILENCE_THRESHOLD = 0.015     # RMS threshold for silence detection
VOICE_MAX_RECORDING_S = 15.0        # Max recording duration in seconds

# --- Validation ---
def validate_config():
    """Check that required config values are present. Exit with instructions if not."""
    if not GOOGLE_API_KEY:
        print("\n❌  GOOGLE_API_KEY is not set!")
        print("─" * 50)
        print("1. Create a file called '.env' in the Nila/ directory")
        print("2. Add this line:  GOOGLE_API_KEY=your-key-here")
        print("3. Get your key from: https://aistudio.google.com/app/apikey")
        print("─" * 50)
        sys.exit(1)
