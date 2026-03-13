# Installing Forge for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git installed

## Installation Steps

### 1. Clone Forge

```bash
git clone https://github.com/rahulsc/superpowers.git ~/.config/opencode/forge
```

### 2. Register the Plugin

Create a symlink so OpenCode discovers the plugin:

```bash
mkdir -p ~/.config/opencode/plugins
rm -f ~/.config/opencode/plugins/forge.js
ln -s ~/.config/opencode/forge/.opencode/plugins/forge.js ~/.config/opencode/plugins/forge.js
```

### 3. Symlink Skills

Create a symlink so OpenCode's native skill tool discovers forge skills:

```bash
mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/forge
ln -s ~/.config/opencode/forge/skills ~/.config/opencode/skills/forge
```

### 4. Restart OpenCode

Restart OpenCode. The plugin will automatically inject forge context.

Verify by asking: "do you have forge?"

## Usage

### Finding Skills

Use OpenCode's native `skill` tool to list available skills:

```
use skill tool to list skills
```

### Loading a Skill

Use OpenCode's native `skill` tool to load a specific skill:

```
use skill tool to load forge/brainstorming
```

### Personal Skills

Create your own skills in `~/.config/opencode/skills/`:

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

Create `~/.config/opencode/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

### Project Skills

Create project-specific skills in `.opencode/skills/` within your project.

**Skill Priority:** Project skills > Personal skills > Forge skills

## Updating

```bash
cd ~/.config/opencode/forge
git pull
```

## Troubleshooting

### Plugin not loading

1. Check plugin symlink: `ls -l ~/.config/opencode/plugins/forge.js`
2. Check source exists: `ls ~/.config/opencode/forge/.opencode/plugins/forge.js`
3. Check OpenCode logs for errors

### Skills not found

1. Check skills symlink: `ls -l ~/.config/opencode/skills/forge`
2. Verify it points to: `~/.config/opencode/forge/skills`
3. Use `skill` tool to list what's discovered

### Tool mapping

When skills reference Claude Code tools:
- `TodoWrite` → `todowrite`
- `Task` with subagents → `@mention` syntax
- `Skill` tool → OpenCode's native `skill` tool
- File operations → your native tools

## Getting Help

- Report issues: https://github.com/rahulsc/superpowers/issues
- Full documentation: https://github.com/rahulsc/superpowers/blob/main/docs/README.opencode.md
