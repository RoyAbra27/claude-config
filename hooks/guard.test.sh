#!/usr/bin/env bash
# Run: bash ~/.claude/hooks/guard.test.sh
GUARD="${GUARD:-$(dirname "${BASH_SOURCE[0]}")/guard.sh}"
FAIL=0

check() {
  local want="$1" cmd="$2" got
  jq -n --arg c "$cmd" '{tool_name: "Bash", tool_input: {command: $c}}' | bash "$GUARD" 2>/dev/null
  got=$?
  if [ "$got" -ne "$want" ]; then
    echo "FAIL (want $want, got $got): $cmd"
    FAIL=1
  fi
}

check 2 'rm -rf build'
check 2 'cd x && rm -fr build'
check 2 'git push --force origin main'
check 2 'git push -f'
check 2 'psql -c "DROP TABLE x"'
check 2 'git commit -m "feat: x

Co-Authored-By: Bot <b@x>"'

check 2 'git reset --hard HEAD~1'
check 2 'git clean -fd'
check 2 'cd x && git clean -xdf'
check 2 'git branch -D feature'
check 2 'git checkout .'
check 2 'git checkout -- .'
check 2 'git restore .'

check 0 "grep -nE 'pipefail|rm -rf|DROP' file"
check 0 'grep -n "git reset --hard" notes.md'
check 0 'git reset --soft HEAD~1'
check 0 'git clean -n'
check 0 'git branch -d merged'
check 0 'git checkout main'
check 0 'git checkout ./src/a.ts'
check 0 'git restore src/a.ts'
check 0 'echo "git push --force is blocked"'
check 0 'rm file.txt'
check 0 'git push origin main'

[ "$FAIL" -eq 0 ] && echo "guard: all cases pass"
exit "$FAIL"
