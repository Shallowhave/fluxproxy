$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$buildScript = Get-Content -Raw -Path (Join-Path $root '.github/build-ipk.sh')
$rescanScript = Get-Content -Raw -Path (Join-Path $root '.github/rescan-translation.sh')
$zhCn = Get-Content -Raw -Path (Join-Path $root 'po/zh_Hans/fluxproxy.po')
$pot = Get-Content -Raw -Path (Join-Path $root 'po/templates/fluxproxy.pot')

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
Assert-Match $zhCn 'htdocs/luci-static/resources/view/fluxproxy/' 'The Chinese translation comments should reference renamed fluxproxy views.'
Assert-Match $pot 'htdocs/luci-static/resources/view/fluxproxy/' 'The translation template comments should reference renamed fluxproxy views.'
Assert-Match $zhCn '/etc/fluxproxy/certs/' 'The Chinese translation text should reference the renamed fluxproxy config directory.'
Assert-Match $pot '/etc/fluxproxy/certs/' 'The translation template text should reference the renamed fluxproxy config directory.'
Assert-Match $zhCn 'root/usr/share/luci/menu.d/luci-app-fluxproxy\.json' 'The Chinese translation comments should reference the renamed menu file.'
Assert-Match $pot 'root/usr/share/luci/menu.d/luci-app-fluxproxy\.json' 'The translation template comments should reference the renamed menu file.'
Assert-Match $zhCn 'root/usr/share/rpcd/acl.d/luci-app-fluxproxy\.json' 'The Chinese translation comments should reference the renamed ACL file.'
Assert-Match $pot 'root/usr/share/rpcd/acl.d/luci-app-fluxproxy\.json' 'The translation template comments should reference the renamed ACL file.'

Write-Output 'translation file checks passed.'
