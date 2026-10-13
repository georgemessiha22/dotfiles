import { readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { basename, isAbsolute, relative } from "node:path";
import type { EditedFile, LspInfo, SubagentInfo, ToolStat } from "./types.ts";

// ---- Tool usage ------------------------------------------------------------

const tools = new Map<string, ToolStat>();
const inflight = new Map<string, string>(); // toolCallId -> group name

/** Group `mcp__server__tool` under `mcp:server`; everything else by name. */
export function toolGroup(name: string): string {
  const m = /^mcp__([^_].*?)__/.exec(name);
  return m ? `mcp:${m[1]}` : name;
}

export function toolStart(callId: string, name: string): void {
  const group = toolGroup(name);
  inflight.set(callId, group);
  const s = tools.get(group) ?? { name: group, count: 0, errors: 0, running: 0, lastMs: 0 };
  s.count++;
  s.running++;
  s.lastMs = Date.now();
  tools.set(group, s);
}

export function toolEnd(callId: string, isError: boolean): void {
  const group = inflight.get(callId);
  if (!group) return;
  inflight.delete(callId);
  const s = tools.get(group);
  if (!s) return;
  s.running = Math.max(0, s.running - 1);
  if (isError) s.errors++;
  s.lastMs = Date.now();
}

export function getToolStats(): ToolStat[] {
  return [...tools.values()].sort((a, b) => b.running - a.running || b.lastMs - a.lastMs);
}

// ---- Subagents (pi-subagents in-process RPC) ---------------------------------

const agents = new Map<string, SubagentInfo>();
const DONE_KEEP = 5;
let rpcSeq = 0;

function toMs(v: unknown): number {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string") {
    const t = Date.parse(v);
    if (!Number.isNaN(t)) return t;
  }
  return Date.now();
}

function reconcile(entries: any[]): boolean {
  const now = Date.now();
  const seen = new Set<string>();
  let changed = false;
  for (const e of entries) {
    const key = String(e?.key ?? `${e?.agent}:${e?.startedAt}`);
    seen.add(key);
    const tokens = typeof e?.tokens?.total === "number" ? e.tokens.total : null;
    const prev = agents.get(key);
    if (!prev) {
      agents.set(key, {
        key,
        agent: String(e?.agent ?? "agent"),
        goal: typeof e?.goal === "string" ? e.goal : null,
        status: "running",
        startedAt: toMs(e?.startedAt),
        endedAt: null,
        tokens,
      });
      changed = true;
    } else if (prev.tokens !== tokens) {
      prev.tokens = tokens;
      changed = true;
    }
  }
  for (const a of agents.values()) {
    if (a.status === "running" && !seen.has(a.key)) {
      a.status = "done";
      a.endedAt = now;
      changed = true;
    }
  }
  const done = [...agents.values()].filter((a) => a.status === "done").sort((x, y) => (y.endedAt ?? 0) - (x.endedAt ?? 0));
  for (const old of done.slice(DONE_KEEP)) agents.delete(old.key);
  return changed;
}

/** Ask pi-subagents for the active fleet; resolves true if the list changed. */
export function pollSubagents(events: any): Promise<boolean> {
  return new Promise((resolve) => {
    if (!events?.on || !events?.emit) return resolve(false);
    const requestId = `sidebar-${Date.now()}-${rpcSeq++}`;
    let off: (() => void) | null = null;
    const timer = setTimeout(() => { off?.(); resolve(false); }, 1500);
    off = events.on(`subagents:rpc:v1:reply:${requestId}`, (reply: any) => {
      clearTimeout(timer);
      off?.();
      const fleet = reply?.data?.fleet ?? reply?.data?.details?.fleet;
      resolve(reply?.success && Array.isArray(fleet?.entries) ? reconcile(fleet.entries) : false);
    });
    events.emit("subagents:rpc:v1:request", { version: 1, requestId, method: "status", params: {} });
  });
}

export function getSubagents(): SubagentInfo[] {
  return [...agents.values()].sort(
    (a, b) => (a.status === b.status ? b.startedAt - a.startedAt : a.status === "running" ? -1 : 1),
  );
}

export function hasRunningSubagents(): boolean {
  for (const a of agents.values()) if (a.status === "running") return true;
  return false;
}

export function resetActivity(): void {
  edited.clear();
  tools.clear();
  inflight.clear();
  agents.clear();
}

// ---- Edited files ----------------------------------------------------------

const edited = new Map<string, EditedFile>();
const EDIT_TOOLS = new Set(["edit", "write", "multiedit", "apply_patch"]);

export function recordEdit(toolName: string, input: any, isError: boolean, cwd: string | undefined): boolean {
  const name = toolName.toLowerCase();
  if (isError || !EDIT_TOOLS.has(name)) return false;
  const raw = input?.path ?? input?.file_path ?? input?.filePath;
  if (typeof raw !== "string" || !raw) return false;
  const base = cwd ?? process.cwd();
  let p = isAbsolute(raw) ? relative(base, raw) : raw;
  if (p.startsWith("..")) p = raw; // outside the workspace: keep absolute
  const prev = edited.get(p);
  if (prev) {
    prev.edits++;
    prev.lastMs = Date.now();
    if (name === "write") prev.kind = "write";
  } else {
    edited.set(p, { path: p, edits: 1, kind: name === "write" ? "write" : "edit", lastMs: Date.now() });
  }
  return true;
}

export function getEditedFiles(): EditedFile[] {
  return [...edited.values()].sort((a, b) => b.lastMs - a.lastMs);
}

// ---- LSP -------------------------------------------------------------------
// Language servers started by pi-lsp-adapter register themselves in
// ~/.pi/agent/lsp/pids/<owner>.json. Show the ones owned by this pi process.

function alive(pid: number): boolean {
  try { process.kill(pid, 0); return true; } catch { return false; }
}

export function getLspServers(): LspInfo[] {
  const dir = join(homedir(), ".pi", "agent", "lsp", "pids");
  const out: LspInfo[] = [];
  let files: string[] = [];
  try { files = readdirSync(dir).filter((f) => f.endsWith(".json")); } catch { return out; }
  for (const f of files) {
    try {
      const procs = JSON.parse(readFileSync(join(dir, f), "utf8"))?.processes ?? [];
      for (const p of procs) {
        if (p?.ownerPid !== process.pid || !alive(p.pid)) continue;
        out.push({ name: String(p.serverId), detail: basename(String(p.rootDir ?? "")), available: true });
      }
    } catch { /* ignore partial writes */ }
  }
  return out.sort((x, y) => x.name.localeCompare(y.name));
}
