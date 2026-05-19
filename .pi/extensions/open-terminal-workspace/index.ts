import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";

// open-terminal-workspace
// ------------------------
// Routes ALL file/shell operations through the open-terminal container's HTTP
// API instead of letting them touch the little-coder container's own
// filesystem. The agent's "workspace" is therefore the open-terminal sandbox
// (wipable, internet-enabled for GitHub) — not the agent runtime.
//
// Activation: set LITTLE_CODER_USE_OPEN_TERMINAL=1 (set by infra/docker-compose.yml).
// When unset, the extension is a no-op so bare-host dev still works.
//
// Also enforces requirement #1: only llamacpp/* model IDs are accepted
// (the llama-ingress-proxy serves qwen3.6:27b and qwen3.6:27b-nothink).
//
// API surface mapped from open-terminal's /openapi.json:
//   POST /execute?wait=N       { command, cwd?, env? }   -> { stdout, stderr, exit_code }
//   GET  /files/read?path=...                            -> file content
//   POST /files/write          { path, content }         -> ok
//   POST /files/replace        { path, replacements: [{target, replacement, allow_multiple?}] }
//   GET  /files/list?path=&recursive=                    -> entries
//   GET  /files/glob?pattern=                            -> matches
//   GET  /files/grep?pattern=&path=                      -> matches

const ENABLED = process.env.LITTLE_CODER_USE_OPEN_TERMINAL === "1";
const URL_BASE = (process.env.OPEN_TERMINAL_URL || "http://open-terminal:8000").replace(/\/+$/, "");
const API_KEY = process.env.OPEN_TERMINAL_API_KEY || "";

const BLOCKED_BUILTINS = new Set(["Read", "Write", "Edit", "Bash", "bash", "Glob", "Grep"]);
const REDIRECT_MESSAGE =
  "Workspace lives in the open-terminal container. Use OTRead / OTWrite / OTEdit / OTBash / " +
  "OTList / OTGlob / OTGrep instead — built-in Read/Write/Edit/Bash/Glob/Grep are blocked " +
  "because they would operate on the agent runtime's own filesystem.";

function textResult(text: string) {
  return { content: [{ type: "text" as const, text }], details: {} };
}
function errorResult(text: string) {
  return { content: [{ type: "text" as const, text }], details: {}, isError: true };
}

async function otFetch(path: string, init: RequestInit = {}): Promise<any> {
  const url = `${URL_BASE}${path}`;
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...((init.headers as Record<string, string>) ?? {}),
  };
  if (API_KEY) headers["Authorization"] = `Bearer ${API_KEY}`;
  const resp = await fetch(url, { ...init, headers });
  const body = await resp.text();
  if (!resp.ok) {
    throw new Error(`open-terminal ${path} -> HTTP ${resp.status}: ${body.slice(0, 500)}`);
  }
  if (!body) return null;
  try {
    return JSON.parse(body);
  } catch {
    return body;
  }
}

export default function (pi: ExtensionAPI) {
  if (!ENABLED) return;

  // ── Probe llama proxy for advertised context lengths (best-effort) ─────
  // llama-server native /v1/models includes a context_length field per model.
  // llama-swap (current proxy) does not expose it yet, so this is a no-op for
  // now — but will log discovered values automatically once the proxy does.
  // The static fallback in docker.models.json + .pi/settings.json is 122880 (120 K).
  void (async () => {
    const baseUrl = process.env.LLAMACPP_BASE_URL || "http://host.docker.internal:8000/v1";
    const apiKey = process.env.LLAMACPP_API_KEY || "";
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 3000);
      const res = await fetch(`${baseUrl}/models`, {
        signal: controller.signal,
        headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {},
      });
      clearTimeout(timer);
      if (!res.ok) return;
      const data: any = await res.json();
      for (const m of data?.data ?? []) {
        if (typeof m.context_length === "number") {
          console.log(`[open-terminal-workspace] proxy context_length: ${m.id} = ${m.context_length}`);
        }
      }
    } catch {
      // proxy unreachable or doesn't expose context_length — expected with llama-swap
    }
  })();

  // ── Requirement 1: lock provider to llamacpp/* ────────────────────────
  pi.on("before_agent_start", async (event) => {
    const evAny = event as any;
    const model: string | undefined = evAny.model ?? evAny.modelId ?? evAny.model_id;
    if (typeof model === "string" && model.length > 0 && !model.startsWith("llamacpp/")) {
      throw new Error(
        `Model '${model}' is not permitted in this deployment. ` +
          `Only llamacpp/* models served by llama-ingress-proxy (qwen3.6:27b, qwen3.6:27b-nothink) ` +
          `are allowed. Re-run with --model llamacpp/qwen3.6:27b.`,
      );
    }
  });

  // ── Requirement 2: block built-in fs/shell tools with redirect ────────
  pi.on("tool_call", async (event) => {
    const name = (event as any).toolName;
    if (typeof name === "string" && BLOCKED_BUILTINS.has(name)) {
      return { block: true, reason: REDIRECT_MESSAGE };
    }
  });

  // ── Requirement 3: register OT* tools that proxy to open-terminal ─────

  pi.registerTool({
    name: "OTBash",
    label: "OTBash",
    description:
      "Execute a shell command inside the open-terminal container (the workspace). " +
      "Supports chaining (&&, ||, ;), pipes (|), redirections. Returns stdout, stderr, exit_code.",
    parameters: Type.Object({
      command: Type.String({ description: "Shell command to execute." }),
      cwd: Type.Optional(Type.String({ description: "Working directory (default: server cwd)." })),
      timeout: Type.Optional(
        Type.Integer({ description: "Seconds to wait for completion (default 30)." }),
      ),
    }),
    async execute(_id, { command, cwd, timeout }) {
      if (!command || typeof command !== "string") return errorResult("Error: command is required");
      const wait = typeof timeout === "number" && timeout > 0 ? timeout : 30;
      const body: Record<string, unknown> = { command };
      if (cwd) body.cwd = cwd;
      try {
        const res: any = await otFetch(`/execute?wait=${wait}`, {
          method: "POST",
          body: JSON.stringify(body),
        });
        const parts: string[] = [];
        if (res?.stdout) parts.push(`stdout:\n${res.stdout}`);
        if (res?.stderr) parts.push(`stderr:\n${res.stderr}`);
        parts.push(`exit_code: ${res?.exit_code ?? "?"}`);
        const out = parts.join("\n\n");
        return (res?.exit_code ?? 0) === 0 ? textResult(out) : errorResult(out);
      } catch (e: any) {
        return errorResult(`OTBash error: ${e?.message ?? e}`);
      }
    },
  });

  pi.registerTool({
    name: "OTRead",
    label: "OTRead",
    description: "Read a file from the open-terminal container.",
    parameters: Type.Object({
      path: Type.String({ description: "Path to the file inside the open-terminal container." }),
    }),
    async execute(_id, { path }) {
      if (!path) return errorResult("Error: path is required");
      try {
        const res = await otFetch(`/files/read?path=${encodeURIComponent(path)}`, { method: "GET" });
        const content =
          typeof res === "string"
            ? res
            : res?.content !== undefined
              ? String(res.content)
              : JSON.stringify(res, null, 2);
        return textResult(content);
      } catch (e: any) {
        return errorResult(`OTRead error: ${e?.message ?? e}`);
      }
    },
  });

  pi.registerTool({
    name: "OTWrite",
    label: "OTWrite",
    description:
      "Create or overwrite a file in the open-terminal container. Parent directories are created automatically.",
    parameters: Type.Object({
      path: Type.String({ description: "Path to write to." }),
      content: Type.String({ description: "Full text content of the file." }),
    }),
    async execute(_id, { path, content }) {
      if (!path) return errorResult("Error: path is required");
      const body = JSON.stringify({ path, content: content ?? "" });
      try {
        await otFetch("/files/write", { method: "POST", body });
        return textResult(`wrote ${path} (${(content ?? "").length} chars)`);
      } catch (e: any) {
        return errorResult(`OTWrite error: ${e?.message ?? e}`);
      }
    },
  });

  pi.registerTool({
    name: "OTEdit",
    label: "OTEdit",
    description:
      "Find-and-replace exact strings in a file inside open-terminal. 'target' must match precisely " +
      "(whitespace included). Pass allow_multiple=true to replace every occurrence; otherwise errors " +
      "when 'target' matches more than once.",
    parameters: Type.Object({
      path: Type.String(),
      target: Type.String({ description: "Exact string to find." }),
      replacement: Type.String({ description: "Replacement text." }),
      allow_multiple: Type.Optional(
        Type.Boolean({ description: "If true, replaces all occurrences." }),
      ),
    }),
    async execute(_id, { path, target, replacement, allow_multiple }) {
      if (!path || target === undefined || replacement === undefined) {
        return errorResult("Error: path, target, and replacement are all required");
      }
      const body = JSON.stringify({
        path,
        replacements: [{ target, replacement, allow_multiple: !!allow_multiple }],
      });
      try {
        await otFetch("/files/replace", { method: "POST", body });
        return textResult(`edited ${path}`);
      } catch (e: any) {
        return errorResult(`OTEdit error: ${e?.message ?? e}`);
      }
    },
  });

  pi.registerTool({
    name: "OTList",
    label: "OTList",
    description: "List directory contents in the open-terminal container.",
    parameters: Type.Object({
      path: Type.String({ description: "Directory path to list." }),
      recursive: Type.Optional(Type.Boolean({ description: "Recurse into subdirectories." })),
    }),
    async execute(_id, { path, recursive }) {
      if (!path) return errorResult("Error: path is required");
      const qs = `path=${encodeURIComponent(path)}&recursive=${recursive ? "true" : "false"}`;
      try {
        const res = await otFetch(`/files/list?${qs}`, { method: "GET" });
        return textResult(typeof res === "string" ? res : JSON.stringify(res, null, 2));
      } catch (e: any) {
        return errorResult(`OTList error: ${e?.message ?? e}`);
      }
    },
  });

  pi.registerTool({
    name: "OTGlob",
    label: "OTGlob",
    description: "Find files matching a glob pattern in the open-terminal container.",
    parameters: Type.Object({
      pattern: Type.String({ description: "Glob pattern, e.g. '**/*.py'." }),
    }),
    async execute(_id, { pattern }) {
      if (!pattern) return errorResult("Error: pattern is required");
      try {
        const res = await otFetch(`/files/glob?pattern=${encodeURIComponent(pattern)}`, {
          method: "GET",
        });
        return textResult(typeof res === "string" ? res : JSON.stringify(res, null, 2));
      } catch (e: any) {
        return errorResult(`OTGlob error: ${e?.message ?? e}`);
      }
    },
  });

  pi.registerTool({
    name: "OTGrep",
    label: "OTGrep",
    description: "Search file contents under a path for a regex pattern inside open-terminal.",
    parameters: Type.Object({
      pattern: Type.String({ description: "Regex pattern to search for." }),
      path: Type.String({ description: "Path (file or directory) to search within." }),
    }),
    async execute(_id, { pattern, path }) {
      if (!pattern || !path) return errorResult("Error: pattern and path are required");
      const qs = `pattern=${encodeURIComponent(pattern)}&path=${encodeURIComponent(path)}`;
      try {
        const res = await otFetch(`/files/grep?${qs}`, { method: "GET" });
        return textResult(typeof res === "string" ? res : JSON.stringify(res, null, 2));
      } catch (e: any) {
        return errorResult(`OTGrep error: ${e?.message ?? e}`);
      }
    },
  });
}
