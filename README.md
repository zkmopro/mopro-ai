# mopro-ai

AI-powered toolkit for building mobile zero-knowledge proof applications with [mopro](https://zkmopro.org).

## What You Can Do

- **Scaffold a ZK project** from scratch with a single command (`/mopro:new`)
- **Build native bindings** for iOS, Android, Flutter, React Native, and Web
- **Generate starter app templates** ready to run on any platform
- **Run and test** on simulators, emulators, and physical devices
- **Diagnose your environment** and fix missing tools before you start

Follows the [Agent Skills](https://agentskills.io) open standard so that it works not only as a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code) but a plugin for all agents.

## Installation

```bash
# In Claude Code:
/plugin marketplace add zkmopro/mopro-ai
/plugin install mopro
```

Or for local development:

```bash
claude --plugin-dir /path/to/mopro-ai
```

## Prerequisites

- [mopro-cli](https://github.com/zkmopro/mopro): `cargo install mopro-cli`
- [Rust](https://rustup.rs): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- [CMake](https://cmake.org/download/): `brew install cmake`
- Platform-specific tools (Xcode, Android Studio, Flutter, Node.js, wasm-pack)

Run `/mopro:check-env` for a full diagnostic.

## Quick Start

```
> /mopro:check-env

  Checking environment...
  rust: 1.77.0    cargo: 1.77.0    cmake: 3.28.0    mopro-cli: 0.3.4
  All required tools installed.

> /mopro:new my-voting-app circom ios

  Step 1/3: Initializing project...
  Step 2/3: Building iOS bindings (this takes 5-15 min)...
  Step 3/3: Generating iOS app template...
  Done! Open my-voting-app/ios-app/MyApp.xcodeproj in Xcode.
```

Or just describe what you want:

```
> I want to build a ZK voting app for iOS using Noir

  Your agent will auto-trigger the right skills to guide you
  through environment check, project setup, and app generation.
```

## Commands

| Command | Description |
|---|---|
| `/mopro:new [name] [adapter] [platform]` | Full workflow: init + build + create |
| `/mopro:check-env [platform]` | Diagnose environment and missing tools |
| `/mopro:init [name] [adapters]` | Initialize a new mopro project |
| `/mopro:build [platform] [mode]` | Build ZK bindings (background, 5-15 min) |
| `/mopro:create [framework]` | Generate app template from bindings |
| `/mopro:test [level] [platform]` | Run Rust, FFI, or UI tests |
| `/mopro:device [action] [platform]` | Manage simulators, emulators, devices |

Beyond slash commands, skills also activate automatically based on what you ask. Mention "build for iOS", "check my environment", or "test proof generation" and the relevant skill triggers without needing a command.

## Agent Compatibility

This package is portable across AI coding agents. It uses [AGENTS.md](https://agents.md) for universal instructions and the [Agent Skills](https://agentskills.io) spec for auto-triggered workflows. Supported agents include Claude Code, Cursor, VS Code Copilot, Codex CLI, and Gemini CLI.

## Links

- [mopro documentation](https://zkmopro.org)
- [mopro GitHub](https://github.com/zkmopro/mopro)
- [Agent Skills spec](https://agentskills.io)
- [AGENTS.md spec](https://agents.md)
- [Claude Code plugins](https://docs.anthropic.com/en/docs/claude-code)

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or [MIT License](LICENSE-MIT) at your option.
