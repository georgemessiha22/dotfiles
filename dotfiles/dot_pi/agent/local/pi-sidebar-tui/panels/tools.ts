import type { SidebarContext } from "../types.ts";
import { dim, fg, COLORS, panelHeader, trunc } from "../colors.ts";

const SPIN = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

export function renderToolsPanel(ctx: SidebarContext, width: number): string[] {
  const stats = ctx.toolStats ?? [];
  if (stats.length === 0) return [];
  const total = stats.reduce((n, s) => n + s.count, 0);
  const header = panelHeader(`Tools (${total})`, width);
  const content = stats.map((s) => {
    const glyph = s.running > 0
      ? fg(COLORS.accent, SPIN[(ctx.spinnerFrame ?? 0) % SPIN.length])
      : s.errors > 0 ? fg(COLORS.warning, "!") : fg(COLORS.success, "✓");
    const right = dim(` ${s.count}`) + (s.errors > 0 ? fg(COLORS.error, ` ✗${s.errors}`) : "");
    const rightLen = 1 + String(s.count).length + (s.errors > 0 ? 2 + String(s.errors).length : 0);
    return ` ${glyph} ${trunc(s.name, Math.max(1, width - 3 - rightLen))}${right}`;
  });
  return [...header, ...content];
}
