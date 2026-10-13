import type { SidebarContext } from "../types.ts";
import { dim, fg, COLORS, panelHeader, trunc } from "../colors.ts";

export function renderLspPanel(ctx: SidebarContext, width: number): string[] {
  const servers = ctx.lspServers ?? [];
  if (servers.length === 0) return [];
  const header = panelHeader("LSP", width);
  const content = servers.map((s) => {
    const dot = s.available ? fg(COLORS.success, "●") : dim("○");
    const detail = s.detail ? dim(` ${s.detail}`) : "";
    return ` ${dot} ${trunc(s.name, Math.max(1, width - 3 - (s.detail ? s.detail.length + 1 : 0)))}${detail}`;
  });
  return [...header, ...content];
}
