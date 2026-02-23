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
  CLAUDE.md
  settings.json
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

for skill in skills/*/SKILL.md; do
  check_frontmatter "$skill"
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
