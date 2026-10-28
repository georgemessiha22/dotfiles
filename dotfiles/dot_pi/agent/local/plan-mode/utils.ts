/**
 * Pure utility functions for plan mode.
 * Extracted for testability.
 */

// Destructive commands blocked in plan mode
const DESTRUCTIVE_PATTERNS = [
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bchgrp\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/\bdd\b/i,
	/\bshred\b/i,
	/(^|[^<])>(?!>)/,
	/>>/,
	/\bnpm\s+(install|uninstall|update|ci|link|publish)/i,
	/\byarn\s+(add|remove|install|publish)/i,
	/\bpnpm\s+(add|remove|install|publish)/i,
	/\bpip\s+(install|uninstall)/i,
	/\bapt(-get)?\s+(install|remove|purge|update|upgrade)/i,
	/\bbrew\s+(install|uninstall|upgrade)/i,
	/\bgit(?:\s+(?:-C(?:\s+(?:"[^"]+"|'[^']+'|\S+)|=\S+)|--no-pager|--paginate|-c(?:\s+\S+|=\S+)|--git-dir(?:\s+\S+|=\S+)|--work-tree(?:\s+\S+|=\S+)))*\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert|tag|init|clone)\b/i,
	/\bsudo\b/i,
	/\bsu\b/i,
	/\bkill\b/i,
	/\bpkill\b/i,
	/\bkillall\b/i,
	/\breboot\b/i,
	/\bshutdown\b/i,
	/\bsystemctl\s+(start|stop|restart|enable|disable)/i,
	/\bservice\s+\S+\s+(start|stop|restart)/i,
	/^\s*(?:[A-Za-z_][A-Za-z0-9_]*=(?:'[^']*'|"[^"]*"|\S+)\s+)*(?:vim?|nano|emacs|code|subl)\b/i,
];

// Safe read-only commands allowed in plan mode
const SAFE_PATTERNS = [
	/^\s*cat\b/,
	/^\s*head\b/,
	/^\s*tail\b/,
	/^\s*less\b/,
	/^\s*more\b/,
	/^\s*grep\b/,
	/^\s*find\b/,
	/^\s*ls\b/,
	/^\s*pwd\b/,
	/^\s*echo\b/,
	/^\s*printf\b/,
	/^\s*wc\b/,
	/^\s*sort\b/,
	/^\s*uniq\b/,
	/^\s*diff\b/,
	/^\s*file\b/,
	/^\s*stat\b/,
	/^\s*du\b/,
	/^\s*df\b/,
	/^\s*tree\b/,
	/^\s*which\b/,
	/^\s*whereis\b/,
	/^\s*type\b/,
	/^\s*env\b/,
	/^\s*printenv\b/,
	/^\s*uname\b/,
	/^\s*whoami\b/,
	/^\s*id\b/,
	/^\s*date\b/,
	/^\s*cal\b/,
	/^\s*uptime\b/,
	/^\s*ps\b/,
	/^\s*top\b/,
	/^\s*htop\b/,
	/^\s*free\b/,
	/^\s*git(?:\s+(?:-C(?:\s+(?:"[^"]+"|'[^']+'|\S+)|=\S+)|--no-pager|--paginate|-c(?:\s+\S+|=\S+)|--git-dir(?:\s+\S+|=\S+)|--work-tree(?:\s+\S+|=\S+)))*\s+(status|log|diff|show|branch|remote|config\s+--get)\b/i,
	/^\s*git(?:\s+(?:-C(?:\s+(?:"[^"]+"|'[^']+'|\S+)|=\S+)|--no-pager|--paginate|-c(?:\s+\S+|=\S+)|--git-dir(?:\s+\S+|=\S+)|--work-tree(?:\s+\S+|=\S+)))*\s+ls-/i,
	/^\s*gh(?:\s+(?:(?:-R|--repo)(?:\s+(?:"[^"]+"|'[^']+'|\S+)|=\S+)|--hostname(?:\s+\S+|=\S+)))*\s+(?:pr\s+(?:view|list|status|diff|checks)|issue\s+(?:view|list)|repo\s+view|run\s+(?:view|list)|search\b|status\b|api\b)/i,
	/^\s*npm\s+(list|ls|view|info|search|outdated|audit)/i,
	/^\s*yarn\s+(list|info|why|audit)/i,
	/^\s*node\s+--version/i,
	/^\s*python\s+--version/i,
	/^\s*curl\s/i,
	/^\s*wget\s+-O\s*-/i,
	/^\s*jq\b/,
	/^\s*sed\s+-n/i,
	/^\s*awk\b/,
	/^\s*rg\b/,
	/^\s*fd\b/,
	/^\s*bat\b/,
	/^\s*eza\b/,
];

const ENV_PREFIX = /^(?:[A-Za-z_][A-Za-z0-9_]*=(?:'[^']*'|"[^"]*"|\S+)\s+)+/;

function stripQuotes(input: string): string {
	let out = "";
	let quote: "'" | '"' | null = null;
	for (let i = 0; i < input.length; i++) {
		const ch = input[i];
		if (quote) {
			if (ch === "\\" && quote === '"') {
				i++;
				continue;
			}
			if (ch === quote) quote = null;
			continue;
		}
		if (ch === "'" || ch === '"') {
			quote = ch;
			continue;
		}
		out += ch;
	}
	return out;
}

function stripBenignRedirects(input: string): string {
	return input
		.replace(/\d*>&?\d+/g, " ")
		.replace(/\d*>>?\/dev\/null\b/g, " ")
		.replace(/&>>?\/dev\/null\b/g, " ");
}

function splitCommandSegments(command: string): string[] {
	const parts: string[] = [];
	let current = "";
	let quote: "'" | '"' | null = null;
	for (let i = 0; i < command.length; i++) {
		const ch = command[i];
		if (quote) {
			current += ch;
			if (ch === "\\" && quote === '"' && i + 1 < command.length) {
				current += command[++i];
				continue;
			}
			if (ch === quote) quote = null;
			continue;
		}
		if (ch === "'" || ch === '"') {
			quote = ch;
			current += ch;
			continue;
		}
		if (ch === "\n" || ch === ";") {
			parts.push(current);
			current = "";
			continue;
		}
		if ((ch === "|" && command[i + 1] === "|") || (ch === "&" && command[i + 1] === "&")) {
			parts.push(current);
			current = "";
			i++;
			continue;
		}
		if (ch === "|") {
			parts.push(current);
			current = "";
			continue;
		}
		current += ch;
	}
	parts.push(current);
	return parts.map((part) => part.trim()).filter((part) => part.length > 0);
}

function isMutatingGhApi(segment: string): boolean {
	const unquoted = stripQuotes(segment);
	if (!/\bgh\b(?:\s+(?:(?:-R|--repo)(?:\s+\S+|=\S+)|--hostname(?:\s+\S+|=\S+)))*\s+api\b/i.test(unquoted)) {
		return false;
	}
	if (/\bgraphql\b/i.test(unquoted)) return true;
	if (/(?:^|\s)(?:-f|-F|--raw-field|--field|--input)(?:\s|=|$)/.test(unquoted)) return true;
	const method = unquoted.match(/(?:--method(?:=|\s+)|-X\s*)([A-Za-z]+)/i);
	return method !== null && method[1].toUpperCase() !== "GET";
}

function segmentIsSafe(segment: string): boolean {
	const sanitized = stripBenignRedirects(stripQuotes(segment));
	if (DESTRUCTIVE_PATTERNS.some((pattern) => pattern.test(sanitized))) return false;
	if (isMutatingGhApi(segment)) return false;
	const command = segment.replace(ENV_PREFIX, "");
	return SAFE_PATTERNS.some((pattern) => pattern.test(command));
}

export function isSafeCommand(command: string): boolean {
	const segments = splitCommandSegments(command);
	return segments.length > 0 && segments.every(segmentIsSafe);
}

export interface TodoItem {
	step: number;
	text: string;
	completed: boolean;
}

export function cleanStepText(text: string): string {
	let cleaned = text
		.replace(/\*{1,2}([^*]+)\*{1,2}/g, "$1") // Remove bold/italic
		.replace(/`([^`]+)`/g, "$1") // Remove code
		.replace(
			/^(Use|Run|Execute|Create|Write|Read|Check|Verify|Update|Modify|Add|Remove|Delete|Install)\s+(the\s+)?/i,
			"",
		)
		.replace(/\s+/g, " ")
		.trim();

	if (cleaned.length > 0) {
		cleaned = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
	}
	if (cleaned.length > 50) {
		cleaned = `${cleaned.slice(0, 47)}...`;
	}
	return cleaned;
}

export function extractTodoItems(message: string): TodoItem[] {
	const items: TodoItem[] = [];
	const headerMatch = message.match(/\*{0,2}Plan:\*{0,2}\s*\n/i);
	if (!headerMatch) return items;

	const planSection = message.slice(message.indexOf(headerMatch[0]) + headerMatch[0].length);
	const numberedPattern = /^\s*(\d+)[.)]\s+\*{0,2}([^*\n]+)/gm;

	for (const match of planSection.matchAll(numberedPattern)) {
		const text = match[2]
			.trim()
			.replace(/\*{1,2}$/, "")
			.trim();
		if (text.length > 5 && !text.startsWith("`") && !text.startsWith("/") && !text.startsWith("-")) {
			const cleaned = cleanStepText(text);
			if (cleaned.length > 3) {
				items.push({ step: items.length + 1, text: cleaned, completed: false });
			}
		}
	}
	return items;
}

export function extractDoneSteps(message: string): number[] {
	const steps: number[] = [];
	for (const match of message.matchAll(/\[DONE:(\d+)\]/gi)) {
		const step = Number(match[1]);
		if (Number.isFinite(step)) steps.push(step);
	}
	return steps;
}

export function markCompletedSteps(text: string, items: TodoItem[]): number {
	const doneSteps = extractDoneSteps(text);
	for (const step of doneSteps) {
		const item = items.find((t) => t.step === step);
		if (item) item.completed = true;
	}
	return doneSteps.length;
}

const EXIT_PLAN_MODE_LINE = /^(?:execute|go)$/i;

/** True when a line, after trim, is exactly `execute` or `go`. */
export function messageExitsPlanMode(text: string): boolean {
	if (!text) return false;
	return text.split(/\r?\n/).some((line) => EXIT_PLAN_MODE_LINE.test(line.trim()));
}
