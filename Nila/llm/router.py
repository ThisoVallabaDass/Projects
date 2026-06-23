"""
Hybrid Router — Speed classification + routing statistics for Nila.
Now includes terminal_action as a routing tier.
"""


# Triggers for instant local responses (no API call)
INSTANT_LOCAL = [
    # Greetings
    "hi", "hello", "hey", "vanakkam", "sup", "yo", "hii", "helo",
    "good morning", "good night", "good afternoon", "morning", "night",
    "how are you", "how r u", "how are u", "wassup", "what's up",
    "whatsup", "howdy",
    # Casual short messages
    "ok", "okay", "seri", "seri da", "got it", "understood", "noted",
    "thanks", "thank you", "nandri", "bye", "goodbye", "see you", "later",
    # Emotional short messages
    "tired", "bored", "happy", "sad", "stressed", "angry",
    "enakku bore", "mosam", "nalla iruku", "bayama iruku",
    # About Nila herself
    "who are you", "what are you", "are you ai", "tell me about yourself",
    "what can you do", "your name", "nee yaru", "enna pannuva",
]

# Triggers for terminal/file operations
TERMINAL_ACTION = [
    # Run commands
    "run ", "execute ", "run command", "run this", "execute this",
    "cmd ", "shell ", "terminal ",
    "pip install", "pip ", "python ", "node ", "npm ",
    "git status", "git add", "git commit", "git push", "git pull", "git log",
    # File reading
    "read file", "open file", "show file", "read the file",
    "contents of", "show me the file", "cat ",
    "file la iruku", "file open pannu", "file padikka",
    # File creation
    "create file", "make file", "new file", "write file",
    "save as", "create a file", "make a new file",
    "file create pannu", "file ezhuthu",
    # Folder operations
    "create folder", "make folder", "new folder", "mkdir",
    "create directory", "make directory", "new directory",
    "folder create pannu",
    # List directory
    "list files", "show files", "what files", "folder contents",
    "show directory", "list directory",
    "files kaatu", "folder la enna iruku",
    # Find/search files
    "find file", "search file", "locate file", "where is the file",
    "find the file", "search for file",
    "file edhu", "file enga",
    # Delete
    "delete file", "remove file", "delete the file",
    "file delete pannu",
]

# Triggers for web-search-required queries
NEEDS_WEB_SEARCH = [
    # Location-based (ALWAYS needs internet)
    "near me", "near avadi", "near chennai", "near saligramam",
    "near my office", "restaurant", "hotel", "kadai", "shop",
    "delivery", "swiggy", "zomato", "order food",
    "dosa", "biriyani", "biryani", "idli", "food",
    # Current information
    "news", "today's news", "latest", "current", "right now",
    "price of", "stock", "weather", "score",
    # Research queries
    "what is", "explain", "how to", "best way to learn",
    "search for", "find me", "look up",
    "tutorial", "resources for",
    # Planning (needs research)
    "create a course", "make a plan", "roadmap for",
    "help me learn", "teach me",
    # General research
    "how do", "how does", "what are", "why is", "why does",
    "compare", "difference between", "what to do",
    "best", "recommend", "spots", "place", "location",
    "where can i", "buy", "price",
]

# Triggers for personal/memory queries (local, with full context)
PERSONAL_LOCAL = [
    "my ", "i am", "i have", "my project", "my sap", "my portal",
    "my table", "my function", "my package", "my work", "my config",
    "what is my", "what's my", "tell me about my",
    "what did i", "do you remember",
    "unakku", "enakku", "en ",
    "unakku theriyuma", "enna solnen",
]


def classify_speed(message: str) -> str:
    """
    Classify the speed/routing tier for a message.

    Returns:
        'instant_local'   — answer in <0.5s using local model already in RAM
        'terminal_action' — file system or command execution
        'needs_web'       — must search internet, use provider chain
        'standard_local'  — local model, personal/memory questions
        'standard_online' — online model, complex but no search needed
    """
    import re
    msg = message.lower().strip()
    words = msg.split()
    
    # ── TERMINAL ACTION (highest priority check) ──────────────────
    # Has a Windows file path?
    has_win_path = bool(re.search(r'[A-Za-z]:\\', message))
    
    # Has file extension?
    has_file_ext = bool(re.search(
        r'\b\w+\.(txt|py|js|html|css|json|md|csv|log|bat|sh|yaml|xml|ts|jsx|vue)\b',
        message, re.I
    ))
    
    # Has terminal/file action keywords?
    terminal_keywords = [
        "create", "make", "build", "generate", "write",
        "read", "open", "show file", "first line", "last line",
        "rename", "delete", "remove file", "move file",
        "list files", "show files", "folder contents",
        "run ", "execute", "pip install", "mkdir",
        "calculator", "web app", "webapp", "application",
        "html file", "python file", "script",
        "inside this folder", "in this folder", "in the folder",
        "inside the folder",
    ]
    has_terminal_keyword = any(kw in msg for kw in terminal_keywords)
    
    # Direct check for file/folder actions
    folder_action = any(kw in msg for kw in ["create folder", "make folder", "new folder", "mkdir", "create a folder", "make a folder", "delete folder", "remove folder", "delete the folder", "remove the folder"])
    file_action = any(kw in msg for kw in ["create file", "make file", "new file", "write file", "create a file", "make a new file", "delete file", "remove file", "delete the file", "remove the file"])
    command_action = any(kw in msg for kw in ["run command", "run ", "execute ", "terminal ", "shell ", "pip install", "npm install", "git "])
    list_action = any(kw in msg for kw in ["list files", "show files", "folder contents", "what's in the folder", "what is in the folder", "list directory", "show directory"])
    app_creation_action = any(kw in msg for kw in ["create a calculator", "create calculator", "make a calculator", "build a calculator", "build calculator", "create a simple calculator", "create web app", "create webapp"])

    if has_win_path or (has_file_ext and has_terminal_keyword) or \
       (has_win_path and has_terminal_keyword) or \
       folder_action or file_action or command_action or list_action or app_creation_action:
        return "terminal_action"
    
    # ── INSTANT LOCAL (ONLY for very short pure greetings) ────────
    # Max 4 words AND must be a greeting/casual phrase
    PURE_GREETINGS = {
        "hi", "hello", "hey", "sup", "yo", "hii",
        "good morning", "good night", "good afternoon",
        "how are you", "how r u", "how are u",
        "bye", "goodbye", "ok", "okay", "seri", "thanks",
        "thank you", "nandri", "vanakkam",
        "tired", "bored", "happy", "sad",
    }
    if len(words) <= 4:
        if any(msg == g or msg.startswith(g) for g in PURE_GREETINGS):
            return "instant_local"
    
    # ── WEB SEARCH needed ─────────────────────────────────────────
    web_keywords = [
        "news", "latest", "current", "today's", "right now",
        "weather", "price", "stock", "score",
        "restaurant", "hotel", "shop", "near me", "near avadi",
        "near chennai", "near saligramam", "near my",
        "swiggy", "zomato", "order food", "delivery",
        "search for", "look up", "find me",
    ]
    if any(kw in msg for kw in web_keywords):
        return "needs_web"
    
    # ── STANDARD LOCAL (personal/memory) ──────────────────────────
    memory_keywords = [
        "my goal", "my course", "my project", "my sap",
        "my table", "my portal", "what did i", "do you remember",
        "enakku theriyum", "unakku theriyuma",
    ]
    if any(kw in msg for kw in memory_keywords):
        return "standard_local"
    
    # ── DEFAULT: online for everything else ───────────────────────
    return "standard_online"



class HybridRouter:
    """
    Tracks which model was used and maintains routing statistics.

    Route categories:
    - online: Gemini / Groq / OpenRouter
    - offline: Ollama local
    - terminal: File/command actions
    - data_query: Direct JSON (no AI)
    - system: Model switching commands
    - agent: Agent mode actions (courses, KB)
    """

    def __init__(self):
        self.route_history = {
            "online": 0,
            "offline": 0,
            "terminal": 0,
            "data_query": 0,
            "system": 0,
            "agent": 0,
        }
        self.interaction_count = 0

    def record(self, route: str):
        """Record which model/path was used for this interaction."""
        self.interaction_count += 1
        route_lower = route.lower()
        if "gemini" in route_lower or "groq" in route_lower or "openrouter" in route_lower:
            self.route_history["online"] += 1
        elif "terminal" in route_lower:
            self.route_history["terminal"] += 1
        elif "local" in route_lower or "offline" in route_lower:
            self.route_history["offline"] += 1
        elif "data" in route_lower:
            self.route_history["data_query"] += 1
        elif "system" in route_lower:
            self.route_history["system"] += 1
        elif "agent" in route_lower:
            self.route_history["agent"] += 1

    def get_stats(self) -> dict:
        """Return routing statistics for monitoring."""
        total = sum(self.route_history.values())
        stats = {
            "total_interactions": self.interaction_count,
        }
        for key, count in self.route_history.items():
            stats[f"{key}_count"] = count
            stats[f"{key}_percentage"] = round((count / max(1, total)) * 100, 1)
        return stats

    def reset_stats(self):
        """Reset routing history."""
        for key in self.route_history:
            self.route_history[key] = 0
        self.interaction_count = 0
