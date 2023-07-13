#
# persistent-tty
#
include $(TOPDIR)/rules.mk

PKG_NAME:=persistent-tty
PKG_VERSION:=1.1
PKG_RELEASE:=1

PKG_MAINTAINER:=Edmunt Pienkowsky <roed@onet.eu>

include $(INCLUDE_DIR)/package.mk

define Package/persistent-tty
	PKGARCH:=all
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Persistent names for serial port devices
	URL:=http://github.com/RoEdAl/persistent-tty
endef

define Package/persistent-tty/description
  Persistent names for serial port devices (hotplug script).
endef

define Build/Compile
endef

define Package/persistent-tty/install
	$(INSTALL_DIR) $(1)/etc/hotplug.d/tty
	$(INSTALL_CONF) ./files/10-persistent-tty.sh $(1)/etc/hotplug.d/tty/10-persistent-tty
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/persistent-tty $(1)/etc/config
endef

define Package/persistent-tty/conffiles
/etc/config/persistent-tty
endef

$(eval $(call BuildPackage,persistent-tty))

