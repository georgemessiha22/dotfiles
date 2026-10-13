import type { SidebarContext } from "../types.ts";
import { dim, fg, COLORS, panelHeader } from "../colors.ts";

/** Keep the tail of a path (filename matters most), prefixing with an ellipsis. */
function tail(p: string, max: number): string {
  if (max <= 1) return "…";
  return p.length <= max ? p : "…" + p.slice(p.length - (max - 1));
}

export function renderFilesPanel(ctx: SidebarContext, width: number): string[] {
  const files = ctx.editedFiles ?? [];
  if (files.length === 0) return [];
  const header = panelHeader(`Files edited (${files.length})`, width);
  const content = files.map((f) => {
    const mark = f.kind === "write" ? fg(COLORS.success, "+") : fg(COLORS.accent, "~");
    const count = f.edits > 1 ? dim(` ×${f.edits}`) : "";
    const countLen = f.edits > 1 ? 2 + String(f.edits).length : 0;
    return ` ${mark} ${tail(f.path, Math.max(1, width - 3 - countLen))}${count}`;
  });
  return [...header, ...content];
}
