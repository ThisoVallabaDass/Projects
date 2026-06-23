# 🪷 Nila — YearZero AI Agent

**Nila** (நிலா — Tamil for "moon/companion") is a standalone multi-LLM agent that serves as your personal life coach, accountability partner, and intelligent assistant. It is the intelligence layer of **YearZero**, a personal operating system for self-development.

> **CLI Interface.** Nila operates as a highly optimized, responsive CLI tool with a rich terminal interface.

---

## ✨ Features & Capabilities

- **Strict Routing Waterfall**: Bypasses AI completely for direct data lookups (instant JSON queries).
- **Nila Council (Multi-LLM Collaboration)**:
  - **Online APIs**: Prioritized for research, web search, planning, and course creation. Waterfall: Gemini 2.5 Flash ➔ Groq (Llama-3.1-70B) ➔ OpenRouter.
  - **Local Offline LLM**: A custom `nila` model running on Ollama, trained on your personal memory, goals, and notes. Used for casual chat, Tamil/Tanglish conversing, and offline fallback.
- **Persistent Memory**: Automatically logs facts, routines, preferences, and conversations into local storage.
- **Interactive Course Agent**: Dynamically generates study courses and tracks daily lesson progress.

---

## 🏗️ Architecture

```
                       ┌─────────────────────────┐
                       │      USER TERMINAL      │
                       └────────────┬────────────┘
                                    │
                         [Strict Routing Waterfall]
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         ▼                          ▼                          ▼
   [DATA ENGINE]             [SYSTEM COMMANDS]           [COUNCIL ROUTER]
  Direct JSON Lookup          switch/clear/status         Model Selection &
  (No AI / Instant)           (Instant System)             Collaboration
                                                               │
                                         ┌─────────────────────┴─────────────────────┐
                                         ▼                                           ▼
                                [ONLINE WATERFALL]                          [LOCAL OFFLINE LLM]
                           Gemini ➔ Groq ➔ OpenRouter                       nila model (Ollama)
```

---

## 📁 Project Structure

```
Nila/
├── core/
│   ├── __init__.py
│   ├── agent.py         # NilaAgent core orchestrator
│   ├── config.py        # Configuration and paths
│   └── memory.py        # Local JSON memory database
├── llm/
│   ├── council.py       # NilaCouncil multi-LLM coordinator
│   ├── ollama_client.py # Client wrapper for local Ollama
│   └── providers/
│       ├── groq_client.py
│       └── openrouter_client.py
├── tools/
│   ├── scraper.py       # Web scraper (DuckDuckGo + BeautifulSoup)
│   ├── summariser.py    # Condensed reading tool
│   └── reasoner.py      # Structured planner
├── training/
│   ├── Modelfile        # Ollama system prompt & parameters
│   └── memory_trainer.py# Builds local training dataset from memory
├── main.py              # CLI chat loop with Rich styling
├── setup.py             # Installs dependencies, builds training dataset, and compiles local nila model
└── requirements.txt
```

---

## 🚀 Setup

### 1. Install Dependencies
Initialize and install the required packages:
```bash
pip install -r requirements.txt
```

### 2. Configure Environment `.env`
Create a `.env` file in the project root:
```env
GOOGLE_API_KEY=AIzaSy...
GROQ_API_KEY=gsk_...       # (Optional)
OPENROUTER_API_KEY=sk-or...# (Optional)
OLLAMA_HOST=http://localhost:11434
```

### 3. Build Dataset & Compile Local Model
Run the setup script to download required local models, build the training dataset from your memory, and register the custom `nila` model with Ollama:
```bash
python setup.py
```

### 4. Run Nila
Launch the interactive terminal console:
```bash
python main.py
```

---

## 🎮 Usage & System Commands

| Command | Action |
|---|---|
| `switch gemini` / `use gemini` | Force routing to Gemini (online) |
| `switch groq` / `use groq` | Force routing to Groq (fast online backup) |
| `switch openrouter` / `use openrouter` | Force routing to OpenRouter |
| `switch local` / `use local` | Force routing to Nila Local (offline) |
| `switch auto` | Re-enable automatic council routing |
| `status` | View health and statistics of the Nila council |
| `clear` | Wipe conversation history (keeps goals & facts) |
| `quit` | Exit the application |

---

*Built as part of YearZero — a personal operating system for self-development.*
