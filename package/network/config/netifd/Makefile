include $(TOPDIR)/rules.mk

PKG_NAME:=netifd
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=$(PROJECT_GIT)/project/netifd.git
PKG_SOURCE_DATE:=2026-04-23
PKG_SOURCE_VERSION:=e45b890fa532bb89380b78008c2cc70bfad2c4c7
PKG_MIRROR_HASH:=bf318b9905ca2a63a8bb834d356bef3eec031acc843ba0137495708090894f75
PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=

PKG_BUILD_FLAGS:=lto
PKG_CONFIG_DEPENDS:=CONFIG_NETIFD_DEVLINK_PORT_SPLIT

USE_SOURCE_DIR:=$(TOPDIR)/../netifd

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/netifd
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+libuci +libnl-tiny +libubus +ubus +ubusd +jshn +libubox +libudebug \
	+ucode +ucode-mod-fs +ucode-mod-ubus +ucode-mod-uloop +ucode-mod-uci
  TITLE:=OpenWrt Network Interface Configuration Daemon
endef

define Package/netifd/config
	config NETIFD_DEVLINK_PORT_SPLIT
		bool "Enable devlink port split support"
		default n
		help
		  Enable support for configuring devlink port splitting from UCI
		  device sections using option split. This is only useful on the
		  small set of NIC/switch drivers that implement devlink port split.
endef

define Package/netifd/conffiles
/etc/udhcpc.user
/etc/udhcpc.user.d/
endef

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include/libnl-tiny \
	-I$(STAGING_DIR)/usr/include

CMAKE_OPTIONS += \
	-DLIBNL_LIBS=-lnl-tiny \
	-DDEBUG=1 \
	-DDEVLINK_PORT_SPLIT=$(if $(CONFIG_NETIFD_DEVLINK_PORT_SPLIT),ON,OFF)

define Package/netifd/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/netifd $(1)/sbin/
	$(CP) ./files/* $(1)/
	$(INSTALL_DIR) $(1)/etc/udhcpc.user.d/
	$(CP) \
		$(PKG_BUILD_DIR)/scripts/utils.sh \
		$(PKG_BUILD_DIR)/scripts/netifd-proto.sh \
		$(1)/lib/netifd/
endef

$(eval $(call BuildPackage,netifd))
