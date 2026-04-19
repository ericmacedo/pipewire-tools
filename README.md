# PipeWire Tools

A simple, modular Command-Line Interface (CLI) tool designed to manage and cycle PipeWire/WirePlumber output devices on Linux natively.

## Purpose

When using modern Linux desktop environments (like KDE Plasma on Wayland) backed by PipeWire, you often encounter multiple audio sinks. Some of these sinks might be unconnected HDMI/DisplayPort outputs that clutter your system. 

This tool provides an easy way to:
1. **Cycle** through active audio output devices via a single command (perfect for binding to keyboard shortcuts).
2. **Ignore** specific ghost devices (like unplugged monitors) so they are completely skipped during cycling, without breaking them at the system level.

Under the hood, this tool dynamically injects `node.cycle.ignore = true` flags via WirePlumber's Lua configuration files and seamlessly skips over them during iteration.

## System Requirements

- **Linux** (Tested on CachyOS / Arch Linux)
- **PipeWire** installed and active.
- **WirePlumber** (version 0.5+ required) installed and active.
- standard `bash`, `awk`, `sed`, and `grep`.

## Installation

Clone the repository to your preferred location (for example, `~/.local/bin/` or `~/Workspace/`):

```bash
git clone <repository_url> pipewire-tools
cd pipewire-tools
chmod +x pipewire-tools modules/*.sh
```

*(Optional)* You can symlink the main script to a directory in your `$PATH` so you can call it from anywhere:
```bash
ln -s "$(pwd)/pipewire-tools" ~/.local/bin/pipewire-tools
```

## CLI Usage

The tool is modular and supports multiple subcommands. You can append `--help` to any command to see its specific documentation.

### Main Commands

```bash
pipewire-tools <command> [options]
```
- `cycle`: Cycle output devices forward or backward.
- `device`: Manage devices and their ignore flags.

---

### The `cycle` Command
Changes the default system audio output to the next available device in the list. This relies purely on PipeWire, triggering the native Desktop Environment OSD volume indicator automatically.

```bash
# Cycle forward (Next device)
pipewire-tools cycle 1
# Or simply
pipewire-tools cycle

# Cycle backward (Previous device)
pipewire-tools cycle -1
```
*Tip: Bind these two commands to custom keyboard shortcuts in your Desktop Environment.*

---

### The `device` Command
Used to view and configure which devices should be ignored when cycling.

**List Devices**
Shows all available PipeWire audio sinks, their ID, name, description, and whether they are currently flagged to be ignored `[X]`.

```bash
pipewire-tools device list
```

**Ignore a Device**
Flag a device to be skipped when using the `cycle` command. Grab the `ID` from the `list` command.
```bash
pipewire-tools device ignore <device_id>
```
*(This automatically rebuilds the WirePlumber configuration and restarts the WirePlumber daemon).*

**Enable a Device**
Remove the ignore flag from a device, returning it to the normal cycle rotation.
```bash
pipewire-tools device enable <device_id>
```