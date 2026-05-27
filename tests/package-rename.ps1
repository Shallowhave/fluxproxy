$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$makefile = Get-Content -Raw -Path (Join-Path $root 'Makefile')
$buildScript = Get-Content -Raw -Path (Join-Path $root '.github/build-ipk.sh')
$workflow = Get-Content -Raw -Path (Join-Path $root '.github/workflows/build-ipk.yml')
$readme = Get-Content -Raw -Path (Join-Path $root 'README')
$menuPath = Join-Path $root 'root/usr/share/luci/menu.d/luci-app-fluxproxy.json'
$aclPath = Join-Path $root 'root/usr/share/rpcd/acl.d/luci-app-fluxproxy.json'
$configPath = Join-Path $root 'root/etc/config/fluxproxy'
$initPath = Join-Path $root 'root/etc/init.d/fluxproxy'
$viewPath = Join-Path $root 'htdocs/luci-static/resources/view/fluxproxy/client.js'

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

Assert-Match $makefile 'PKG_NAME:=luci-app-fluxproxy' 'The package name should be luci-app-fluxproxy.'
Assert-Match $makefile 'CONFLICTS:=luci-app-homeproxy' 'The renamed package should conflict with luci-app-homeproxy.'
Assert-Match $buildScript 'Conflicts: luci-app-homeproxy' 'The generated ipk control file should conflict with luci-app-homeproxy.'
Assert-NotMatch $buildScript 'provider_priority' 'The apk metadata should not use unsupported provider_priority info fields.'
Assert-Match $readme 'https://shallowhave\.github\.io/fluxproxy/releases' 'README should use the renamed GitHub Pages package feed URL.'
Assert-NotMatch $readme 'https://shallowhave\.github\.io/homeproxy/releases' 'README should not use the old homeproxy package feed URL.'
Assert-Match $readme '/etc/apk/repositories' 'README should document the apk repository setup.'
Assert-Match $readme 'apk --allow-untrusted update' 'README should document updating an unsigned apk feed.'
Assert-Match $readme 'apk add --allow-untrusted luci-app-fluxproxy' 'README should document installing the apk package from the GitHub Pages feed.'
Assert-Match $buildScript 'origin:https://github\.com/Shallowhave/fluxproxy' 'The generated apk metadata should point to the fluxproxy upstream repository.'
Assert-Match $buildScript 'Source: https://github\.com/Shallowhave/fluxproxy' 'The generated ipk control file should point to the fluxproxy upstream repository.'
Assert-Match $buildScript '/etc/init\.d/rpcd restart' 'Package installation should restart rpcd so renamed ubus objects are loaded.'
Assert-Match $buildScript '/etc/init\.d/uhttpd restart' 'Package installation should restart uhttpd so LuCI uses fresh menu and module caches.'
Assert-Match $buildScript '\[ -n "\$\{IPKG_INSTROOT\}" \] \|\| \{\s+rm -f /tmp/luci-indexcache /tmp/luci-indexcache\.\*' 'APK post-install scripts should clear all LuCI index cache variants.'
Assert-Match $workflow 'luci-app-fluxproxy_\*\.\*' 'Release upload should match renamed fluxproxy packages.'
Assert-Match $readme 'opkg install luci-app-fluxproxy' 'README should install the renamed package.'
Assert-NotMatch $readme 'opkg install luci-app-homeproxy' 'README should not tell users to install the old package name.'
Assert-Match $makefile '/etc/config/fluxproxy' 'The package conffiles should use the renamed UCI config.'
Assert-Match $makefile '/etc/fluxproxy/' 'The package conffiles should use the renamed data directory.'
Assert-Match $buildScript '/etc/config/fluxproxy' 'The generated package should preserve the renamed UCI config.'
foreach ($path in @($menuPath, $aclPath, $configPath, $initPath, $viewPath)) {
	if (!(Test-Path $path)) {
		throw "Expected renamed file to exist: $path"
	}
}

Write-Output 'package rename checks passed.'
