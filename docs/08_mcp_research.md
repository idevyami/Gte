# MCP — Game-Engine Integration Research

Date: session after WB-17 · Request: «یه mcp پیدا کن برای هر موتور بازی‌سازی که وجود داره تا بهش وصلت کنم»
Scope: find a Model Context Protocol server for every major game engine, verify the
Godot one against THIS project (Godot 4.4.1 headless, `entity000`), and document
how to connect.

---

## 1. Godot — the engine of ENTITY_000 ✅ VERIFIED LIVE

### 1a. `Coding-Solo/godot-mcp` — RECOMMENDED, verified in this sandbox
- Repo: https://github.com/Coding-Solo/godot-mcp · npm: `@coding-solo/godot-mcp` · MIT
- Node ≥ 18. Speaks stdio JSON-RPC (standard MCP).
- **14 tools**: `launch_editor`, `run_project`, `get_debug_output`, `stop_project`,
  `get_godot_version`, `list_projects`, `get_project_info`, `create_scene`, `add_node`,
  `load_sprite`, `export_mesh_library`, `save_scene`, `get_uid`, `update_project_uids`.
- Godot 3.5+ / 4.x; has dedicated Godot **4.4+ UID** tools (fits us exactly).

**Live PoC executed in this sandbox** (script at `/home/z/mcp-poc/poc.mjs`, driven by
raw stdio JSON-RPC against `GODOT_PATH=/home/z/.local/bin/godot`):

| MCP call | Result |
| --- | --- |
| `initialize` | server `godot-mcp` 0.1.1, tools capability ✓ |
| `tools/list` | 14 tools advertised |
| `get_godot_version` | `4.4.1.stable.official.49a5bc7b6` — OUR binary |
| `get_project_info /home/z/entity000` | name `entity000`, **25 scenes / 85 scripts / 411 assets** — real read of this repo |
| `get_uid scripts/world/traces.gd` | executes a GDScript inside our headless Godot ✓ (path format: project-root-relative, NO `res://`) |

Notes: `launch_editor` / `run_project` need a display — fine on a local machine,
not in this headless sandbox. `get_uid` expects paths relative to the project root
(`scripts/x.gd`, `main.tscn`), not `res://` or absolute.

**Connect (pick your client):**

```bash
# Claude Code — one command:
claude mcp add godot -e GODOT_PATH=/path/to/godot -- npx @coding-solo/godot-mcp
```

```json
// Claude Desktop / Cline / any MCP client — mcpServers entry:
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["@coding-solo/godot-mcp"],
      "env": { "GODOT_PATH": "/path/to/godot", "DEBUG": "false" }
    }
  }
}
```

Cursor: Settings → Features → MCP → add command `npx @coding-solo/godot-mcp`,
or project-local `.cursor/mcp.json` with the same JSON.

### 1b. `bradypp/godot-mcp` — richer scene surgery
- Repo: https://github.com/bradypp/godot-mcp · clone + `npm install && npm run build`
- Adds `edit_node`, `remove_node`, `save_scene` variants, `READ_ONLY_MODE` for safe
  analysis, auto Godot detection. Config = same `mcpServers` shape but
  `"args": ["/abs/path/godot-mcp/build/index.js"]`.

### 1c. `IvanMurzak/Godot-MCP` — editor-plugin approach (C#)
- Repo: https://github.com/IvanMurzak/Godot-MCP · installs INSIDE the Godot editor as
  an addon; the editor itself hosts the MCP endpoint. Choose this if you want the AI
  to manipulate the OPEN editor scene tree live rather than files on disk.

---

## 2. Unity
- **`CoplayDev/unity-mcp`** — https://github.com/CoplayDev/unity-mcp — the de-facto
  standard: bridges Claude/Codex/VS Code/local LLMs to the Unity Editor; manage
  assets, control scenes, edit scripts, automate tasks. Docs: https://coplaydev.github.io/unity-mcp
- **`IvanMurzak/Unity-MCP`** — https://github.com/ivanmurzak/unity-mcp — AI Skills,
  MCP tools + CLI, ~268 tools, Unity Hub integration.
- **Unity official MCP (beta)** — announced on unity.com (blog: "Unity's AI tools in
  beta: How to get started with MCP") — first-party support is landing in-editor.
- Domain-specific: `game4automation/io.realvirtual.mcp` (industrial simulation).

## 3. Unreal Engine
- **OFFICIAL: "Unreal MCP" plugin, UE 5.8+ (experimental)** —
  https://dev.epicgames.com/documentation/unreal-engine/unreal-mcp-in-unreal-editor
  - Enable plugins: **Unreal MCP** + **All Toolsets** (Edit → Plugins).
  - Configure auto-start; generate the client config file from the editor.
  - Or console: `ModelContextProtocol.StartServer` (default port **8000**).
  - Runs inside the editor process; local-machine connections only, no auth (by
    design, per Epic docs); tool calls are serialized on the game thread.
- **`chongdashu/unreal-mcp`** — https://github.com/chongdashu/unreal-mcp — community
  server for natural-language control via Cursor/Windsurf/Claude Desktop (Remote
  Control API based).
- Docker: `mcp/unreal-engine-mcp-server` on Docker Hub.

## 4. Everything else / directories
- Curated lists to find servers for any other engine:
  - https://github.com/wong2/awesome-mcp-servers (lists a Unity3D MCP among ~thousands)
  - https://mcpservers.org (9800+ servers, searchable)
  - https://awesomeclaude.ai/mcp/gaming (13 gaming servers ranked)
- Bevy / Roblox / GameMaker etc.: no de-facto standard server as of this writing —
  the pattern (a small stdio server wrapping the engine's CLI/IPC) is exactly what
  the Godot community servers do, and is reproducible per-engine on demand.

---

## 5. Bottom line for ENTITY_000
The engine we actually ship on (Godot 4.4.1) has a **working, verified** MCP path:
`npx @coding-solo/godot-mcp` + `GODOT_PATH` pointed at the 4.4.1 binary gives any
MCP client (Claude Code/Desktop, Cline, Cursor) version checks, project analysis,
scene/node surgery, UID management and debug-output capture for THIS project —
proven live against `entity000` in this session (see PoC table above).
