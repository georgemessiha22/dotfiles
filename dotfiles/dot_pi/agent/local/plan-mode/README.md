# Plan Mode Extension

Read-only exploration mode for safe code analysis.

## Features

- **Built-in write tools disabled**: Disables edit/write while preserving other active tools
- **Bash allowlist**: Only read-only bash commands are allowed
- **Plan extraction**: Extracts numbered steps from `Plan:` sections
- **Progress tracking**: Widget shows completion status during execution
- **[DONE:n] markers**: Explicit step completion tracking
- **Session persistence**: State survives session resume
- **Chat exit**: A reply line that is only `execute` or `go` leaves plan mode. If plan steps exist, that turn executes them.
- **Input signal**: The plan dialog notifies that user input is required. Inside Herdr it shows a request toast and reports `blocked` from source `pi-plan-mode`. Elsewhere it sends a terminal notification.

## Commands

- `Shift+Tab` - Toggle plan mode (shown in the bottom bar as `plan` or `agent`)
- `/plan` - Toggle plan mode
- `/todos` - Show current plan progress
- `Ctrl+Alt+P` - Toggle plan mode (shortcut)
- `Ctrl+Shift+Tab` - Cycle thinking level (`Shift+Tab` is plan mode, not thinking)

## Usage

1. Plan mode starts enabled. The bottom bar shows `plan` or `agent`. Toggle with `Shift+Tab`, `/plan`, or Ctrl+Alt+P
2. Ask the agent to analyze code and create a plan
3. The agent should output a numbered plan under a `Plan:` header:

```
Plan:
1. First step description
2. Second step description
3. Third step description
```

4. Choose "Execute the plan" when prompted, or reply with `execute` or `go` on its own line
5. During execution, the agent marks steps complete with `[DONE:n]` tags
6. Progress widget shows completion status

## How It Works

### Plan Mode (Read-Only)
- Built-in edit/write tools disabled
- Other active tools remain available
- Bash commands filtered through allowlist
- Agent creates a plan without making changes

### Execution Mode
- Full tool access restored
- Agent executes steps in order
- `[DONE:n]` markers track completion
- Widget shows progress

### Command Allowlist

Safe commands (allowed):
- File inspection: `cat`, `bat`, `head`, `tail`, `less`, `more`
- Search: `grep`, `find`, `rg`, `fd`, `jq`
- Directory: `ls`, `pwd`, `tree`
- Git read: `git status`, `git log`, `git diff`, `git branch`, including global options such as `git -C repo status` and `git --no-pager log`
- GitHub read: `gh pr view|list|status|diff|checks`, `gh issue view|list`, `gh repo view`, `gh run view|list`, `gh search`, `gh status`, and `gh api` GET only
- Package info: `npm list`, `npm outdated`, `yarn info`
- System info: `uname`, `whoami`, `date`, `uptime`
- Pipelines and chains (`|`, `&&`, `||`, `;`) when every segment is read-only
- Stderr/null redirects: `2>&1`, `2>/dev/null`, `>/dev/null`

Blocked commands:
- File modification: `rm`, `mv`, `cp`, `mkdir`, `touch`
- File redirects: `> file`, `>> file`
- Git write: `git add`, `git commit`, `git push`, including after `git -C` or `git --no-pager`
- GitHub write: `gh pr create|merge|checkout`, `gh issue comment`, non-GET `gh api`
- Package install: `npm install`, `yarn add`, `pip install`
- System: `sudo`, `kill`, `reboot`
- Editors: `vim`, `nano`, `code`
