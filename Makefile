# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2022-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

LUCI_TITLE:=The modern ImmortalWrt proxy platform for ARM64/AMD64
LUCI_PKGARCH:=all
LUCI_DEPENDS:= \
	+sing-box \
	+firewall4 \
	+kmod-nft-tproxy \
	+ucode-mod-digest
PKG_NAME:=luci-app-fluxproxy

define Package/luci-app-fluxproxy
  CONFLICTS:=luci-app-homeproxy
endef

define Package/luci-app-fluxproxy/conffiles
/etc/config/fluxproxy
/etc/fluxproxy/certs/
/etc/fluxproxy/ruleset/
/etc/fluxproxy/resources/direct_list.txt
/etc/fluxproxy/resources/proxy_list.txt
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
