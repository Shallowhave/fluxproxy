$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$workflow = Get-Content -Raw -Path (Join-Path $root '.github/workflows/build-ipk.yml')
$buildScript = Get-Content -Raw -Path (Join-Path $root '.github/build-ipk.sh')
$readme = Get-Content -Raw -Path (Join-Path $root 'README')

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

Assert-Match $workflow 'OPKG_USIGN_SECRET_B64' 'Workflow should read the opkg usign private key from GitHub Secrets.'
Assert-Match $workflow 'OPKG_USIGN_PUBLIC_B64' 'Workflow should publish the opkg usign public key.'
Assert-Match $workflow 'APK_SIGN_KEY_B64' 'Workflow should read the apk private key from GitHub Secrets.'
Assert-Match $workflow 'APK_SIGN_PUBLIC_B64' 'Workflow should publish the apk public key.'
Assert-Match $workflow 'usign -S -m Packages -s "\$\{OPKG_USIGN_KEY\}"' 'Workflow should sign the opkg Packages index.'
Assert-Match $workflow 'opkg feed will remain unsigned' 'Workflow should warn when opkg signing secrets are missing.'
Assert-Match $workflow 'apk feed will remain unsigned' 'Workflow should warn when apk signing secrets are missing.'
Assert-Match $workflow 'fluxproxy-opkg\.pub' 'Workflow should publish the opkg public key.'
Assert-Match $workflow 'fluxproxy-apk\.pub' 'Workflow should publish the apk public key.'
Assert-Match $workflow 'apk \$\{APK_SIGN_KEY:\+\-\-sign-key "\$\{APK_SIGN_KEY\}"\} --allow-untrusted mkndx' 'Workflow should sign the APK v3 index when an apk key is configured.'
Assert-Match $buildScript 'APK_SIGN_KEY' 'APK package build should accept an APK signing key.'
Assert-Match $buildScript 'apk \$\{APK_SIGN_KEY:\+\-\-sign-key "\$\{APK_SIGN_KEY\}"\} mkpkg' 'APK package build should sign packages when an apk key is configured.'
Assert-Match $readme 'fluxproxy-opkg\.pub' 'README should explain installing the opkg feed public key.'
Assert-Match $readme 'fluxproxy-apk\.pub' 'README should explain installing the apk feed public key.'
Assert-NotMatch $readme '--allow-untrusted' 'Signed feed instructions should not require --allow-untrusted.'

Write-Output 'package signing checks passed.'
