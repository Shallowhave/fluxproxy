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
Assert-Match $clientView "'require ui';" 'Client view should require LuCI ui before using ui helpers.'
Assert-Match $clientView "uci\.add\(data\[0\], 'node'" 'Importer should create proxy node sections.'
Assert-Match $clientView "uci\.add\(data\[0\], 'routing_node'" 'Importer should create routing node sections.'
Assert-Match $clientView "uci\.add\(data\[0\], 'routing_rule'" 'Importer should create routing rule sections.'
Assert-Match $clientView "let importedNodeSid = uci\.add\(data\[0\], 'node', nodeSid\)" 'Importer should keep the actual node section id returned by uci.add.'
Assert-Match $clientView "uci\.set\(data\[0\], importedRoutingNodeSid, 'node', importedNodeSid\)" 'Routing nodes should point at the actual imported proxy node id.'
Assert-Match $clientView "uci\.set\(data\[0\], importedRoutingRuleSid, 'outbound', importedRoutingNodeSid\)" 'Routing rules should point at the actual imported routing node id.'
Assert-Match $clientView "source_ip_cidr" 'Importer should assign LAN clients through source_ip_cidr.'
Assert-Match $clientView "socks_version', '5'" 'Imported SOCKS proxies should default to SOCKS5.'
Assert-Match $clientView 'Import SOCKS5 mappings' 'Client view should show an import button for SOCKS5 mappings.'
Assert-Match $clientView 'Clear existing imported mappings' 'Importer should offer an option to clear previous imported mappings.'
Assert-Match $clientView 'clearSocks5MappingImport' 'Importer should clear previous imported mappings before importing when requested.'
Assert-Match $clientView "startsWith\(namePrefix \+ '_node_'\)" 'Importer should only clear proxy node sections matching the selected prefix.'
Assert-Match $clientView "startsWith\(namePrefix \+ '_rnode_'\)" 'Importer should only clear routing node sections matching the selected prefix.'
Assert-Match $clientView "startsWith\(namePrefix \+ '_rule_'\)" 'Importer should only clear routing rule sections matching the selected prefix.'

Write-Output 'SOCKS5 mapping import source checks passed.'
