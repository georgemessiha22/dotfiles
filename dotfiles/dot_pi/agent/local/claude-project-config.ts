/**
 * Load Claude Code project config into Pi.
 *
 * From the session cwd up to the git root, in trusted projects only:
 * - `.claude/skills` and `.claude/agents` become skills
 * - direct `.claude/commands/*.md` files become prompt templates
 * - `.claude/rules/*.md` are listed in the system prompt
 * - static SessionStart `echo '{"systemMessage":...}'` hooks are appended
 *
 * Hooks are never executed.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function findGitRoot(start: string): string {
	let dir = path.resolve(start);
	while (true) {
		if (fs.existsSync(path.join(dir, ".git"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) return path.resolve(start);
		dir = parent;
	}
}

function claudeDirs(cwd: string): string[] {
	const root = findGitRoot(cwd);
	const dirs: string[] = [];
	let dir = path.resolve(cwd);
	while (true) {
		const claude = path.join(dir, ".claude");
		if (fs.existsSync(claude) && fs.statSync(claude).isDirectory()) dirs.push(claude);
		if (dir === root) break;
		const parent = path.dirname(dir);
		if (parent === dir) break;
		dir = parent;
	}
	return dirs;
}

function findMarkdownFiles(dir: string, base = ""): string[] {
	if (!fs.existsSync(dir)) return [];
	const results: string[] = [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		if (entry.name.startsWith(".")) continue;
		const rel = base ? `${base}/${entry.name}` : entry.name;
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) results.push(...findMarkdownFiles(full, rel));
		else if (entry.isFile() && entry.name.endsWith(".md")) results.push(rel);
	}
	return results;
}

function commandFiles(commandsDir: string): string[] {
	if (!fs.existsSync(commandsDir)) return [];
	return fs
		.readdirSync(commandsDir, { withFileTypes: true })
		.filter((entry) => entry.isFile() && entry.name.endsWith(".md"))
		.map((entry) => path.join(commandsDir, entry.name));
}

function staticSessionMessages(settingsPath: string): string[] {
	if (!fs.existsSync(settingsPath)) return [];
	let parsed: unknown;
	try {
		parsed = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
	} catch {
		return [];
	}
	const hooks = (parsed as { hooks?: { SessionStart?: unknown } }).hooks?.SessionStart;
	if (!Array.isArray(hooks)) return [];
	const messages: string[] = [];
	for (const group of hooks) {
		const commands = (group as { hooks?: { type?: string; command?: string }[] }).hooks ?? [];
		for (const hook of commands) {
			if (hook.type !== "command" || typeof hook.command !== "string") continue;
			const match = hook.command.match(/echo\s+'(\{.*\})'/s);
			if (!match) continue;
			try {
				const body = JSON.parse(match[1]) as { systemMessage?: unknown };
				if (typeof body.systemMessage === "string" && body.systemMessage.trim()) {
					messages.push(body.systemMessage.trim());
				}
			} catch {
				// Not a static echo payload; do not execute the hook.
			}
		}
	}
	return messages;
}

function discover(cwd: string) {
	const dirs = claudeDirs(cwd);
	const skillPaths: string[] = [];
	const promptPaths: string[] = [];
	const rules: string[] = [];
	const messages: string[] = [];

	for (const dir of dirs) {
		for (const name of ["skills", "agents"]) {
			const candidate = path.join(dir, name);
			if (fs.existsSync(candidate)) skillPaths.push(candidate);
		}
		promptPaths.push(...commandFiles(path.join(dir, "commands")));
		const rulesDir = path.join(dir, "rules");
		for (const file of findMarkdownFiles(rulesDir)) {
			rules.push(path.join(rulesDir, file));
		}
		messages.push(...staticSessionMessages(path.join(dir, "settings.json")));
	}

	return { skillPaths, promptPaths, rules, messages };
}

export default function claudeProjectConfig(pi: ExtensionAPI) {
	pi.on("resources_discover", (event, ctx) => {
		if (!ctx.isProjectTrusted()) return;
		const found = discover(event.cwd);
		return { skillPaths: found.skillPaths, promptPaths: found.promptPaths };
	});

	pi.on("before_agent_start", (event, ctx) => {
		if (!ctx.isProjectTrusted()) return;
		const found = discover(ctx.cwd);
		if (found.rules.length === 0 && found.messages.length === 0) return;

		const sections: string[] = [];
		if (found.messages.length > 0) {
			sections.push(`## Claude project reminder\n\n${found.messages.join("\n\n")}`);
		}
		if (found.rules.length > 0) {
			const list = found.rules.map((file) => `- ${file}`).join("\n");
			sections.push(`## Claude project rules\n\nRead the relevant files before changing code in this repo:\n\n${list}`);
		}

		return { systemPrompt: `${event.systemPrompt}\n\n${sections.join("\n\n")}` };
	});
}
