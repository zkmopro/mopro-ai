#!/usr/bin/env bash
set -euo pipefail

errors=0

fail() {
  echo "FAIL: $1"
  errors=$((errors + 1))
}

pass() {
  echo "  OK: $1"
}

# ---------- 1. Check all expected files exist ----------

echo "=== Checking expected files ==="

expected_files=(
  .claude-plugin/plugin.json
  AGENTS.md
  settings.json
  .claude/rules/build-background.md
  README.md
  commands/build.md
  commands/check-env.md
  commands/create.md
  commands/device.md
  commands/init.md
  commands/new.md
  commands/test.md
  skills/mopro-env/SKILL.md
  skills/mopro-project/SKILL.md
  skills/mopro-app/SKILL.md
  skills/mopro-device/SKILL.md
  skills/mopro-test/SKILL.md
  skills/mopro-env/references/prerequisites.md
  skills/mopro-project/references/architectures.md
  skills/mopro-project/references/cli-reference.md
  skills/mopro-project/references/project-structure.md
  skills/mopro-project/references/troubleshooting.md
  skills/mopro-app/references/ios-guide.md
  skills/mopro-app/references/android-guide.md
  skills/mopro-app/references/flutter-guide.md
  skills/mopro-app/references/react-native-guide.md
  skills/mopro-app/references/web-guide.md
  skills/mopro-app/references/troubleshooting.md
  skills/mopro-device/references/device-management.md
  skills/mopro-test/references/rust-ffi-tests.md
  skills/mopro-test/references/mobile-ui-tests.md
  skills/mopro-env/scripts/check-env.sh
  skills/mopro-device/scripts/list-devices.sh
)

file_count=0
for f in "${expected_files[@]}"; do
  if [[ -f "$f" ]]; then
    pass "$f"
    file_count=$((file_count + 1))
  else
    fail "missing file: $f"
  fi
done
echo "--- $file_count / ${#expected_files[@]} files found ---"
echo

# ---------- 1b. Check CLAUDE.md symlink ----------

echo "=== Checking CLAUDE.md symlink ==="

if [[ -L "CLAUDE.md" ]]; then
  target=$(readlink CLAUDE.md)
  if [[ "$target" == "AGENTS.md" ]]; then
    pass "CLAUDE.md is a symlink to AGENTS.md"
  else
    fail "CLAUDE.md symlink points to '$target' (expected AGENTS.md)"
  fi
elif [[ -f "CLAUDE.md" ]]; then
  fail "CLAUDE.md exists but is not a symlink (should be symlink to AGENTS.md)"
else
  fail "CLAUDE.md does not exist"
fi
echo

# ---------- 2. Validate YAML frontmatter ----------

echo "=== Checking YAML frontmatter ==="

check_frontmatter() {
  local file="$1"
  if head -1 "$file" | grep -q '^---$'; then
    if grep -q '^description:' "$file"; then
      pass "$file has frontmatter with description"
    else
      fail "$file has frontmatter but missing description field"
    fi
  else
    fail "$file missing YAML frontmatter (--- delimiter)"
  fi
}

for cmd in commands/*.md; do
  check_frontmatter "$cmd"
done

check_skill_name() {
  local file="$1"
  if grep -q '^name:' "$file"; then
    pass "$file has name field"
  else
    fail "$file missing required name field (agentskills.io spec)"
  fi
}

for skill in skills/*/SKILL.md; do
  check_frontmatter "$skill"
  check_skill_name "$skill"
done
echo

# ---------- 2b. Validate no $SKILL_DIR in SKILL.md files ----------

echo "=== Checking no \$SKILL_DIR in SKILL.md files ==="

for skill in skills/*/SKILL.md; do
  if grep -q '\$SKILL_DIR' "$skill"; then
    fail "$skill contains \$SKILL_DIR (use relative paths per agentskills.io spec)"
  else
    pass "$skill has no \$SKILL_DIR references"
  fi
done
echo

# ---------- 3. Cross-reference check ----------

echo "=== Checking cross-references ==="

for skill_md in skills/*/SKILL.md; do
  skill_dir=$(dirname "$skill_md")
  refs=$(grep -oE 'references/[a-zA-Z0-9_-]+\.md' "$skill_md" || true)
  if [[ -z "$refs" ]]; then
    echo "  --: $skill_md has no reference paths"
    continue
  fi
  while IFS= read -r ref; do
    if [[ -f "$skill_dir/$ref" ]]; then
      pass "$skill_md -> $ref"
    else
      fail "$skill_md references $ref but $skill_dir/$ref does not exist"
    fi
  done <<< "$refs"
done
echo

# ---------- 4. Executable permissions on scripts ----------

echo "=== Checking script permissions ==="

while IFS= read -r -d '' script; do
  if [[ -x "$script" ]]; then
    pass "$script is executable"
  else
    fail "$script is not executable"
  fi
done < <(find . -name '*.sh' -print0)
echo

# ---------- Summary ----------

if [[ $errors -gt 0 ]]; then
  echo "FAILED: $errors error(s) found"
  exit 1
else
  echo "PASSED: all checks passed"
fi
