$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$clientView = Get-Content -Raw -Path (Join-Path $root 'htdocs/luci-static/resources/view/fluxproxy/client.js')
$serverView = Get-Content -Raw -Path (Join-Path $root 'htdocs/luci-static/resources/view/fluxproxy/server.js')

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

$url = 'http://www\.dayuip\.com/#/register\?invitation=memory&shareid=195'

Assert-Match $clientView $url 'Client page should link to the Dayu IP purchase page.'
Assert-Match $serverView $url 'Server page should link to the Dayu IP purchase page.'
Assert-Match $clientView "_\('Residential dedicated IP purchase'\)" 'Client page should display a descriptive translated IP purchase label.'
Assert-Match $serverView "_\('Residential dedicated IP purchase'\)" 'Server page should display a descriptive translated IP purchase label.'
Assert-NotMatch $clientView 'The modern ImmortalWrt proxy platform for ARM64/AMD64' 'Client page should no longer show the old platform description.'
Assert-NotMatch $serverView 'The modern ImmortalWrt proxy platform for ARM64/AMD64' 'Server page should no longer show the old platform description.'
Assert-Match $clientView "target: '_blank'" 'Client page should open the purchase link in a new tab.'
Assert-Match $serverView "rel: 'noopener noreferrer'" 'Server page should protect the external link.'

Write-Output 'Dayu IP link checks passed.'
