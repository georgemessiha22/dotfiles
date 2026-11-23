import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export interface McpServerInfo {
  name: string;
  directCount: number;
  totalCount: number;
  tokenEstimate: number;
  connected: boolean;
  disabled: boolean;
}

/** One tool from pi.getAllTools() for a connected built-in MCP server. */
export interface LiveMcpTool {
  name: string;
  description?: string;
  parameters?: unknown;
  exposure?: string;
}

const MCP_CACHE_TTL_MS = 1500;
let mcpCache: { data: McpServerInfo[]; timestamp: number } | null = null;

function getAgentDir(): string {
  return process.env["PI_AGENT_DIR"] ?? join(homedir(), ".pi", "agent");
}

function readJson(path: string): unknown {
  try {
    return JSON.parse(readFileSync(path, "utf-8"));
  } catch {
    return null;
  }
}

/**
 * Tool-name prefix of a server's built-in pi tools. Pi names them
 * `mcp__<server>__<tool>` with every non-alphanumeric except `_` replaced by `_`.
 */
function mcpToolPrefix(server: string): string {
  return `mcp__${server.replace(/[^A-Za-z0-9_]/g, "_")}__`;
}

function estimateTokens(name: string, description: string | undefined, schema: unknown): number {
  const schemaLen = JSON.stringify(schema ?? {}).length;
  const descLen = description?.length ?? 0;
  return Math.ceil((name.length + descLen + schemaLen) / 4) + 10;
}

function computeMcpServers(liveTools: readonly LiveMcpTool[]): McpServerInfo[] {
  const agentDir = getAgentDir();
  const config = readJson(join(agentDir, "mcp.json")) as any;
  const cache = readJson(join(agentDir, "mcp-cache.json")) as any;

  const configuredServers: Record<string, any> = config?.mcpServers ?? {};
  const cachedServers: Record<string, any> = cache?.servers ?? {};
  const globalDirect = config?.settings?.directTools;

  const names = Object.keys(configuredServers).length > 0
    ? Object.keys(configuredServers)
    : Object.keys(cachedServers);

  if (names.length === 0) return [];

  return names.map((name) => {
    const definition = configuredServers[name] ?? {};

    // A disabled server is surfaced with no tool counts regardless of any tools.
    // Built-in pi uses `enabled: false`; the legacy adapter format used `disabled: true`.
    const disabled = definition.enabled === false || definition.disabled === true;
    if (disabled) {
      return { name, directCount: 0, totalCount: 0, tokenEstimate: 0, connected: false, disabled: true };
    }

    // Live built-in pi tools are authoritative when the server is connected:
    // pi registers mcp__<server>__<tool> for every tool of a connected server.
    const prefix = mcpToolPrefix(name);
    const live = liveTools.filter((t) => typeof t?.name === "string" && t.name.startsWith(prefix));

    if (live.length > 0) {
      let directCount = 0;
      let tokenEstimate = 0;
      for (const tool of live) {
        // Only `direct`-exposure tools are declared to the model and cost context.
        if (tool.exposure === "direct") {
          directCount++;
          tokenEstimate += estimateTokens(tool.name, tool.description, tool.parameters);
        }
      }
      return { name, directCount, totalCount: live.length, tokenEstimate, connected: true, disabled: false };
    }

    // Fallback: tools cached by an MCP adapter extension (legacy).
    const srv = cachedServers[name];
    const tools: any[] = srv?.tools ?? [];
    if (tools.length === 0) {
      return { name, directCount: 0, totalCount: 0, tokenEstimate: 0, connected: false, disabled: false };
    }

    // Determine directTools filter same way mcp-panel does
    let toolFilter: true | string[] | false = false;
    if (definition.directTools !== undefined) {
      toolFilter = definition.directTools;
    } else if (globalDirect) {
      toolFilter = globalDirect;
    }

    const excludeTools: string[] = definition.excludeTools ?? [];

    let directCount = 0;
    let tokenEstimate = 0;
    let totalCount = 0;

    for (const tool of tools) {
      // Simple exclude check
      if (excludeTools.includes(tool.name)) continue;
      totalCount++;

      const isDirect = toolFilter === true || (Array.isArray(toolFilter) && toolFilter.includes(tool.name));
      if (isDirect) {
        directCount++;
        tokenEstimate += estimateTokens(tool.name, tool.description, tool.inputSchema);
      }
    }

    return { name, directCount, totalCount, tokenEstimate, connected: true, disabled: false };
  });
}

export function getMcpServers(liveTools?: readonly LiveMcpTool[] | null): McpServerInfo[] {
  const now = Date.now();
  if (mcpCache && now - mcpCache.timestamp < MCP_CACHE_TTL_MS) return mcpCache.data;

  const data = computeMcpServers(liveTools ?? []);
  mcpCache = { data, timestamp: now };
  return data;
}

export function invalidateMcpCache(): void {
  mcpCache = null;
}
