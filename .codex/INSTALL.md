# Installing Forge for Codex

Enable forge skills in Codex via native skill discovery. Just clone and symlink.

## Prerequisites

- Git

## Installation

1. **Clone the forge repository:**
   ```bash
   git clone https://github.com/rahulsc/superpowers.git ~/.codex/forge
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/forge/skills ~/.agents/skills/forge
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\forge" "$env:USERPROFILE\.codex\forge\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Migrating from old bootstrap

If you installed forge before native skill discovery, you need to:

1. **Update the repo:**
   ```bash
   cd ~/.codex/forge && git pull
   ```

2. **Create the skills symlink** (step 2 above) -- this is the new discovery mechanism.

3. **Remove the old bootstrap block** from `~/.codex/AGENTS.md` -- any block referencing `forge-codex bootstrap` is no longer needed.

4. **Restart Codex.**

## Verify

```bash
ls -la ~/.agents/skills/forge
```

You should see a symlink (or junction on Windows) pointing to your forge skills directory.

## Updating

```bash
cd ~/.codex/forge && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/forge
```

Optionally delete the clone: `rm -rf ~/.codex/forge`.
