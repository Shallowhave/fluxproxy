$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$clientView = Get-Content -Raw -Path (Join-Path $root 'htdocs/luci-static/resources/view/homeproxy/client.js')

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

Assert-Match $clientView 'parseSocks5MappingLine' 'Client view should parse host|port|username|password|expire SOCKS5 mapping lines.'
Assert-Match $clientView 'nextIPv4Address' 'Client view should allocate client IP addresses sequentially.'
Assert-Match $clientView 'handleSocks5MappingImport' 'Client view should expose a SOCKS5 mapping import handler.'
Assert-Match $clientView "uci\.add\(data\[0\], 'node'" 'Importer should create proxy node sections.'
Assert-Match $clientView "uci\.add\(data\[0\], 'routing_node'" 'Importer should create routing node sections.'
Assert-Match $clientView "uci\.add\(data\[0\], 'routing_rule'" 'Importer should create routing rule sections.'
Assert-Match $clientView "source_ip_cidr" 'Importer should assign LAN clients through source_ip_cidr.'
Assert-Match $clientView "socks_version', '5'" 'Imported SOCKS proxies should default to SOCKS5.'
Assert-Match $clientView 'Import SOCKS5 mappings' 'Client view should show an import button for SOCKS5 mappings.'

Write-Output 'SOCKS5 mapping import source checks passed.'
