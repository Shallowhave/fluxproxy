$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$workflow = Get-Content -Raw -Path (Join-Path $root '.github/workflows/build-ipk.yml')

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

Assert-Match $workflow 'ipkg-make-index\.sh' 'The workflow should use OpenWrt ipkg-make-index.sh instead of an unavailable apt package.'
Assert-Match $workflow 'raw\.githubusercontent\.com/openwrt/openwrt/master/scripts/ipkg-make-index\.sh' 'The workflow should download the package index script from OpenWrt.'
Assert-Match $workflow 'MKHASH=mkhash ipkg-make-index\.sh \. > Packages' 'The workflow should generate an opkg Packages index with OpenWrt ipkg-make-index.sh.'
Assert-Match $workflow 'gzip -9.*Packages' 'The workflow should generate Packages.gz for opkg clients.'
Assert-Match $workflow 'cp \.github/\*\.apk repo/releases/' 'The workflow should publish apk packages into the GitHub Pages package feed.'
Assert-Match $workflow 'apk --allow-untrusted mkndx' 'The workflow should use apk mkndx for apk v3 packages.'
Assert-Match $workflow '--output Packages\.adb' 'The workflow should generate a v3 Packages.adb index for apk clients.'
Assert-Match $workflow '--pkgname-spec' 'The workflow should make apk index entries point at the generated package filenames.'
Assert-Match $workflow '\$\{name\}_\$\{version\}_\$\{arch\}\.apk' 'The workflow should use the apk package filename format generated from package metadata.'
Assert-Match $workflow 'peaceiris/actions-gh-pages@v4' 'The workflow should deploy the package feed to GitHub Pages.'
Assert-Match $workflow 'publish_dir: ./repo' 'The GitHub Pages deploy step should publish the generated repo directory.'

Write-Output 'opkg feed workflow checks passed.'
