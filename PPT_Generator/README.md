# 🎯 KaarTech Corporate PPT Generator

> AI-powered PowerPoint presentation generator for **Kaar Technologies** — takes a topic, calls **Gemini 2.0 Flash**, and outputs a fully branded `.pptx` file with the official KaarTech Corporate Template.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🤖 **AI Content Generation** | Gemini 2.0 Flash generates structured slide content from a single topic |
| 🎨 **Corporate Branding** | Every slide uses the official KaarTech red/dark theme, logos, and fonts |
| 📊 **15+ Slide Layouts** | Cover, agenda, content, process, timeline, comparison, dashboard, table, and more |
| ✏️ **Edit Existing PPTs** | Inspect and edit any `.pptx` file via CLI or interactive AI chat mode |
| 🔌 **Claude Desktop MCP** | Integrated MCP server — generate PPTs by chatting with Claude |
| 📄 **JSON Pipeline** | Save/reload content JSON for iterative refinement without re-calling Gemini |

---

## 📁 Project Structure

```
PPT_Generator/
├── .env.example            ← Copy to .env and add your Gemini API key
├── requirements.txt        ← Python dependencies
├── README.md               ← This file
├── what_to_do.txt          ← Step-by-step beginner setup guide
├── instructions.txt        ← Full feature reference & CLI usage
├── src/
│   ├── ppt_generator.py    ← Main AI-powered generator (1800+ lines)
│   └── ppt_editor.py       ← Standalone editor with inspect/edit/chat modes
├── mcp/
│   ├── server.js           ← MCP server for Claude Desktop integration
│   └── package.json        ← Node.js dependencies
├── reference/              ← Place your KaarTech template here (not tracked)
│   └── KaarTech Corporate PPT Templates - 2024 Guide (2).pptx
└── output/                 ← Generated .pptx files (not tracked)
```

---

## 🚀 Quick Start

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Set Up Your API Key

```bash
copy .env.example .env
# Edit .env and add your Gemini API key
# Get one free at: https://aistudio.google.com/apikey
```

### 3. Add the KaarTech Template

Place the official **KaarTech Corporate PPT Templates - 2024 Guide (2).pptx** in the `reference/` folder. This file is required for branded slide generation.

### 4. Generate a Presentation

```bash
# From a topic (Gemini generates everything)
python src/ppt_generator.py --topic "SAP S/4HANA Migration Guide" --output "migration.pptx"

# From a prompt file
python src/ppt_generator.py --prompt-file my_prompt.txt --output "custom.pptx"

# From pre-generated JSON (skip Gemini)
python src/ppt_generator.py --json-file output/last_content.json --output "rebuilt.pptx"

# Interactive mode
python src/ppt_generator.py
```

---

## ✏️ Edit Existing Presentations

```bash
# Inspect a .pptx file (see all slides, shapes, and text)
python src/ppt_editor.py inspect --file output/my_presentation.pptx

# Apply edits from a JSON file
python src/ppt_editor.py edit --file output/my_ppt.pptx --edits edits.json --output "v2.pptx"

# Interactive AI chat mode (describe edits in plain English!)
python src/ppt_editor.py chat --file output/my_ppt.pptx --output "v2.pptx"
```

---

## 🔌 MCP Server (Claude Desktop)

For Claude Desktop integration:

```bash
cd mcp
npm install
```

Add to `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "kaartech-ppt": {
      "command": "node",
      "args": ["<path-to>/PPT_Generator/mcp/server.js"],
      "env": {
        "GEMINI_API_KEY": "your_key_here"
      }
    }
  }
}
```

Then say to Claude: *"Generate a PPT for the 7 SAP Enterprise Portals"*

### MCP Tools

| Tool | Description |
|------|-------------|
| `generate_ppt` | Gemini AI → content → `.pptx` |
| `generate_ppt_from_json` | Build from pre-structured JSON |
| `list_output_files` | List generated `.pptx` files |
| `get_content_schema` | Return the JSON schema |
| `preview_slide_count` | Estimate slide count from JSON |
| `inspect_pptx` | Show slide structure of any `.pptx` |
| `edit_pptx` | Apply edit operations to a `.pptx` |

---

## 🎨 Supported Slide Types

| Type | Layout | Description |
|------|--------|-------------|
| `overview` | Single content | Intro with overview text + features + SAP module |
| `content_single` | Single column | Text and bullet points |
| `content_two` | Two columns | Side-by-side content |
| `content_three` | Three columns | Three-way split |
| `components` | Auto (2-3 col) | Named components with SAP t-codes |
| `process` | Arrow/Flow/Cycle | Sequential steps (auto-selects layout by count) |
| `dashboard` | Single column | Monitoring metrics with t-codes |
| `comparison` | Two columns | Side-by-side options |
| `timeline` | Horizontal | Time-ordered steps (max 9) |
| `pointer_4` | 4 items | Key highlighted points |
| `circle_4` | 4 items | Connected concepts in circle |
| `quote` | Highlight | Key stat or statement |
| `table` | Data grid | Tabular data with headers |

---

## 🔑 Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| KaarTech Red | `#C0202B` | Titles, accents |
| Dark Navy | `#1A1A2E` | Backgrounds |
| White | `#FFFFFF` | Text on dark slides |
| Body Gray | `#585858` | Body text |

---

## 📝 Dependencies

- **Python 3.10+** — `python-pptx`, `google-generativeai`, `python-dotenv`, `lxml`, `Pillow`, `requests`
- **Node.js 18+** — `@modelcontextprotocol/sdk`, `zod` (for MCP server only)
- **Gemini API Key** — Free from [Google AI Studio](https://aistudio.google.com/apikey)

---

## 👤 Author

**Thiso Vallabadass K** (AID-902015, GE-26 Batch-1) — Kaar Technologies
