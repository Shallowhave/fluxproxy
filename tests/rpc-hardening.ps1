$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$rpc = Get-Content -Raw -Path (Join-Path $root 'root/usr/share/rpcd/ucode/luci.fluxproxy')

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

function Assert-NotMatch {
	param(
		[string]$Text,
		[string]$Pattern,
		[string]$Message
	)

	if ($Text -match $Pattern) {
		throw $Message
	}
}

Assert-Match $rpc "const resource_types = \['china_ip4', 'china_ip6', 'china_list', 'gfw_list'\]" 'RPC resource updates should be limited to known resource names.'
Assert-Match $rpc "if \(!\(req\.args\?\.type in resource_types\)\)" 'RPC resource updates should reject unknown resource names.'
Assert-Match $rpc "const params = req\.args\?\.params \? shellquote\(req\.args\.params\) : ''" 'sing-box generator params should be shell-quoted before command execution.'
Assert-NotMatch $rpc 'generate '' \+ type \+ ` \$\{req\.args\?\.params \|\| ''''\}`' 'sing-box generator should not concatenate raw params into a shell command.'

Write-Output 'RPC hardening checks passed.'
