---
description: Initialize a new mopro project with Rust scaffolding and circuit test vectors
argument-hint: "[name] [adapters]"
allowed-tools: Bash, Read, Write, Glob
---

# /mopro:init

Initialize a new mopro project.

## Arguments

- `$1` (optional): Project name (lowercase, no spaces, hyphens OK)
- `$2` (optional): Comma-separated adapter list: `circom`, `halo2`, `noir`

## Instructions

1. If arguments are not provided, ask the user for:
   - **Project name**: Suggest a default like `my-zk-app`
   - **Adapters**: Ask which proving systems they need. Explain briefly:
     - `circom` — Groth16 proofs, most common for ZK apps
     - `halo2` — Plonkish proofs, used in Ethereum L2s
     - `noir` — Barretenberg proofs, developer-friendly DSL

2. Verify mopro-cli is installed:
```bash
mopro --version
```
If not found, guide: `cargo install mopro-cli`

3. Confirm before running:
```
About to run: mopro init --project_name <name> --adapter <adapters>
This will create a new directory './<name>' with Rust project scaffolding.
Proceed?
```

4. Run init:
```bash
mopro init --project_name $1 --adapter $2
```

5. After completion, verify the project structure:
```bash
ls -la $1/
ls $1/src/lib.rs
ls $1/test-vectors/
```

6. Report what was created and suggest next steps:
   - Place circuit artifacts in `test-vectors/` if using custom circuits
   - Run `mopro build` to compile bindings for a target platform
