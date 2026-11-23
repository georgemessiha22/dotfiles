import type { SidebarContext } from "../types.ts";
import { dim, fg, COLORS, panelHeader, trunc } from "../colors.ts";

const SPIN = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

function elapsed(ms: number): string {
  const s = Math.max(0, Math.floor(ms / 1000));
  return s < 60 ? `${s}s` : `${Math.floor(s / 60)}m${String(s % 60).padStart(2, "0")}s`;
}

export function renderSubagentsPanel(ctx: SidebarContext, width: number): string[] {
  const list = ctx.subagents ?? [];
  if (list.length === 0) return [];
  const running = list.filter((a) => a.status === "running").length;
  const header = panelHeader(`Subagents (${running} running)`, width);
  const now = Date.now();
  const content: string[] = [];
  for (const a of list) {
    const live = a.status === "running";
    const glyph = live ? fg(COLORS.accent, SPIN[(ctx.spinnerFrame ?? 0) % SPIN.length]) : fg(COLORS.success, "✓");
    const time = elapsed((a.endedAt ?? now) - a.startedAt);
    const right = dim(` ${time}`);
    const name = trunc(a.agent, Math.max(1, width - 4 - time.length));
    content.push(` ${glyph} ${live ? name : dim(name)}${right}`);
    if (live && a.goal) content.push(dim(`   ${trunc(a.goal, Math.max(1, width - 4))}`));
  }
  return [...header, ...content];
}
