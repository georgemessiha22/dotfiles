/**
 * Plan Mode Extension
 *
 * Read-only exploration mode for safe code analysis.
 * When enabled, built-in write tools are disabled.
 *
 * Features:
 * - /plan command or Ctrl+Alt+P to toggle
 * - Bash restricted to allowlisted read-only commands
 * - Extracts numbered plan steps from "Plan:" sections
 * - [DONE:n] markers to complete steps during execution
 * - Progress tracking widget during execution
 */

import { spawn } from "node:child_process";
import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { AssistantMessage, TextContent } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import { extractTodoItems, isSafeCommand, markCompletedSteps, messageExitsPlanMode, type TodoItem } from "./utils.ts";

// Tools
const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls", "questionnaire", "herdr"];
const NORMAL_MODE_TOOLS = ["read", "bash", "edit", "write"];
const PLAN_MODE_DISABLED_TOOLS = new Set<string>(["edit", "write"]);
const PLAN_MANAGED_TOOLS = new Set<string>([...PLAN_MODE_TOOLS, ...NORMAL_MODE_TOOLS]);

interface PlanModeState {
	enabled: boolean;
	todos?: TodoItem[];
	executing?: boolean;
	toolsBeforePlanMode?: string[];
}

// Type guard for assistant messages
function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray(m.content);
}

// Extract text content from an assistant message
function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

export default function planModeExtension(pi: ExtensionAPI): void {
	let planModeEnabled = true;
	let executionMode = false;
	let todoItems: TodoItem[] = [];
	let toolsBeforePlanMode: string[] | undefined;

	pi.registerFlag("plan", {
		description: "Start in plan mode (read-only exploration). On by default; /plan toggles it off.",
		type: "boolean",
		default: true,
	});

	pi.registerFlag("no-plan", {
		description: "Start with plan mode off so an automated session can write files.",
		type: "boolean",
		default: false,
	});

	let planModeSegmentRegistered = false;

	function updateStatus(ctx: ExtensionContext): void {
		const completed = todoItems.filter((t) => t.completed).length;
		const modeLabel = planModeEnabled
			? "plan"
			: executionMode && todoItems.length > 0
				? `agent ${completed}/${todoItems.length}`
				: "agent";
		const modeColor = planModeEnabled ? "warning" : "success";

		// Built-in footer (hidden while powerbar replaces it) and the powerbar segment.
		ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg(modeColor, modeLabel));
		if (!planModeSegmentRegistered) {
			pi.events.emit("powerbar:register-segment", { id: "plan-mode", label: "Mode" });
			planModeSegmentRegistered = true;
		}
		pi.events.emit("powerbar:update", {
			id: "plan-mode",
			text: modeLabel,
			color: modeColor,
		});

		// Widget showing todo list
		if (executionMode && todoItems.length > 0) {
			const lines = todoItems.map((item) => {
				if (item.completed) {
					return (
						ctx.ui.theme.fg("success", "☑ ") + ctx.ui.theme.fg("muted", ctx.ui.theme.strikethrough(item.text))
					);
				}
				return `${ctx.ui.theme.fg("muted", "☐ ")}${item.text}`;
			});
			ctx.ui.setWidget("plan-todos", lines);
		} else {
			ctx.ui.setWidget("plan-todos", undefined);
		}
	}

	function uniqueToolNames(toolNames: string[]): string[] {
		return [...new Set(toolNames)];
	}

	function getPlanModeTools(activeToolNames: string[]): string[] {
		return uniqueToolNames([
			...activeToolNames.filter((name) => !PLAN_MODE_DISABLED_TOOLS.has(name)),
			...PLAN_MODE_TOOLS,
		]);
	}

	function getNormalModeTools(activeToolNames: string[]): string[] {
		return uniqueToolNames([
			...NORMAL_MODE_TOOLS,
			...activeToolNames.filter((name) => !PLAN_MANAGED_TOOLS.has(name)),
		]);
	}

	function enablePlanModeTools(): void {
		if (toolsBeforePlanMode === undefined) {
			toolsBeforePlanMode = pi.getActiveTools();
		}
		pi.setActiveTools(getPlanModeTools(toolsBeforePlanMode));
	}

	function restoreNormalModeTools(): void {
		pi.setActiveTools(toolsBeforePlanMode ?? getNormalModeTools(pi.getActiveTools()));
		toolsBeforePlanMode = undefined;
	}

	function persistState(): void {
		pi.appendEntry("plan-mode", {
			enabled: planModeEnabled,
			todos: todoItems,
			executing: executionMode,
			toolsBeforePlanMode,
		});
	}

	function exitPlanModeFromUser(ctx: ExtensionContext): void {
		if (!planModeEnabled) return;
		planModeEnabled = false;
		executionMode = todoItems.length > 0;
		restoreNormalModeTools();
		ctx.ui.notify(
			executionMode ? "Plan mode exited. Executing the plan." : "Plan mode exited. Full access restored.",
			"info",
		);
		updateStatus(ctx);
		persistState();
	}

	let herdrSeq = Date.now();
	let planModeBlockReported = false;

	function nextHerdrSeq(): string {
		const now = Date.now();
		herdrSeq = Math.max(herdrSeq + 1, now);
		return String(herdrSeq);
	}

	function herdrEnv(): { bin: string; paneId: string } | undefined {
		if (process.env.HERDR_ENV !== "1") return undefined;
		const bin = process.env.HERDR_BIN_PATH;
		const paneId = process.env.HERDR_PANE_ID;
		if (!bin || !paneId) return undefined;
		return { bin, paneId };
	}

	function spawnDetached(command: string, args: string[]): void {
		try {
			const child = spawn(command, args, { stdio: "ignore", detached: true, windowsHide: true });
			child.unref();
			const timer = setTimeout(() => {
				child.kill();
			}, 2000);
			timer.unref();
			child.once("exit", () => clearTimeout(timer));
		} catch {
			// A missing notifier must not delay the dialog.
		}
	}

	function notifyTerminal(title: string, body: string): void {
		if (process.env.WT_SESSION) {
			const script = [
				"[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null",
				"$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01)",
				`$xml.GetElementsByTagName('text')[0].AppendChild($xml.CreateTextNode('${body.replace(/'/g, "''")}')) > $null`,
				`[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('${title.replace(/'/g, "''")}').Show([Windows.UI.Notifications.ToastNotification]::new($xml))`,
			].join("; ");
			spawnDetached("powershell.exe", ["-NoProfile", "-Command", script]);
			return;
		}
		if (process.env.KITTY_WINDOW_ID) {
			process.stdout.write(`\x1b]99;i=plan-mode:d=0;${title}\x1b\\`);
			process.stdout.write(`\x1b]99;i=plan-mode:p=body;${body}\x1b\\`);
			return;
		}
		process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
	}

	function signalInputRequired(message: string): void {
		const herdr = herdrEnv();
		if (herdr) {
			spawnDetached(herdr.bin, [
				"notification",
				"show",
				"Plan mode",
				"--body",
				"User input required",
				"--sound",
				"request",
			]);
			spawnDetached(herdr.bin, [
				"pane",
				"report-agent",
				herdr.paneId,
				"--source",
				"pi-plan-mode",
				"--agent",
				"pi",
				"--state",
				"blocked",
				"--message",
				message,
				"--seq",
				nextHerdrSeq(),
			]);
			planModeBlockReported = true;
			return;
		}
		notifyTerminal("Plan mode", "User input required");
	}

	function clearInputRequired(): void {
		if (!planModeBlockReported) return;
		planModeBlockReported = false;
		const herdr = herdrEnv();
		if (!herdr) return;
		spawnDetached(herdr.bin, [
			"pane",
			"report-agent",
			herdr.paneId,
			"--source",
			"pi-plan-mode",
			"--agent",
			"pi",
			"--state",
			"idle",
			"--seq",
			nextHerdrSeq(),
		]);
	}

	async function waitForPlanInput<T>(message: string, run: () => Promise<T>): Promise<T> {
		signalInputRequired(message);
		try {
			return await run();
		} finally {
			clearInputRequired();
		}
	}

	function togglePlanMode(ctx: ExtensionContext): void {
		planModeEnabled = !planModeEnabled;
		executionMode = false;
		todoItems = [];

		if (planModeEnabled) {
			enablePlanModeTools();
			ctx.ui.notify("Plan mode enabled. Built-in write tools disabled.");
		} else {
			restoreNormalModeTools();
			ctx.ui.notify("Plan mode disabled. Full access restored.");
		}
		updateStatus(ctx);
		persistState();
	}

	pi.registerCommand("plan", {
		description: "Toggle plan mode (read-only exploration)",
		handler: async (_args, ctx) => togglePlanMode(ctx),
	});

	pi.registerCommand("todos", {
		description: "Show current plan todo list",
		handler: async (_args, ctx) => {
			if (todoItems.length === 0) {
				ctx.ui.notify("No todos. Create a plan first with /plan", "info");
				return;
			}
			const list = todoItems.map((item, i) => `${i + 1}. ${item.completed ? "✓" : "○"} ${item.text}`).join("\n");
			ctx.ui.notify(`Plan Progress:\n${list}`, "info");
		},
	});

	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle plan mode",
		handler: async (ctx) => togglePlanMode(ctx),
	});

	pi.registerShortcut("shift+tab", {
		description: "Toggle plan mode",
		handler: async (ctx) => togglePlanMode(ctx),
	});

	// A reply line that is only `execute` or `go` leaves plan mode before the turn starts.
	pi.on("input", (event, ctx) => {
		if (!planModeEnabled || !messageExitsPlanMode(event.text)) return;
		exitPlanModeFromUser(ctx);
	});

	// Block destructive bash commands in plan mode
	pi.on("tool_call", async (event) => {
		if (!planModeEnabled || event.toolName !== "bash") return;

		const command = event.input.command as string;
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `Plan mode: command blocked (not allowlisted). Use /plan to disable plan mode first.\nCommand: ${command}`,
			};
		}
	});

	// Filter out stale plan mode context when not in plan mode
	pi.on("context", async (event) => {
		if (planModeEnabled) return;

		return {
			messages: event.messages.filter((m) => {
				const msg = m as AgentMessage & { customType?: string };
				if (msg.customType === "plan-mode-context") return false;
				if (msg.role !== "user") return true;

				const content = msg.content;
				if (typeof content === "string") {
					return !content.includes("[PLAN MODE ACTIVE]");
				}
				if (Array.isArray(content)) {
					return !content.some(
						(c) => c.type === "text" && (c as TextContent).text?.includes("[PLAN MODE ACTIVE]"),
					);
				}
				return true;
			}),
		};
	});

	// Inject plan/execution context before a user prompt. Runs started by custom messages, such as
	// background task notifications, skip it: the context from the last prompt is still in the
	// conversation, and adding it again on every notification would only repeat it.
	pi.on("before_agent_start", async (event, ctx) => {
		if (event.messageType !== "user") return;
		if (planModeEnabled && messageExitsPlanMode(event.prompt)) {
			exitPlanModeFromUser(ctx);
		}

		if (planModeEnabled) {
			return {
				message: {
					customType: "plan-mode-context",
					content: `[PLAN MODE ACTIVE]
You are in plan mode - a read-only exploration mode for safe code analysis.

Restrictions:
- Built-in edit and write tools are disabled
- Other currently active tools remain available
- Bash is restricted to an allowlist of read-only commands
- You may run query commands: grep, ls, cat, bat, jq, git status, git log (including git -C and git --no-pager), and read-only gh (pr/issue/repo/run view or list, search, status, GET api). Pipelines of those commands are allowed. Do not redirect output to files.

Plan first. Do not edit files or run mutating commands until the user chooses to execute the plan.
The user exits plan mode by sending execute or go on its own line. When they do, plan mode is already off for that turn — do not ask them to toggle /plan.

Create a detailed numbered plan under a "Plan:" header:

Plan:
1. First step description
2. Second step description
...

Do NOT attempt to make changes - just describe what you would do.`,
					display: false,
				},
			};
		}

		if (executionMode && todoItems.length > 0) {
			const remaining = todoItems.filter((t) => !t.completed);
			const todoList = remaining.map((t) => `${t.step}. ${t.text}`).join("\n");
			return {
				message: {
					customType: "plan-execution-context",
					content: `[EXECUTING PLAN - Full tool access enabled]

Remaining steps:
${todoList}

Execute each step in order.
After completing a step, include a [DONE:n] tag in your response.`,
					display: false,
				},
			};
		}
	});

	// Track progress after each turn
	pi.on("turn_end", async (event, ctx) => {
		if (!executionMode || todoItems.length === 0) return;
		if (!isAssistantMessage(event.message)) return;

		const text = getTextContent(event.message);
		if (markCompletedSteps(text, todoItems) > 0) {
			updateStatus(ctx);
		}
		persistState();
	});

	// Handle plan completion and plan mode UI
	pi.on("agent_end", async (event, ctx) => {
		// Check if execution is complete
		if (executionMode && todoItems.length > 0) {
			if (todoItems.every((t) => t.completed)) {
				const completedList = todoItems.map((t) => `~~${t.text}~~`).join("\n");
				pi.sendMessage(
					{ customType: "plan-complete", content: `**Plan Complete!** ✓\n\n${completedList}`, display: true },
					{ triggerTurn: false },
				);
				executionMode = false;
				todoItems = [];
				planModeEnabled = true;
				enablePlanModeTools();
				updateStatus(ctx);
				persistState(); // Next request plans first again; /plan still toggles this off
			}
			return;
		}

		if (!planModeEnabled || !ctx.hasUI) return;

		// Extract todos from last assistant message
		const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
		if (lastAssistant) {
			const extracted = extractTodoItems(getTextContent(lastAssistant));
			if (extracted.length > 0) {
				todoItems = extracted;
			}
		}

		if (todoItems.length === 0) return;
		persistState();

		// Show plan steps and prompt for next action
		const todoListText = todoItems.map((t, i) => `${i + 1}. ☐ ${t.text}`).join("\n");
		const planTodoListMessage = {
			customType: "plan-todo-list",
			content: `**Plan Steps (${todoItems.length}):**\n\n${todoListText}`,
			display: true,
		};

		const choice = await waitForPlanInput("Plan mode needs input", () =>
			ctx.ui.select("Plan mode - what next?", [
				"Execute the plan (track progress)",
				"Stay in plan mode",
				"Refine the plan",
			]),
		);

		if (choice?.startsWith("Execute")) {
			const firstTodoItem = todoItems[0];
			if (!firstTodoItem) return;

			planModeEnabled = false;
			executionMode = true;
			restoreNormalModeTools();
			updateStatus(ctx);
			persistState();

			const remainingList = todoItems.map((t) => `${t.step}. ${t.text}`).join("\n");
			const execMessage = `Execute the plan.

Remaining steps:
${remainingList}

Start with: ${firstTodoItem.text}
After completing a step, include a [DONE:n] tag in your response.`;
			pi.sendMessage(planTodoListMessage, { deliverAs: "followUp" });
			pi.sendMessage(
				{ customType: "plan-mode-execute", content: execMessage, display: true },
				{ triggerTurn: true, deliverAs: "followUp" },
			);
		} else if (choice === "Refine the plan") {
			const refinement = await waitForPlanInput("Plan mode needs input", () =>
				ctx.ui.editor("Refine the plan:", ""),
			);
			if (refinement?.trim()) {
				pi.sendMessage(planTodoListMessage, { deliverAs: "followUp" });
				pi.sendUserMessage(refinement.trim(), { deliverAs: "followUp" });
			}
		}
	});

	// Restore state on session start/resume
	pi.on("session_start", async (_event, ctx) => {
		if (pi.getFlag("plan") === true) {
			planModeEnabled = true;
		}

		const entries = ctx.sessionManager.getEntries();

		// Restore persisted state
		const planModeEntry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "plan-mode")
			.pop() as { data?: PlanModeState } | undefined;

		if (planModeEntry?.data) {
			planModeEnabled = planModeEntry.data.enabled ?? planModeEnabled;
			todoItems = planModeEntry.data.todos ?? todoItems;
			executionMode = planModeEntry.data.executing ?? executionMode;
			toolsBeforePlanMode = planModeEntry.data.toolsBeforePlanMode ?? toolsBeforePlanMode;
		}

		// Wins over the default and over resumed session state. Do not call
		// restoreNormalModeTools(): that would drop tools that plan mode did not enable.
		if (pi.getFlag("no-plan") === true) {
			planModeEnabled = false;
			executionMode = false;
		}

		// On resume: re-scan messages to rebuild completion state
		// Only scan messages AFTER the last "plan-mode-execute" to avoid picking up [DONE:n] from previous plans
		const isResume = planModeEntry !== undefined;
		if (isResume && executionMode && todoItems.length > 0) {
			// Find the index of the last plan-mode-execute entry (marks when current execution started)
			let executeIndex = -1;
			for (let i = entries.length - 1; i >= 0; i--) {
				const entry = entries[i] as { type: string; customType?: string };
				if (entry.customType === "plan-mode-execute") {
					executeIndex = i;
					break;
				}
			}

			// Only scan messages after the execute marker
			const messages: AssistantMessage[] = [];
			for (let i = executeIndex + 1; i < entries.length; i++) {
				const entry = entries[i];
				if (entry.type === "message" && "message" in entry && isAssistantMessage(entry.message as AgentMessage)) {
					messages.push(entry.message as AssistantMessage);
				}
			}
			const allText = messages.map(getTextContent).join("\n");
			markCompletedSteps(allText, todoItems);
		}

		if (planModeEnabled) {
			enablePlanModeTools();
			ctx.ui.notify("Plan mode is on. Shift+Tab, /plan, or Ctrl+Alt+P toggles it off.", "info");
		}
		updateStatus(ctx);
	});
}
