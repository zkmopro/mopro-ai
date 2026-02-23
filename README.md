# mopro-ai

A [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code) for building mobile-native zero-knowledge proof applications with [mopro](https://zkmopro.org).

## What is mopro?

Mopro is a developer toolkit for building mobile ZK apps. It uses Rust + UniFFI to generate native bindings for ZK provers across iOS, Android, Flutter, React Native, and Web. Supported proving systems: Circom (Groth16), Halo2 (Plonkish), Noir (Barretenberg).

## Installation

```bash
claude plugin add /path/to/mopro-ai
# or
claude --plugin-dir /path/to/mopro-ai
```

## Commands

| Command | Description |
|---|---|
| `/mopro:new [name] [adapter] [platform]` | Full workflow: init + build + create with confirmation gates |
| `/mopro:check-env [platform]` | Check development environment and diagnose missing tools |
| `/mopro:init [name] [adapters]` | Initialize a new mopro project |
| `/mopro:build [platform] [mode]` | Build ZK bindings (runs in background, warns about duration) |
| `/mopro:create [framework]` | Generate app template from bindings |
| `/mopro:test [level] [platform]` | Run tests at Rust, FFI, or UI level |
| `/mopro:device [action] [platform]` | List, start, or run on simulators/emulators/devices |

## Skills (Auto-Triggered)

Skills activate automatically based on what you ask Claude:

| Skill | Triggers on |
|---|---|
| **mopro-env** | "check environment", "install prerequisites", "what do I need" |
| **mopro-project** | "initialize project", "build bindings", "compile for mobile" |
| **mopro-app** | "build iOS app", "Flutter ZK app", "integrate mopro bindings" |
| **mopro-test** | "add tests", "test proof generation", "run cargo test" |
| **mopro-device** | "run on simulator", "start emulator", "list devices" |

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

  Claude will auto-trigger mopro-env → mopro-project → mopro-app skills
  to guide you through the full setup.
```

## Plugin Structure

```
mopro-ai/
├── .claude-plugin/plugin.json     # Plugin manifest
├── CLAUDE.md                      # Always-loaded context (guardrails, CLI reference)
├── settings.json                  # Tiered permissions
├── commands/                      # /mopro:* slash commands
│   ├── check-env.md
│   ├── new.md
│   ├── init.md
│   ├── build.md
│   ├── create.md
│   ├── test.md
│   └── device.md
└── skills/                        # Auto-triggered domain knowledge
    ├── mopro-env/                 # Environment setup + check-env.sh
    ├── mopro-project/             # Init/build/create workflow + references
    ├── mopro-app/                 # Platform integration guides (5 platforms)
    ├── mopro-test/                # Rust, FFI, and UI testing patterns
    └── mopro-device/              # Simulator/emulator/device management
```

## Key Design Decisions

- **Build guardrails**: Builds take 5-15+ minutes. The plugin always warns about duration, runs builds in background, and never re-runs without confirmation.
- **Minimal architectures**: Defaults to simulator-only builds for fast iteration. Device/production architectures only when explicitly requested.
- **mopro-cli required**: No manual fallback. If the CLI is missing, the plugin guides installation via `cargo install mopro-cli`.
- **Confirmation gates**: All mutating operations (init, build, create, device boot) require user confirmation.

## Prerequisites

- [mopro-cli](https://github.com/zkmopro/mopro): `cargo install mopro-cli`
- [Rust](https://rustup.rs): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- [CMake](https://cmake.org/download/): `brew install cmake`
- Platform-specific tools (Xcode, Android Studio, Flutter, Node.js, wasm-pack)

Run `/mopro:check-env` for a full diagnostic.

## Links

- [mopro documentation](https://zkmopro.org)
- [mopro GitHub](https://github.com/zkmopro/mopro)
- [Claude Code plugins](https://docs.anthropic.com/en/docs/claude-code)
