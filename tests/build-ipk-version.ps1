$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$script = Get-Content -Raw -Path (Join-Path $root '.github/build-ipk.sh')

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

Assert-Match $script 'GITHUB_REF_NAME' 'Release builds should derive a package version from the GitHub release tag when PKG_VERSION is not defined.'
Assert-Match $script 'PKG_VERSION="\$\{PKG_VERSION#v\}"' 'Release tag versions should drop a leading v for package manager compatibility.'
Assert-Match $script 'PKG_VERSION="\$PKG_SOURCE_DATE_EPOCH~\$\(git rev-parse --short HEAD\)"' 'The script should keep the existing snapshot version fallback.'

Write-Output 'build-ipk release version source checks passed.'
