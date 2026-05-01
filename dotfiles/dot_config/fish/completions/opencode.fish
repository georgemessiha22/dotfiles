# Fish completion for opencode

function __opencode_yargs_completions
    set -l args (commandline -opc)
    set -e args[1]
    opencode --get-yargs-completions $args 2>/dev/null
end

complete -c opencode -f -a '(__opencode_yargs_completions)'

# Level 1: Main commands
complete -c opencode -n '__fish_use_subcommand' -a "completion" -d "Generate shell completion script"
complete -c opencode -n '__fish_use_subcommand' -a "acp" -d "Start ACP server"
complete -c opencode -n '__fish_use_subcommand' -a "mcp" -d "Manage MCP servers"
complete -c opencode -n '__fish_use_subcommand' -a "attach" -d "Attach to running server"
complete -c opencode -n '__fish_use_subcommand' -a "run" -d "Run with message"
complete -c opencode -n '__fish_use_subcommand' -a "debug" -d "Debugging tools"
complete -c opencode -n '__fish_use_subcommand' -a "providers" -d "Manage AI providers"
complete -c opencode -n '__fish_use_subcommand' -a "agent" -d "Manage agents"
complete -c opencode -n '__fish_use_subcommand' -a "upgrade" -d "Upgrade opencode"
complete -c opencode -n '__fish_use_subcommand' -a "uninstall" -d "Uninstall opencode"
complete -c opencode -n '__fish_use_subcommand' -a "serve" -d "Start headless server"
complete -c opencode -n '__fish_use_subcommand' -a "web" -d "Open web interface"
complete -c opencode -n '__fish_use_subcommand' -a "models" -d "List models"
complete -c opencode -n '__fish_use_subcommand' -a "stats" -d "Show statistics"
complete -c opencode -n '__fish_use_subcommand' -a "export" -d "Export session"
complete -c opencode -n '__fish_use_subcommand' -a "import" -d "Import session"
complete -c opencode -n '__fish_use_subcommand' -a "github" -d "GitHub agent"
complete -c opencode -n '__fish_use_subcommand' -a "pr" -d "Checkout PR"
complete -c opencode -n '__fish_use_subcommand' -a "session" -d "Manage sessions"
complete -c opencode -n '__fish_use_subcommand' -a "plugin" -d "Install plugin"
complete -c opencode -n '__fish_use_subcommand' -a "db" -d "Database tools"

# Level 2: agent
complete -c opencode -n '__fish_seen_subcommand_from agent' -a "list" -d "List all available agents"
complete -c opencode -n '__fish_seen_subcommand_from agent' -a "create" -d "Create a new agent"

# Level 2: mcp
complete -c opencode -n '__fish_seen_subcommand_from mcp' -a "add" -d "Add an MCP server"
complete -c opencode -n '__fish_seen_subcommand_from mcp' -a "list" -d "List MCP servers"
complete -c opencode -n '__fish_seen_subcommand_from mcp' -a "auth" -d "Authenticate with MCP server"
complete -c opencode -n '__fish_seen_subcommand_from mcp' -a "logout" -d "Remove MCP credentials"
complete -c opencode -n '__fish_seen_subcommand_from mcp' -a "debug" -d "Debug MCP connection"

# Level 2: providers
complete -c opencode -n '__fish_seen_subcommand_from providers' -a "list" -d "List providers and credentials"
complete -c opencode -n '__fish_seen_subcommand_from providers' -a "login" -d "Log in to a provider"
complete -c opencode -n '__fish_seen_subcommand_from providers' -a "logout" -d "Log out from provider"

# Level 2: github
complete -c opencode -n '__fish_seen_subcommand_from github' -a "install" -d "Install GitHub agent"
complete -c opencode -n '__fish_seen_subcommand_from github' -a "run" -d "Run GitHub agent"

# Level 2: session
complete -c opencode -n '__fish_seen_subcommand_from session' -a "list" -d "List sessions"
complete -c opencode -n '__fish_seen_subcommand_from session' -a "delete" -d "Delete a session"

# Level 2: plugin
complete -c opencode -n '__fish_seen_subcommand_from plugin' -a "install" -d "Install plugin"
complete -c opencode -n '__fish_seen_subcommand_from plugin' -a "update" -d "Update plugin"

# Level 2: db
complete -c opencode -n '__fish_seen_subcommand_from db' -a "query" -d "Run SQL query"
complete -c opencode -n '__fish_seen_subcommand_from db' -a "path" -d "Print database path"
complete -c opencode -n '__fish_seen_subcommand_from db' -a "migrate" -d "Migrate JSON to SQLite"

# Level 2: debug
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "config" -d "Show resolved configuration"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "lsp" -d "LSP debugging utilities"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "rg" -d "Ripgrep debugging utilities"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "file" -d "File system debugging"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "scrap" -d "List known projects"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "skill" -d "List available skills"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "snapshot" -d "Snapshot debugging"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "agent" -d "Show agent config"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "paths" -d "Show global paths"
complete -c opencode -n '__fish_seen_subcommand_from debug' -a "wait" -d "Wait indefinitely"

# Level 3: agent create flags
complete -c opencode -n '__fish_seen_subcommand_from agent create' -x -a "--path" -d "Directory path for agent"
complete -c opencode -n '__fish_seen_subcommand_from agent create' -x -a "--description" -d "What the agent should do"
complete -c opencode -n '__fish_seen_subcommand_from agent create' -x -a "--mode" -d "Agent mode (all/primary/subagent)"
complete -c opencode -n '__fish_seen_subcommand_from agent create' -x -a "--tools" -d "Tools to enable"
complete -c opencode -n '__fish_seen_subcommand_from agent create' -x -a "-m --model" -d "Model to use"

# Level 3: mcp add flags
complete -c opencode -n '__fish_seen_subcommand_from mcp add' -x -a "--name" -d "Server name"
complete -c opencode -n '__fish_seen_subcommand_from mcp add' -x -a "--command" -d "Command to run"
complete -c opencode -n '__fish_seen_subcommand_from mcp add' -x -a "--env" -d "Environment variables"
complete -c opencode -n '__fish_seen_subcommand_from mcp add' -x -a "--url" -d "Server URL"

# Level 3: attach flags
complete -c opencode -n '__fish_seen_subcommand_from attach' -x -a "--dir" -d "Directory to run in"
complete -c opencode -n '__fish_seen_subcommand_from attach' -x -a "-c --continue" -d "Continue session"
complete -c opencode -n '__fish_seen_subcommand_from attach' -x -a "-s --session" -d "Session ID"
complete -c opencode -n '__fish_seen_subcommand_from attach' -x -a "--fork" -d "Fork session"
complete -c opencode -n '__fish_seen_subcommand_from attach' -x -a "-p --password" -d "Basic auth password"

# Level 3: run flags
complete -c opencode -n '__fish_seen_subcommand_from run' -x -a "-c --continue" -d "Continue session"
complete -c opencode -n '__fish_seen_subcommand_from run' -x -a "-s --session" -d "Session ID"
complete -c opencode -n '__fish_seen_subcommand_from run' -x -a "--fork" -d "Fork session"
complete -c opencode -n '__fish_seen_subcommand_from run' -x -a "-m --model" -d "Model to use"
complete -c opencode -n '__fish_seen_subcommand_from run' -x -a "--prompt" -d "Prompt to use"
complete -c opencode -n '__fish_seen_subcommand_from run' -x -a "--agent" -d "Agent to use"

# Level 3: upgrade flags
complete -c opencode -n '__fish_seen_subcommand_from upgrade' -x -a "-m --method" -d "Installation method"

# Level 3: import flags
complete -c opencode -n '__fish_seen_subcommand_from import' -x -a "--format" -d "Output format"

# Level 3: export flags
complete -c opencode -n '__fish_seen_subcommand_from export' -x -a "--sanitize" -d "Redact sensitive data"

# Level 3: stats flags
complete -c opencode -n '__fish_seen_subcommand_from stats' -x -a "--days" -d "Show last N days"
complete -c opencode -n '__fish_seen_subcommand_from stats' -x -a "--tools" -d "Number of tools"
complete -c opencode -n '__fish_seen_subcommand_from stats' -x -a "--models" -d "Show model statistics"
complete -c opencode -n '__fish_seen_subcommand_from stats' -x -a "--project" -d "Filter by project"

# Level 3: models flags
complete -c opencode -n '__fish_seen_subcommand_from models' -x -a "--verbose" -d "Verbose output"
complete -c opencode -n '__fish_seen_subcommand_from models' -x -a "--refresh" -d "Refresh cache"

# Level 3: plugin flags
complete -c opencode -n '__fish_seen_subcommand_from plugin' -x -a "-g --global" -d "Install globally"
complete -c opencode -n '__fish_seen_subcommand_from plugin' -x -a "-f --force" -d "Replace existing"

# Level 3: common flags (various commands)
complete -c opencode -n '__fish_seen_subcommand_from' -x -a "-h --help --print-logs --log-level --pure --version" -d "Common options"

# Level 3: server flags (serve, web, acp)
complete -c opencode -n '__fish_seen_subcommand_from serve' -x -a "--port --hostname --mdns --mdns-domain --cors --cwd" -d "Server options"
complete -c opencode -n '__fish_seen_subcommand_from web' -x -a "--port --hostname --mdns --mdns-domain --cors --cwd" -d "Server options"
complete -c opencode -n '__fish_seen_subcommand_from acp' -x -a "--port --hostname --mdns --mdns-domain --cors --cwd" -d "Server options"
