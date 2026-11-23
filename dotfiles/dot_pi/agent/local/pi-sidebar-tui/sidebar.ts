import { truncateToWidth } from "@earendil-works/pi-tui";
import type { SidebarContext } from "./types.ts";
import { dim } from "./colors.ts";
import { renderSessionPanel } from "./panels/session.ts";
import { renderMcpPanel } from "./panels/mcp.ts";
import { renderTodosPanel } from "./panels/todos.ts";
import { renderWorkspacePanel } from "./panels/workspace.ts";
import { renderToolsPanel } from "./panels/tools.ts";
import { renderSubagentsPanel } from "./panels/subagents.ts";
import { renderLspPanel } from "./panels/lsp.ts";
import { renderFilesPanel } from "./panels/files.ts";

// The scrollable panels (mcp, todos, workspace) share the rows left after the
// pinned session panel. The water-filler divides that room so the sidebar fills
// the space down to the cwd row (no dead gap); each panel only scrolls when its
// content exceeds the window it was allocated.

// Every panel renders a 2-row header (panelHeader / renderWorkspaceHeader).
const HEADER_ROWS = 2;

/**
 * Water-fill `available` rows across panels with the given `needs`, giving each
 * panel at most its need. The shares sum to min(available, sum(needs)); when
 * there is more than enough room each panel simply gets its full need.
 */
export function distributeRows(available: number, needs: number[]): number[] {
  const n = needs.length;
  const cap = needs.map((v) => (typeof v === "number" && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0));
  const shares = new Array(n).fill(0);
  let rem = typeof available === "number" && Number.isFinite(available) ? Math.max(0, Math.floor(available)) : 0;

  let guard = 0;
  while (rem > 0 && guard++ < 10000) {
    const activeIdx: number[] = [];
    for (let i = 0; i < n; i++) if (shares[i] < cap[i]) activeIdx.push(i);
    if (activeIdx.length === 0) break;
    const per = Math.floor(rem / activeIdx.length);
    let progress = false;
    if (per > 0) {
      for (const i of activeIdx) {
        const give = Math.min(per, cap[i] - shares[i]);
        if (give > 0) { shares[i] += give; rem -= give; progress = true; }
      }
    }
    if (!progress) {
      // per === 0 but rem > 0: hand the remainder out one row at a time.
      for (const i of activeIdx) {
        if (rem === 0) break;
        if (shares[i] < cap[i]) { shares[i]++; rem--; }
      }
    }
    if (!progress && rem > 0) break; // no panel could take more
  }
  return shares;
}

/** Row range of one panel in the returned line list (0-based, [start,end)). */
export interface PanelSlot {
  id: string;
  startRow: number;
  endRow: number;
  scrollable: boolean;
  /** Max valid scroll offset for this panel (0 when content fits its window). */
  maxOffset: number;
}

export interface SidebarRender {
  lines: string[];
  layout: PanelSlot[];
}

interface PanelSpec {
  id: string;
  render: (ctx: SidebarContext, width: number) => string[];
  scrollable: boolean;
  /**
   * Optional content-row cap for a scrollable panel. When set (todos, via
   * `todosMax`) the window never exceeds it; when unset (mcp, workspace) the
   * panel may grow to fill the remaining rows so there's no dead gap.
   */
  viewport?: number;
}

function todosViewport(ctx: SidebarContext): number {
  const v = ctx.todosMax;
  return typeof v === "number" && Number.isFinite(v) && v > 0 ? v : 10;
}

function panelSpecs(ctx: SidebarContext): PanelSpec[] {
  return [
    { id: "session", render: renderSessionPanel, scrollable: false },
    { id: "todos", render: renderTodosPanel, scrollable: true, viewport: todosViewport(ctx) },
    { id: "subagents", render: renderSubagentsPanel, scrollable: true, viewport: 8 },
    { id: "tools", render: renderToolsPanel, scrollable: true, viewport: 10 },
    { id: "lsp", render: renderLspPanel, scrollable: true, viewport: 4 },
    { id: "files", render: renderFilesPanel, scrollable: true, viewport: 10 },
    { id: "mcp", render: renderMcpPanel, scrollable: true },
    { id: "workspace", render: renderWorkspacePanel, scrollable: true },
  ];
}

/** Render one scrollable panel's content window (with ▲/▼ indicators). */
function renderViewport(
  content: string[],
  viewport: number,
  offset: number,
  lines: string[],
  safeWidth: number,
): number {
  const total = content.length;
  const vp = Math.max(0, Math.floor(viewport));
  const trunc = (s: string) => truncateToWidth(s, safeWidth, "", true);

  if (total === 0) return 0;

  if (vp <= 0) {
    // No room for content (very short terminal): header only, keeps the fit
    // guarantee strict so the whole sidebar never overflows the rows.
    return 0;
  }

  if (total <= vp) {
    for (const c of content) lines.push(trunc(c));
    return 0; // fits: no scroll
  }

  if (vp === 1) {
    // Only one row available: a single indicator, never content. Keeps the
    // output exactly `vp` rows so the water-fill fit guarantee holds.
    const clamped = Math.max(0, Math.min(total - 1, Math.floor(offset)));
    lines.push(clamped === 0
      ? dim(` ▼ ${total} line${total === 1 ? "" : "s"} below`)
      : dim(` ▲ ${clamped} line${clamped === 1 ? "" : "s"} above`));
    return total - 1;
  }

  // vp >= 2: the window holds (vp - 1) content rows plus an indicator, so
  // every state (top / middle / bottom) renders exactly `vp` rows.
  const contentRows = vp - 1;
  const maxOffset = total - contentRows;
  const clamped = Math.max(0, Math.min(maxOffset, Math.floor(offset)));
  const isAtTop = clamped === 0;
  const isAtBottom = clamped >= maxOffset;

  if (isAtTop) {
    for (let i = 0; i < contentRows; i++) lines.push(trunc(content[i] ?? ""));
    const below = Math.max(1, total - contentRows);
    lines.push(dim(` ▼ ${below} line${below === 1 ? "" : "s"} below`));
  } else if (isAtBottom) {
    lines.push(dim(` ▲ ${clamped} line${clamped === 1 ? "" : "s"} above`));
    for (let i = 0; i < contentRows; i++) lines.push(trunc(content[clamped + i] ?? ""));
  } else {
    lines.push(dim(` ▲ ${clamped} line${clamped === 1 ? "" : "s"} above`));
    const midRows = vp - 2;
    for (let i = 0; i < midRows; i++) lines.push(trunc(content[clamped + i] ?? ""));
    const below = Math.max(1, total - (clamped + midRows));
    lines.push(dim(` ▼ ${below} line${below === 1 ? "" : "s"} below`));
  }
  return maxOffset;
}

/**
 * Render the sidebar as a line list plus a per-panel layout map.
 *
 * `visibleRows` is the height available for panels (the compositor passes the
 * terminal rows minus the pinned cwd row). The water-filler divides the room
 * among the scrollable panels so the whole sidebar always fits; each panel's
 * content beyond its window scrolls with ▲/▼ indicators. `panelOffsets` holds
 * the current scroll offset per scrollable panel id.
 */
export function renderSidebar(
  ctx: SidebarContext,
  width: number,
  visibleRows: number = 100000,
  panelOffsets: Record<string, number> = {},
): SidebarRender {
  const safeWidth = Math.max(1, width);
  const specs = panelSpecs(ctx);

  const rendered: { spec: PanelSpec; header: string[]; content: string[] }[] = [];
  for (const spec of specs) {
    const full = spec.render(ctx, safeWidth);
    if (full.length === 0) continue; // empty panel (e.g. MCP with no servers)
    rendered.push({
      spec,
      header: full.slice(0, HEADER_ROWS),
      content: full.slice(HEADER_ROWS),
    });
  }

  if (rendered.length === 0) return { lines: [], layout: [] };

  const scrollable = rendered.filter((r) => r.spec.scrollable);
  const pinnedRows = rendered
    .filter((r) => !r.spec.scrollable)
    .reduce((sum, r) => sum + r.header.length + r.content.length, 0);
  const separators = rendered.length - 1;
  const scrollHeaders = scrollable.length * HEADER_ROWS;

  const needs = scrollable.map((r) =>
    typeof r.spec.viewport === "number" && Number.isFinite(r.spec.viewport) && r.spec.viewport > 0
      ? Math.min(r.content.length, r.spec.viewport)
      : r.content.length,
  );
  const hasBudget = typeof visibleRows === "number" && Number.isFinite(visibleRows) && visibleRows > 0;
  const availForContent = hasBudget ? Math.max(0, visibleRows - pinnedRows - separators - scrollHeaders) : Infinity;
  const shares = hasBudget ? distributeRows(availForContent, needs) : needs.slice();
  const shareById = new Map<string, number>();
  scrollable.forEach((r, i) => shareById.set(r.spec.id, shares[i]));

  const lines: string[] = [];
  const layout: PanelSlot[] = [];

  for (let p = 0; p < rendered.length; p++) {
    const { spec, header, content } = rendered[p];
    if (p > 0) lines.push(""); // blank separator between panels

    const startRow = lines.length;
    for (const h of header) lines.push(truncateToWidth(h, safeWidth, "", true));

    if (!spec.scrollable) {
      for (const c of content) lines.push(truncateToWidth(c, safeWidth, "", true));
      layout.push({ id: spec.id, startRow, endRow: lines.length, scrollable: false, maxOffset: 0 });
    } else {
      const maxOffset = renderViewport(
        content,
        shareById.get(spec.id) ?? 0,
        panelOffsets[spec.id] ?? 0,
        lines,
        safeWidth,
      );
      layout.push({ id: spec.id, startRow, endRow: lines.length, scrollable: true, maxOffset });
    }
  }

  return { lines, layout };
}
