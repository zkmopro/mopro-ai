---
description: Check mopro development environment and diagnose missing tools
argument-hint: "[platform]"
allowed-tools: Bash, Read, Glob
---

# /mopro:check-env

Check the development environment for mopro prerequisites.

## Arguments

- `$1` (optional): Target platform to check. One of: `ios`, `android`, `flutter`,
  `react-native`, `web`, `all`. Defaults to `all`.

## Instructions

1. Run the environment check script with the specified platform:

```bash
bash $SKILL_DIR/../skills/mopro-env/scripts/check-env.sh $ARGUMENTS
```

2. Parse the JSON output and present results in a clear table:

| Tool | Status | Version | Required |
|------|--------|---------|----------|

3. Summarize:
   - Count of installed vs missing required tools
   - Count of installed vs missing platform-specific tools
   - If all required tools are present: "Environment is ready for mopro development!"
   - If any required tools are missing: List specific install commands

4. If a platform was specified, highlight only the tools relevant to that platform.

5. For any missing required tool, provide the exact install command from the
   prerequisites reference.
