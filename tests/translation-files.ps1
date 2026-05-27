$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$buildScript = Get-Content -Raw -Path (Join-Path $root '.github/build-ipk.sh')
$rescanScript = Get-Content -Raw -Path (Join-Path $root '.github/rescan-translation.sh')
$zhCn = Get-Content -Raw -Encoding UTF8 -Path (Join-Path $root 'po/zh_Hans/fluxproxy.po')
$pot = Get-Content -Raw -Encoding UTF8 -Path (Join-Path $root 'po/templates/fluxproxy.pot')

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

function ConvertFrom-Codepoint {
	param([int[]]$Codepoints)

	return -join ($Codepoints | ForEach-Object { [char]$_ })
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
Assert-Match $zhCn (ConvertFrom-Codepoint @(0x5ba2, 0x6237, 0x7aef, 0x8bbe, 0x7f6e)) 'The Chinese translation catalog should keep readable UTF-8 Chinese text.'
Assert-Match $zhCn (ConvertFrom-Codepoint @(0x8def, 0x7531, 0x8bbe, 0x7f6e)) 'The Chinese translation catalog should keep readable UTF-8 Chinese tab labels.'
Assert-Match $zhCn (ConvertFrom-Codepoint @(0x5bb6, 0x5ead, 0x4f4f, 0x5b85, 0x20, 0x49, 0x50, 0xff0c, 0x72ec, 0x4eab, 0x7ebf, 0x8def, 0xff0c, 0x70b9, 0x51fb, 0x8d2d, 0x4e70)) 'The Dayu IP purchase translation should stay readable UTF-8 Chinese.'
$zhCnBytes = [System.IO.File]::ReadAllBytes((Join-Path $root 'po/zh_Hans/fluxproxy.po'))
for ($i = 0; $i -lt ($zhCnBytes.Length - 2); $i++) {
	if ($zhCnBytes[$i] -eq 0xef -and $zhCnBytes[$i + 1] -eq 0xbf -and $zhCnBytes[$i + 2] -eq 0xbd) {
		throw 'The Chinese translation catalog should not contain UTF-8 replacement characters from an encoding rewrite.'
	}
}

Write-Output 'translation file checks passed.'
