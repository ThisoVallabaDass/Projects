"""
Nila — YearZero AI Agent (Speed Routing + Voice)
Entry point — starts the interactive terminal chat loop.
Supports both text CLI and wake-word voice modes.
Run: python main.py
"""

import sys
import asyncio
from rich.console import Console
from rich.panel import Panel
from rich.markdown import Markdown
from rich.spinner import Spinner
from rich.live import Live
from rich.text import Text
from rich.table import Table

from core.config import validate_config
from core.agent import NilaAgent
from core.memory import MemoryStore

from voice.listener import VoiceListener
from voice.speaker import Speaker
from voice.audio_utils import CHIME_ACTIVATE, CHIME_DEACTIVATE, play_chime

console = Console()

# ── Colour palette ──
AMBER = "#F59E0B"
WARM_ORANGE = "#FB923C"
DIM_GRAY = "#6B7280"
SOFT_WHITE = "#F9FAFB"
GREEN = "#10B981"
BLUE = "#3B82F6"
RED = "#EF4444"
CYAN = "#06B6D4"
PURPLE = "#8B5CF6"
YELLOW = "#EAB308"


def print_banner(agent_mode: str = "auto"):
    """Display a clean, minimal Nila banner."""
    console.print(f"\n[bold #FB923C]✦ Nila[/bold #FB923C] — ready ({agent_mode})")
    console.print(
        f"  [dim]Commands: [bold]quit[/bold] • "
        f"[bold]status[/bold] • [bold]memory[/bold] • "
        f"[bold]clear[/bold] • [bold]model[/bold] • "
        f"[bold]switch[/bold] • [bold]tokens[/bold] • "
        f"[bold]todo[/bold] • [bold]voice[/bold] • [bold]stop[/bold] • [bold]text-mode[/bold][/dim]\n"
    )


def get_route_display(route: str) -> tuple:
    """Return (icon, label, color) for a routing label."""
    route_upper = route.upper() if route else ""

    if route_upper == "INSTANT_LOCAL":
        return "⚡", "Nila Local (Instant)", GREEN
    elif route_upper == "ONLINE_GEMINI":
        return "📡", "Gemini 2.5 Flash", BLUE
    elif route_upper == "ONLINE_GROQ":
        return "⚡", "Groq — llama-3.1-70b", YELLOW
    elif route_upper == "ONLINE_OPENROUTER":
        return "🌐", "OpenRouter", CYAN
    elif route_upper == "OFFLINE_LOCAL_LLM":
        return "🖥️", "Nila Local", GREEN
    elif route_upper == "COUNCIL":
        return "🤝", "Council Mode (Multi-AI)", PURPLE
    elif route_upper == "AGENT_MODE":
        return "🤖", "Nila Agent Mode", AMBER
    elif route_upper == "DATA_QUERY":
        return "📊", "Instant Data Query", CYAN
    elif route_upper == "SYSTEM":
        return "⚙️", "System Command", DIM_GRAY
    else:
        return "💬", route or "Unknown", DIM_GRAY


def display_response(text: str, route: str, memory_facts_count: int):
    """Render Nila's response in an amber panel with a minimal routing indicator."""
    md = Markdown(text)
    panel = Panel(
        md,
        title="[bold]🌙 Nila[/bold]",
        title_align="left",
        border_style=AMBER,
        padding=(1, 2),
    )
    console.print(panel)

    # Minimal routing indicator
    icon, model_info, color = get_route_display(route)
    console.print(f"  [dim]{icon} {model_info.lower()}[/dim]")


def display_status(agent: NilaAgent):
    """Display the system status panel."""
    status = agent.get_system_status()

    table = Table(
        show_header=False,
        box=None,
        padding=(0, 2),
        expand=False,
    )
    table.add_column("Key", style="bold #F59E0B", min_width=20)
    table.add_column("Value", style="white")

    # Model status
    ollama_status = f"[bold green]✅ {status['ollama_model']} (online)[/bold green]" if status["ollama_available"] else "[bold red]❌ Unavailable[/bold red]"
    gemini_status = f"[bold green]✅ Connected[/bold green]" if status["gemini_available"] else "[bold red]❌ Unavailable[/bold red]"

    # Check Groq/OpenRouter
    groq_ok = agent._groq and agent._groq.is_available()
    openrouter_ok = agent._openrouter and agent._openrouter.is_available()
    groq_status = "[bold green]✅ Connected[/bold green]" if groq_ok else "[bold red]❌ No API key[/bold red]"
    openrouter_status = "[bold green]✅ Connected[/bold green]" if openrouter_ok else "[bold red]❌ No API key[/bold red]"

    table.add_row("📡 Gemini API", gemini_status)
    table.add_row("⚡ Groq API", groq_status)
    table.add_row("🌐 OpenRouter API", openrouter_status)
    table.add_row("🖥️ Local LLM (Ollama)", ollama_status)
    table.add_row("Routing Mode", status["mode"])
    table.add_row("", "")

    # Memory stats
    table.add_row("Facts stored", str(status["facts_count"]))
    table.add_row("Active goals", str(status["goals_count"]))
    table.add_row("Notes", str(status["notes_count"]))
    table.add_row("Conversations", f"{status['conversations_count']} messages")
    table.add_row("", "")

    # Self-trainer stats
    table.add_row("Routines learned", str(status["routines_count"]))
    table.add_row("Preferences", str(status["preferences_count"]))
    table.add_row("Progress entries", str(status["progress_count"]))
    table.add_row("Personal KB items", str(status.get("personal_kb_count", 0)))
    table.add_row("Courses", str(status.get("courses_count", 0)))
    table.add_row("", "")

    # Routing stats
    routing = status.get("routing_stats", {})
    total = routing.get("total_interactions", 0)
    if total > 0:
        table.add_row("Total interactions", str(total))
        table.add_row("  → Gemini", f"{routing.get('online_count', 0)} ({routing.get('online_percentage', 0)}%)")
        table.add_row("  → Local", f"{routing.get('offline_count', 0)} ({routing.get('offline_percentage', 0)}%)")
        table.add_row("  → Council", f"{routing.get('council_count', 0)} ({routing.get('council_percentage', 0)}%)")
        table.add_row("  → Data Query", f"{routing.get('data_query_count', 0)} ({routing.get('data_query_percentage', 0)}%)")
        table.add_row("  → Agent", f"{routing.get('agent_count', 0)} ({routing.get('agent_percentage', 0)}%)")

    panel = Panel(
        table,
        title="[bold]⚡ NILA SYSTEM STATUS[/bold]",
        title_align="left",
        border_style=AMBER,
        padding=(1, 2),
    )
    console.print(panel)


def display_models(agent: NilaAgent):
    """Display available models and their roles."""
    status = agent.get_system_status()
    ollama_models = agent.ollama.list_models() if status["ollama_available"] else []
    groq_ok = agent._groq and agent._groq.is_available()
    openrouter_ok = agent._openrouter and agent._openrouter.is_available()

    table = Table(
        show_header=True,
        box=None,
        padding=(0, 2),
        expand=False,
    )
    table.add_column("Model", style="bold white")
    table.add_column("Status", style="white")
    table.add_column("Role", style="dim white")

    g_status = "[bold green]✅ Online[/bold green]" if status["gemini_available"] else "[bold red]❌ Offline[/bold red]"
    table.add_row("📡 Gemini 2.5 Flash", g_status, "Research, planning, web search, course creation")

    groq_status = "[bold green]✅ Online[/bold green]" if groq_ok else "[bold red]❌ No key[/bold red]"
    table.add_row("⚡ Groq (llama-3.1-70b)", groq_status, "Fast backup, general knowledge")

    or_status = "[bold green]✅ Online[/bold green]" if openrouter_ok else "[bold red]❌ No key[/bold red]"
    table.add_row("🌐 OpenRouter", or_status, "100+ models, backup provider")

    o_status = f"[bold green]✅ Online ({status['ollama_model']})[/bold green]" if status["ollama_available"] else "[bold red]❌ Offline[/bold red]"
    table.add_row("🖥️ Nila Local (Ollama)", o_status, "Personal memory, Tamil, offline")

    if ollama_models:
        table.add_row("", "", "")
        table.add_row("[dim]Local Ollama models:[/dim]", "", "")
        for m in ollama_models:
            active = " [green]← active[/green]" if m.split(":")[0] == status["ollama_model"].split(":")[0] else ""
            table.add_row(f"  {m}", active, "")

    forced = agent.force_model
    mode_row = f"Forced: {forced.upper()}" if forced else "🤝 Auto (Speed-first routing)"

    panel = Panel(
        table,
        title="[bold]🤖 NILA — AVAILABLE MODELS[/bold]",
        subtitle=f"[dim]{mode_row}[/dim]",
        title_align="left",
        border_style=AMBER,
        padding=(1, 2),
    )
    console.print(panel)


async def handle_special_command_async(command: str, agent: NilaAgent, speaker: Speaker) -> bool:
    """Handle meta-commands. Returns True if handled."""
    cmd = command.strip().lower()

    if cmd == "quit":
        console.print(f"\n[bold {AMBER}]👋 See you next time. — Nila[/bold {AMBER}]\n")
        speaker.stop()
        sys.exit(0)

    if cmd == "voice":
        agent.set_voice_mode(True)
        console.print(f"\n[bold {CYAN}]🎤 Voice Mode Enabled. Wake word: 'Hey Nila'[/bold {CYAN}]")
        play_chime(CHIME_ACTIVATE)
        return True

    if cmd in {"text-mode", "text mode"}:
        agent.set_voice_mode(False)
        speaker.stop()
        console.print(f"\n[bold {CYAN}]⌨️ Text Mode Enabled.[/bold {CYAN}]")
        play_chime(CHIME_DEACTIVATE)
        return True

    if cmd == "stop":
        speaker.stop()
        console.print(f"[dim]🔇 Stopped Nila's speech.[/dim]")
        return True

    if cmd == "repeat":
        if speaker.last_text:
            console.print(f"[dim]🗣️ Repeating: {speaker.last_text}[/dim]")
            asyncio.create_task(speaker.repeat())
        else:
            console.print("[dim]Nothing to repeat.[/dim]")
        return True

    if cmd == "memory":
        console.print(Panel(
            agent.memory.pretty_print(),
            title="[bold]📦 Stored Memory[/bold]",
            title_align="left",
            border_style=DIM_GRAY,
            padding=(1, 2),
        ))
        return True

    if cmd == "clear":
        agent.memory.clear_conversations()
        console.print(f"[dim]🗑️  Conversation history cleared (facts & goals preserved).[/dim]\n")
        return True

    if cmd == "tokens":
        console.print(agent.token_tracker.get_status_report())
        console.print()
        return True

    if cmd in {"todo", "to-do", "to do", "today tasks", "tasks"}:
        console.print(agent.course_agent.generate_daily_todo())
        console.print()
        return True

    if cmd == "status":
        display_status(agent)
        return True

    if cmd in {"model", "models"}:
        display_models(agent)
        return True

    # Model switching shortcuts
    if cmd in {"switch gemini", "switch to gemini", "use gemini"}:
        agent.force_model = "gemini"
        console.print(f"[bold {BLUE}]📡 Switched to Gemini (online). Type 'switch auto' to restore.[/bold {BLUE}]\n")
        return True

    if cmd in {"switch groq", "switch to groq", "use groq"}:
        agent.force_model = "groq"
        console.print(f"[bold {YELLOW}]⚡ Switched to Groq (fast, online). Type 'switch auto' to restore.[/bold {YELLOW}]\n")
        return True

    if cmd in {"switch openrouter", "use openrouter"}:
        agent.force_model = "openrouter"
        console.print(f"[bold {CYAN}]🌐 Switched to OpenRouter. Type 'switch auto' to restore.[/bold {CYAN}]\n")
        return True

    if cmd in {"switch local", "switch ollama", "switch to ollama", "use local", "use ollama"}:
        agent.force_model = "ollama"
        console.print(f"[bold {GREEN}]🖥️  Switched to Nila Local (offline). Type 'switch auto' to restore.[/bold {GREEN}]\n")
        return True

    if cmd == "switch auto":
        agent.force_model = None
        console.print(f"[bold {PURPLE}]🤝 Auto mode restored — speed-first routing active.[/bold {PURPLE}]\n")
        return True

    # Retry commands - resend last query to specific provider
    if cmd in {"retry groq", "use groq again", "groq again"}:
        if not agent.last_query:
            console.print("[dim]No previous query to retry.[/dim]\n")
            return True
        agent.force_model = "groq"
        user_input = agent.last_query  # Re-use last query
        spinner_text = " [⚡ GROQ RETRY] Nila is thinking…"
        with Live(
            Spinner("dots", text=spinner_text),
            console=console,
            transient=True,
        ):
            response, route = await agent.chat_async(user_input)
        agent.force_model = None  # Reset to auto mode
        facts_count = len(agent.memory.get_all_facts())
        display_response(response, route, facts_count)
        console.print()
        return True

    if cmd in {"retry openrouter", "use openrouter again", "openrouter again"}:
        if not agent.last_query:
            console.print("[dim]No previous query to retry.[/dim]\n")
            return True
        agent.force_model = "openrouter"
        user_input = agent.last_query  # Re-use last query
        spinner_text = " [🌐 OPENROUTER RETRY] Nila is thinking…"
        with Live(
            Spinner("dots", text=spinner_text),
            console=console,
            transient=True,
        ):
            response, route = await agent.chat_async(user_input)
        agent.force_model = None  # Reset to auto mode
        facts_count = len(agent.memory.get_all_facts())
        display_response(response, route, facts_count)
        console.print()
        return True

    return False


async def handle_interactive_done_async(command: str, agent: NilaAgent, speaker: Speaker) -> bool:
    """Run the terminal quiz flow for `done` before marking today's lesson complete."""
    if command.strip().lower() != "done":
        return False

    course = agent.progress_tracker.latest_course()
    if not course:
        display_response("Course illa Theo. First course create pannalaam.", "AGENT_MODE", len(agent.memory.get_all_facts()))
        return True

    day_number = course.get("progress", {}).get("current_day", 1)
    day = agent.course_agent.find_day(course, day_number)
    if not day:
        display_response("Current day lesson kedaikala.", "AGENT_MODE", len(agent.memory.get_all_facts()))
        return True

    quiz = day.get("end_of_day_quiz", day.get("verification_quiz", []))
    answers = []
    
    console.print(f"\n[bold {AMBER}]Seri Theo! Day {day_number} complete pannuvoma? Quiz time![/bold {AMBER}]\n")
    if agent.voice_mode:
        await speaker.speak(f"Seri Theo! Day {day_number} complete pannuvoma? Quiz time!")

    loop = asyncio.get_event_loop()
    for index, question in enumerate(quiz, 1):
        console.print(f"[bold]Q{index}: {question}[/bold]")
        if agent.voice_mode:
            await speaker.speak(f"Question {index}: {question}")

        console.print(f"[bold {SOFT_WHITE}]You:[/bold {SOFT_WHITE}] ", end="", flush=True)
        user_ans = await loop.run_in_executor(None, sys.stdin.readline)
        answers.append(user_ans.strip())
        
        console.print("[green]Nalla![/green]\n")
        if agent.voice_mode:
            await speaker.speak("Nalla!")

    notes = "\n".join(f"Q{i + 1}: {q}\nA: {a}" for i, (q, a) in enumerate(zip(quiz, answers)))
    result = await loop.run_in_executor(
        None,
        agent.progress_tracker.complete_day,
        course["course_id"],
        day_number,
        answers,
        notes
    )
    
    next_day = result.get("next_day")
    updated_course = result.get("course", course)
    if next_day:
        response = (
            f"Day {day_number} complete! Streak: {updated_course.get('progress', {}).get('streak', 0)} day(s)\n"
            f"Tomorrow: Day {next_day['day']} - {next_day['topic']}"
        )
    else:
        response = f"{course.get('topic')} course complete!"

    display_response(response, "AGENT_MODE", len(agent.memory.get_all_facts()))
    if agent.voice_mode:
        await speaker.speak(response)
    return True


def get_spinner_text(agent: NilaAgent) -> Text:
    """Get spinner text based on current model forcing."""
    forced = agent.force_model
    if forced == "ollama":
        return Text(" [🖥️ LOCAL] Nila is thinking…", style=f"italic {GREEN}")
    elif forced == "gemini":
        return Text(" [📡 GEMINI] Nila is thinking…", style=f"italic {BLUE}")
    elif forced == "groq":
        return Text(" [⚡ GROQ] Nila is thinking…", style=f"italic {YELLOW}")
    elif forced == "openrouter":
        return Text(" [🌐 OPENROUTER] Nila is thinking…", style=f"italic {CYAN}")
    else:
        return Text(" [🤝 AUTO] Nila is thinking…", style=f"italic {PURPLE}")


async def voice_listener_loop(agent: NilaAgent, listener: VoiceListener, speaker: Speaker):
    """Background voice task for continuous wake word monitoring."""
    while True:
        try:
            if not agent.voice_mode:
                await asyncio.sleep(0.5)
                continue

            if speaker.is_speaking:
                await asyncio.sleep(0.2)
                continue

            if listener.wake_engine_type == "none":
                await asyncio.sleep(0.5)
                continue

            # Blocks waiting for wake-word
            text = await listener.listen_once()
            if text and agent.voice_mode and not speaker.is_speaking:
                # Echo the user's voice input to the terminal
                console.print(f"\n[bold {SOFT_WHITE}]You (Voice):[/bold {SOFT_WHITE}] [italic]{text}[/italic]")

                # Check cancel commands
                if text.strip().lower() in ["stop", "stop talking", "shut up", "silence"]:
                    speaker.stop()
                    continue
                if text.strip().lower() in ["text mode", "text-mode"]:
                    agent.set_voice_mode(False)
                    speaker.stop()
                    console.print(f"\n[bold {CYAN}]⌨️ Text Mode Enabled.[/bold {CYAN}]")
                    play_chime(CHIME_DEACTIVATE)
                    continue

                spinner_text = get_spinner_text(agent)
                with Live(
                    Spinner("dots", text=spinner_text),
                    console=console,
                    transient=True,
                ):
                    tokens = agent.chat_stream(text)
                    await speaker.speak_stream(tokens)

                facts_count = len(agent.memory.get_all_facts())
                display_response(speaker.last_text, agent.last_route, facts_count)
                console.print()

        except asyncio.CancelledError:
            break
        except Exception:
            await asyncio.sleep(1)


async def main_async():
    """Run the interactive async Nila chat loop."""
    validate_config()
    agent = NilaAgent()
    
    # Initialize Speaker and Listener
    speaker = Speaker()
    from core.config import PICOVOICE_ACCESS_KEY, VOICE_MODE_DEFAULT, FORCE_MODEL
    listener = VoiceListener(access_key=PICOVOICE_ACCESS_KEY)
    await listener.start()
    
    agent.set_voice_mode(VOICE_MODE_DEFAULT)
    
    mode = "offline" if (agent.force_model == "ollama" or FORCE_MODEL == "ollama") else "auto"
    print_banner(mode)

    # Start the continuous background voice listener loop
    voice_task = asyncio.create_task(voice_listener_loop(agent, listener, speaker))

    loop = asyncio.get_event_loop()

    try:
        while True:
            # Print appropriate prompt
            if agent.voice_mode:
                console.print(f"[bold {CYAN}]🎤 VOICE (Say 'Hey Nila' or type):[/bold {CYAN}] ", end="", flush=True)
            else:
                console.print(f"[bold {SOFT_WHITE}]You:[/bold {SOFT_WHITE}] ", end="", flush=True)

            # Read user console input asynchronously
            user_input = await loop.run_in_executor(None, sys.stdin.readline)
            user_input = user_input.strip()

            if not user_input:
                continue

            # Interrupt speech if user types stop or silence
            if user_input.lower() in ["stop", "stop talking", "silence"]:
                speaker.stop()
                continue

            if await handle_special_command_async(user_input, agent, speaker):
                continue

            if await handle_interactive_done_async(user_input, agent, speaker):
                continue

            spinner_text = get_spinner_text(agent)
            if agent.voice_mode:
                # Voice mode: stream to speaker & display response
                with Live(
                    Spinner("dots", text=spinner_text),
                    console=console,
                    transient=True,
                ):
                    tokens = agent.chat_stream(user_input)
                    await speaker.speak_stream(tokens)
                facts_count = len(agent.memory.get_all_facts())
                display_response(speaker.last_text, agent.last_route, facts_count)
                console.print()
            else:
                # Text mode: normal spinner + full text chat
                with Live(
                    Spinner("dots", text=spinner_text),
                    console=console,
                    transient=True,
                ):
                    response, route = await agent.chat_async(user_input)
                facts_count = len(agent.memory.get_all_facts())
                display_response(response, route, facts_count)
                console.print()

    except KeyboardInterrupt:
        console.print(f"\n\n[bold {AMBER}]👋 Interrupted. See you soon! — Nila[/bold {AMBER}]\n")
    finally:
        speaker.stop()
        await listener.stop()
        voice_task.cancel()
        try:
            await voice_task
        except asyncio.CancelledError:
            pass
        sys.exit(0)


def main():
    # Force UTF-8 encoding for standard streams to prevent UnicodeEncodeErrors in Windows console
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
        sys.stdin.reconfigure(encoding='utf-8')
    except Exception:
        pass

    try:
        asyncio.run(main_async())
    except KeyboardInterrupt:
        pass



if __name__ == "__main__":
    main()
