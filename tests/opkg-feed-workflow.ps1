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

Assert-Match $workflow 'opkg-utils' 'The workflow should install opkg-utils so opkg-make-index is available.'
Assert-Match $workflow 'opkg-make-index \. > Packages' 'The workflow should generate an opkg Packages index.'
Assert-Match $workflow 'gzip -9.*Packages' 'The workflow should generate Packages.gz for opkg clients.'
Assert-Match $workflow 'peaceiris/actions-gh-pages@v4' 'The workflow should deploy the package feed to GitHub Pages.'
Assert-Match $workflow 'publish_dir: ./repo' 'The GitHub Pages deploy step should publish the generated repo directory.'

Write-Output 'opkg feed workflow checks passed.'
