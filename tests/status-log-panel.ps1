$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$statusView = Get-Content -Raw -Path (Join-Path $root 'htdocs/luci-static/resources/view/homeproxy/status.js')

function Assert-Match {
	param(
		[string]$Text,
		[string]$Pattern,
		[string]$Message
	)

	if ($Text -notmatch $Pattern) {
		throw $Message
	}
}

Assert-Match $statusView 'parseLogLine' 'Status view should parse log lines into structured fields.'
Assert-Match $statusView 'renderLogRows' 'Status view should render structured log rows.'
Assert-Match $statusView 'renderLogPanel' 'Status view should expose a single switchable log panel.'
Assert-Match $statusView 'homeproxy-log-tabs' 'Log panel should provide tab-style log source switches.'
Assert-Match $statusView 'homeproxy-log-row' 'Log panel should render rows with a table-like layout.'
Assert-Match $statusView 'homeproxy-log-level' 'Log panel should render a colored level badge.'
Assert-Match $statusView 'activeLog' 'Log panel should track the selected log source.'
Assert-Match $statusView "HomeProxy log" 'Log panel should include the HomeProxy log tab.'
Assert-Match $statusView "sing-box client log" 'Log panel should include the sing-box client log tab.'
Assert-Match $statusView "sing-box server log" 'Log panel should include the sing-box server log tab.'

Write-Output 'status log panel source checks passed.'
