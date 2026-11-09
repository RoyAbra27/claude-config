# ─── Starting directory ──────────────────────────────────────────────────────
# When launched from taskbar/shortcut, pwsh starts in $HOME. Redirect to Desktop.
# Skip in VS Code (VSCODE_INJECTION is set) so project terminals open correctly.
if (-not $env:VSCODE_INJECTION -and $PWD.Path -eq $HOME) {
    Set-Location "$HOME\Desktop"
}

# ─── Oh-My-Posh prompt ───────────────────────────────────────────────────────
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$HOME\.oh-my-posh\clean-detailed.omp.json" | Invoke-Expression
}

# ─── zoxide (smart cd, replaces ZLocation) ───────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    $zoxideCache = "$env:TEMP\zoxide_pwsh_init.ps1"
    $_zoxideExe  = (Get-Command zoxide).Source
    if (-not (Test-Path $zoxideCache) -or
        (Get-Item $_zoxideExe).LastWriteTime -gt (Get-Item $zoxideCache).LastWriteTime) {
        zoxide init powershell | Out-File $zoxideCache -Encoding utf8
    }
    . $zoxideCache
}

# ─── PSReadLine global options (apply to all terminal types) ─────────────────
if ($Host.Name -notlike 'ServerRemoteHost') {
    Set-PSReadLineOption -MaximumHistoryCount 10000
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -BellStyle None

    $isFullTerminal = $Host.UI.RawUI.SupportsVirtualTerminal `
                      -and -not $env:VSCODE_INJECTION `
                      -and -not $env:TERM_PROGRAM

    # Smart RightArrow: move cursor when inside text, accept suggestion word when at end
    $smartRight = {
        param($key, $arg)
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
        }
    }

    # Smart Ctrl+RightArrow: jump forward word when inside text, accept full suggestion when at end
    $smartCtrlRight = {
        param($key, $arg)
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ForwardWord($key, $arg)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($key, $arg)
        }
    }

    if ($isFullTerminal) {
        # Standalone PowerShell window — list-style suggestions
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    } else {
        # VS Code / integrated terminal — inline ghost-text suggestions
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    }

    # Common key bindings (shared across all terminal types)
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab                 -ScriptBlock {
        param($key, $arg)
        if (-not (Get-Module posh-git)) {
            Import-Module posh-git -ErrorAction SilentlyContinue
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete($key, $arg)
    }
    Set-PSReadLineKeyHandler -Key UpArrow             -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow           -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key RightArrow          -ScriptBlock $smartRight
    Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -ScriptBlock $smartCtrlRight
    Set-PSReadLineKeyHandler -Chord "Ctrl+d"          -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord "Ctrl+f"          -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord "Ctrl+b"          -Function BackwardWord

    # ─── PSFzf (fuzzy finder — lazy-load on first Ctrl+R or Ctrl+T) ─────────
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        if (Get-Command fd -ErrorAction SilentlyContinue) {
            $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
            $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
        }
        Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
            if (-not (Get-Module PSFzf)) {
                Import-Module PSFzf -ErrorAction SilentlyContinue
                Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
            }
            Invoke-FzfPsReadlineHandlerHistory
        }
        Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
            if (-not (Get-Module PSFzf)) {
                Import-Module PSFzf -ErrorAction SilentlyContinue
                Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
            }
            Invoke-FzfPsReadlineHandlerProvider
        }
    }
}

# ─── NPM shortcuts ───────────────────────────────────────────────────────────
function nrd { npm run start:dev }
function nrb { npm run build }
function nrt { npm run test }

# ─── File operations ─────────────────────────────────────────────────────────
function ll {
    if (-not (Get-Module Terminal-Icons)) { Import-Module Terminal-Icons -ErrorAction SilentlyContinue }
    Get-ChildItem -Force
}
function la {
    if (-not (Get-Module Terminal-Icons)) { Import-Module Terminal-Icons -ErrorAction SilentlyContinue }
    Get-ChildItem -Force -Hidden
}
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# ─── Git shortcuts ────────────────────────────────────────────────────────────
function gs { git status }
function ga { git add . }
function gc { param([string]$message) git commit -m $message }
function gp { git push }
function gl { git pull }
function gd { git diff }

# ─── Navigation ──────────────────────────────────────────────────────────────
function home   { Set-Location $HOME }
function desk   { Set-Location "$HOME\Desktop" }

# ─── Kubernetes ──────────────────────────────────────────────────────────────
New-Alias -Name 'k' -Value 'kubectl' -Force

# ─── Help ────────────────────────────────────────────────────────────────────
function Show-MyCommands {
    Write-Host "`n=== Custom Commands ===" -ForegroundColor Cyan
    Write-Host "`nNPM Scripts:" -ForegroundColor Yellow
    Write-Host "  nrd / nrb / nrt"
    Write-Host "`nFile:" -ForegroundColor Yellow
    Write-Host "  ll / la / .. / ... / ...."
    Write-Host "`nGit:" -ForegroundColor Yellow
    Write-Host "  gs / ga / gc <msg> / gp / gl / gd"
    Write-Host "`nNavigation:" -ForegroundColor Yellow
    Write-Host "  home / desk"
    Write-Host "  z <partial>   — jump to frecent directory (zoxide)"
    Write-Host "  zi            — interactive fzf directory picker"
    Write-Host "`nFuzzy Search:" -ForegroundColor Yellow
    Write-Host "  Ctrl+r        — fuzzy history search (PSFzf)"
    Write-Host "  Ctrl+t        — fuzzy file/path picker (PSFzf)"
    Write-Host "`nKubernetes:" -ForegroundColor Yellow
    Write-Host "  k  — kubectl alias"
    Write-Host "`nIntelliSense (VS Code terminal):" -ForegroundColor Yellow
    Write-Host "  →           accept one word of suggestion"
    Write-Host "  Ctrl+→      accept full suggestion"
    Write-Host "  ↑ / ↓       search history"
    Write-Host ""
}

$env:EDITOR = "code"

# ─── Machine-local overrides (not in git) ────────────────────────────────────
$_localProfile = "$HOME\.config\powershell\local.ps1"
if (Test-Path $_localProfile) { . $_localProfile }

Set-Alias bash "C:\Program Files\Git\bin\bash.exe"
