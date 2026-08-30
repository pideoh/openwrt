Package/ath12k-firmware-wcn7850 = $(call Package/firmware-default,WCN7850 ath12k firmware)
define Package/ath12k-firmware-wcn7850/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath12k/WCN7850/hw2.0
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath12k/WCN7850/hw2.0/*.bin $(1)/lib/firmware/ath12k/WCN7850/hw2.0/
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath12k/WCN7850/hw2.0/*.txt $(1)/lib/firmware/ath12k/WCN7850/hw2.0/
endef
$(eval $(call BuildPackage,ath12k-firmware-wcn7850))

Package/ath12k-firmware-qcn9274 = $(call Package/firmware-default,QCN9274 ath12k firmware)
define Package/ath12k-firmware-qcn9274/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath12k/QCN9274/hw2.0
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath12k/QCN9274/hw2.0/* $(1)/lib/firmware/ath12k/QCN9274/hw2.0/
endef
$(eval $(call BuildPackage,ath12k-firmware-qcn9274))

Package/ath12k-firmware-ipq5332 = $(call Package/firmware-default,IPQ5332 ath12k firmware)
define Package/ath12k-firmware-ipq5332/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath12k/IPQ5332/hw1.0
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath12k/IPQ5332/hw1.0/* $(1)/lib/firmware/ath12k/IPQ5332/hw1.0/
endef
$(eval $(call BuildPackage,ath12k-firmware-ipq5332))

Package/ath12k-firmware-qcn6432 = $(call Package/firmware-default,QCN6432 ath12k firmware)
define Package/ath12k-firmware-qcn6432/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath12k/QCN6432/hw1.0
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath12k/QCN6432/hw1.0/* $(1)/lib/firmware/ath12k/QCN6432/hw1.0/
endef
$(eval $(call BuildPackage,ath12k-firmware-qcn6432))
