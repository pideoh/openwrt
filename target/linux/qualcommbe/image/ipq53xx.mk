
define Build/fit-inline-rootfs
	rm -f $@.dtb $@.kernel
	cp $@ $@.kernel
	cp $(word 2,$(1)) $@.dtb
	cp $@.kernel $@
	$(call Build/fit-its,$(word 1,$(1)) $@.dtb with-rootfs)
	$(call Build/fit-image,$(word 1,$(1)) $@.dtb with-rootfs)
	rootfs_offset="$$(grep -oba hsqs $@ | head -n1 | cut -d: -f1)"; \
	[ -n "$$rootfs_offset" ] || { echo "Failed to locate SquashFS in $@"; exit 1; }; \
	pad="$$(( (4096 - ($$rootfs_offset % 4096)) % 4096 ))"; \
	cp $(word 2,$(1)) $@.dtb; \
	dd if=/dev/zero bs=1 count="$$pad" >> $@.dtb 2>/dev/null; \
	cp $@.kernel $@; \
	$(call Build/fit-its,$(word 1,$(1)) $@.dtb with-rootfs)
	$(call Build/fit-image,$(word 1,$(1)) $@.dtb with-rootfs)
	rm -f $@.dtb $@.kernel
endef

define Device/ubnt_u7-pro-xgs
	DEVICE_VENDOR := Ubiquiti
	DEVICE_MODEL := UniFi 7
	DEVICE_VARIANT := Pro XGS
	# Stock U-Boot probes config-a6a4 on this board.
	DEVICE_DTS_CONFIG := config-a6a4
	SOC := ipq5332
	SUPPORTED_DEVICES += ubnt,u7-pro-xgs
	DEVICE_PACKAGES := e2fsprogs f2fsck fitblk mkf2fs \
		kmod-ath12k ath12k-firmware-qcn9274 \
		ipq-wifi-ubnt_u7-pro-xgs kmod-leds-pwm \
		kmod-phy-realtek rtl826x-firmware
	KERNEL := kernel-bin | lzma
	KERNEL_INITRAMFS := kernel-bin | lzma | \
		fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
	KERNEL_INITRAMFS_SUFFIX := .itb
	IMAGE_SIZE := 128m
	IMAGES := sysupgrade.itb
	IMAGE/sysupgrade.itb := append-kernel | \
		fit-inline-rootfs lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb | \
		check-size | append-metadata
endef
TARGET_DEVICES += ubnt_u7-pro-xgs

define Device/xiaomi_rn01
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := Xiaomi
	DEVICE_MODEL := BE3600 Pro
	SOC := ipq5332
	# TODO: unlike ubnt_u7-pro-xgs (custom U-Boot, probes config-a6a4), RN01
	# ships Xiaomi's stock bootloader; leaving DEVICE_DTS_CONFIG unset picks
	# up Device/Default's "config@1" for now. Confirm what FIT config name,
	# if any, the stock RN01 U-Boot actually looks for.
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	# TODO: page/block size above are carried over from the same-family
	# ipq50xx Xiaomi UBI devices (xiaomi_ax6000 etc); the vendor DT's
	# nand@79b0000 node gives ECC params (nand-ecc-strength/step-size) but
	# not page/block geometry directly -- confirm against the real NAND part.
	# rootfs/rootfs_1 in the vendor DT are 0x2a00000 (42MiB) each; leave
	# headroom for the "kernel" UBI volume (KERNEL_SIZE) inside that.
	KERNEL_SIZE := 8192k
	IMAGE_SIZE := 43008k
	NAND_SIZE := 128m
	SUPPORTED_DEVICES += xiaomi,rn01
	DEVICE_PACKAGES := kmod-ath12k ath12k-firmware-ipq5332 ath12k-firmware-qcn6432 kmod-leds-pwm
	# The vendor DT shows two active radios: wifi@c0000000
	# (qcom,cnss-qca5332 / qcom,ipq5332-wifi, on-chip AHB) and wifi4@f00000
	# (qcom,cnss-qcn6432, multipd userpd1). Per ATH12K_HW_IPQ5332_HW10
	# (fw.dir "IPQ5332/hw1.0"), each on-chip radio needs its own ath12k
	# board/cal data; ath12k-firmware-ipq5332 and ath12k-firmware-qcn6432
	# above ship the generic upstream board-2.bin for each. Still TODO: an
	# ipq-wifi-xiaomi_rn01 board-data package with device-specific
	# calibration, once another engineer has created it.
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
	ARTIFACTS := initramfs-factory.ubi
	ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-uImage.itb | ubinize-kernel
endif
endef
TARGET_DEVICES += xiaomi_rn01
