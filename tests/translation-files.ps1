$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$buildScript = Get-Content -Raw -Path (Join-Path $root '.github/build-ipk.sh')
$rescanScript = Get-Content -Raw -Path (Join-Path $root '.github/rescan-translation.sh')

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

foreach ($path in @('po/zh_Hans/fluxproxy.po', 'po/templates/fluxproxy.pot')) {
	if (!(Test-Path (Join-Path $root $path))) {
		throw "Expected translation file to exist: $path"
	}
}

Assert-Match $buildScript 'po/zh_Hans/fluxproxy\.po' 'The build script should compile the renamed translation file.'
Assert-Match $buildScript 'fluxproxy\.zh-cn\.lmo' 'The build script should output the renamed LuCI translation catalog.'
Assert-Match $rescanScript 'po/templates/fluxproxy\.pot' 'The translation rescan script should write the renamed template.'

Write-Output 'translation file checks passed.'
