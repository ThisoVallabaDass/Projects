#!/usr/bin/env python3
"""
Nila YearZero — One-command setup.
Run: python setup.py
"""

import subprocess
import sys
import os

# Fix Windows encoding for emoji
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def run(cmd, description):
    """Run a shell command with status display."""
    print(f"\n→ {description}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"  ✅ Done")
    else:
        print(f"  ⚠️  Warning: {result.stderr[:200] if result.stderr else 'unknown error'}")
    return result.returncode == 0


def main():
    print("=" * 60)
    print("🌙 NILA YEARZERO — SETUP")
    print("   Multi-LLM Council: Gemini + Groq + OpenRouter + Ollama")
    print("=" * 60)

    # 1. Install Python deps
    run("pip install -r requirements.txt -q", "Installing Python dependencies")

    # 2. Check Ollama
    result = subprocess.run("ollama list", shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print("\n❌ Ollama not found. Install from: https://ollama.ai")
        print("   After installing, run 'ollama serve' and try again.")
        sys.exit(1)

    print("\n→ Checking local models...")
    models_output = result.stdout
    available_models = []
    for model_name in ["llama3.1", "phi3", "deepseek-coder", "nomic-embed-text", "mistral", "nila"]:
        if model_name in models_output:
            available_models.append(model_name)
            print(f"  ✅ {model_name}")

    # 3. Pull missing models
    required_models = ["llama3.1:8b"]
    recommended_models = ["phi3", "deepseek-coder", "nomic-embed-text"]

    for model in required_models:
        base = model.split(":")[0]
        if base not in models_output:
            print(f"\n→ Downloading {model} (required, one-time)...")
            os.system(f"ollama pull {model}")

    for model in recommended_models:
        if model not in models_output:
            print(f"  ℹ️  Optional: ollama pull {model}")

    # 4. Build training dataset
    print("\n→ Building training dataset from your existing data...")
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    training_count = 0
    try:
        from training.memory_trainer import MemoryTrainer
        trainer = MemoryTrainer()
        training_count = trainer.build_training_dataset()
        trainer.inject_into_modelfile(training_count)
    except Exception as e:
        print(f"  ⚠️  Training build skipped: {e}")

    # 5. Create custom Nila model
    print("\n→ Creating custom Nila model in Ollama...")
    modelfile_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "training", "Modelfile")
    if os.path.exists(modelfile_path):
        os.system(f'ollama create nila -f "{modelfile_path}"')
        print("  ✅ Nila model created")
    else:
        print(f"  ⚠️  Modelfile not found at {modelfile_path}")

    # 6. Check .env
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            env_content = f.read()
        print("\n→ Checking API keys in .env...")
        if "GOOGLE_API_KEY" in env_content and len([l for l in env_content.split("\n") if l.startswith("GOOGLE_API_KEY=") and len(l) > 20]) > 0:
            print("  ✅ Gemini API key configured")
        else:
            print("  ⚠️  GOOGLE_API_KEY missing — get one at https://aistudio.google.com/app/apikey")
        if "GROQ_API_KEY" in env_content and len([l for l in env_content.split("\n") if l.startswith("GROQ_API_KEY=") and len(l) > 20]) > 0:
            print("  ✅ Groq API key configured")
        else:
            print("  ℹ️  GROQ_API_KEY not set — get free key at https://console.groq.com")
        if "OPENROUTER_API_KEY" in env_content and len([l for l in env_content.split("\n") if l.startswith("OPENROUTER_API_KEY=") and len(l) > 25]) > 0:
            print("  ✅ OpenRouter API key configured")
        else:
            print("  ℹ️  OPENROUTER_API_KEY not set — get free key at https://openrouter.ai")
    else:
        print("\n  ❌ .env file missing! Create it with at minimum:")
        print("     GOOGLE_API_KEY=your-key-here")

    # 7. Summary
    print("\n" + "=" * 60)
    print("✅ NILA SETUP COMPLETE")
    print("=" * 60)
    print(f"\n  Training data: {training_count} Q&A pairs built")
    print(f"  Local models: {', '.join(available_models) if available_models else 'none detected'}")
    print("\n  The Nila Council uses:")
    print("    📡 Gemini 2.5 Flash — Research, planning, web search")
    print("    ⚡ Groq (llama-3.1-70b) — Fast online backup")
    print("    🌐 OpenRouter — 100+ models access")
    print("    🖥️ Nila Local (Ollama) — Personal memory, Tamil, offline")
    print("    📊 Data Engine — Instant JSON answers")
    print(f"\n  Run Nila: python main.py")
    print("=" * 60)


if __name__ == "__main__":
    main()
