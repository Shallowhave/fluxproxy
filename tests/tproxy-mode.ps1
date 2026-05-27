$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$clientView = Get-Content -Raw -Path (Join-Path $root 'htdocs/luci-static/resources/view/fluxproxy/client.js')
$clientGen = Get-Content -Raw -Path (Join-Path $root 'root/etc/fluxproxy/scripts/generate_client.uc')
$firewall = Get-Content -Raw -Path (Join-Path $root 'root/etc/fluxproxy/scripts/firewall_post.ut')
$init = Get-Content -Raw -Path (Join-Path $root 'root/etc/init.d/fluxproxy')

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

Assert-Match $clientView "o\.value\('tproxy', _\('TProxy TCP/UDP'\)\)" 'Client UI should expose the full TProxy mode.'
Assert-Match $clientGen "match\(proxy_mode, /tproxy/\)" 'Client generator should use valid match(proxy_mode, /tproxy/) syntax.'
Assert-Match $clientGen "proxy_mode === 'tproxy' \|\| main_udp_node !== 'nil' \|\| routing_mode === 'custom'" 'Full TProxy should enable the tproxy inbound even when the dedicated UDP node is disabled.'
Assert-Match $clientGen "network:\s*\(proxy_mode === 'tproxy'\) \? null : 'udp'" 'Full TProxy should leave the tproxy inbound network unset so sing-box handles TCP and UDP.'
Assert-Match $firewall "const tproxy_l4proto = \(proxy_mode === 'tproxy'\) \? 'tcp, udp' : 'udp'" 'Firewall template should derive the TProxy protocol set from proxy_mode.'
Assert-Match $firewall "meta l4proto \{ \{\{ tproxy_l4proto \}\} \} meta mark set \{\{ tproxy_mark \}\} tproxy ip to 127\.0\.0\.1:\{\{ tproxy_port \}\}" 'Firewall template should tproxy all selected protocols in full TProxy mode.'
Assert-Match $firewall "th dport != @fluxproxy_routing_port counter return" 'TProxy port filtering should work for TCP and UDP.'
Assert-Match $init '"redirect_tproxy"\|"tproxy"\)' 'Init script should install policy routing for both mixed and full TProxy modes.'

Write-Output 'Full TProxy mode source checks passed.'
