#!/usr/bin/env bash
# New-machine setup for this Claude Code config. Run from Git Bash after:
#   install Claude Code, then: git clone <this repo> ~/.claude && claude   (log in once, then quit)
# Safe to rerun: installed items are skipped, overwritten dotfiles get a .bak copy.
# Usage: bash ~/.claude/bootstrap.sh                      install everything, pick third-party skills interactively
#        bash ~/.claude/bootstrap.sh --skills all|none|1,2,5  same, with the skill choice given up front
#        bash ~/.claude/bootstrap.sh --capture            copy this machine's live dotfiles into the repo
set -uo pipefail
REPO="$HOME/.claude"
SKILLS=""
[ "${1:-}" = "--skills" ] && SKILLS="${2:?--skills needs all, none or a list like 1,2,5}"

if [ "${1:-}" = "--capture" ]; then
  cp "$(pwsh -NoProfile -Command '$PROFILE' | tr -d '\r')" "$REPO/dotfiles/"
  cp "$HOME/.oh-my-posh/clean-detailed.omp.json" "$REPO/dotfiles/"
  git -C "$REPO" status --short dotfiles
  exit 0
fi

step() { printf '\n== %s\n' "$1"; }
missing=()

step "winget packages"
for id in Git.Git Microsoft.PowerShell astral-sh.uv GitHub.cli jqlang.jq OpenJS.NodeJS.LTS \
          JanDeDobbeleer.OhMyPosh sharkdp.fd ZedIndustries.Zed rtk-ai.rtk; do
  if winget list --id "$id" -e --accept-source-agreements >/dev/null 2>&1; then
    echo "ok        $id"
  else
    winget install --id "$id" -e --silent --accept-package-agreements --accept-source-agreements \
      && echo "installed $id" || missing+=("winget $id")
  fi
done

for bin in pwsh uv npx claude jq; do
  if ! command -v "$bin" >/dev/null; then
    echo "$bin is not on PATH yet (fresh winget installs need a new terminal). Open a new Git Bash and rerun this script."
    exit 1
  fi
done

step "uv tools"
# markitdown[all] needs an Azure pre-release dependency, so list the extras explicitly
uv tool install "markitdown[pdf,docx,pptx,xlsx,xls,outlook,audio-transcription,youtube-transcription]" || missing+=("uv markitdown")

step "PowerShell modules"
pwsh -NoProfile -Command 'Install-Module posh-git,PSFzf,Terminal-Icons -Scope CurrentUser -Force -AcceptLicense' \
  || missing+=("pwsh modules")

step "dotfiles"
PROFILE_PS="$(pwsh -NoProfile -Command '$PROFILE' | tr -d '\r')"
mkdir -p "$(dirname "$PROFILE_PS")" "$HOME/.oh-my-posh"
for target in "$PROFILE_PS" "$HOME/.oh-my-posh/clean-detailed.omp.json"; do
  [ -f "$target" ] && cp "$target" "$target.bak-$(date +%Y%m%d%H%M%S)"
done
cp "$REPO/dotfiles/Microsoft.PowerShell_profile.ps1" "$PROFILE_PS"
cp "$REPO/dotfiles/clean-detailed.omp.json" "$HOME/.oh-my-posh/"
echo "profile -> $PROFILE_PS"

step "MCP servers (user scope, stored in ~/.claude.json)"
add_mcp() {
  local name="$1"; shift
  if claude mcp get "$name" >/dev/null 2>&1; then echo "ok        $name"
  else claude mcp add --scope user "$name" -- "$@" && echo "added     $name" || missing+=("mcp $name"); fi
}
add_mcp playwright npx @playwright/mcp@latest
add_mcp mobile npx -y @mobilenext/mobile-mcp@1.0.16

step "third-party skills (upstream, see README Credits)"
bash "$REPO/scripts/install-skills.sh" ${SKILLS:+--select "$SKILLS"} || missing+=("third-party skills: rerun scripts/install-skills.sh")

step "self-check"
uv run --script "$REPO/scripts/docread.py" --selftest || missing+=("docread selftest")

printf '\n== done\n'
if [ ${#missing[@]} -eq 0 ]; then
  echo "All steps succeeded. Start claude: plugins from settings.json download in the background; run /reload-plugins when prompted."
else
  echo "Needs attention:"; printf '  - %s\n' "${missing[@]}"; exit 1
fi
