
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

define Build/rn01-wrap-kernel-elf
	python3 $(TOPDIR)/target/linux/qualcommbe/image/rn01-wrap-kernel-elf.py \
		$(TOPDIR)/target/linux/qualcommbe/image/rn01-kernel-elf-header.bin \
		$@ $@.new
	mv $@.new $@
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
	# The vendor bootloader's do_bootmiwifi requires the "kernel" UBI
	# volume to start with a small ELF wrapper (see rn01-wrap-kernel-elf.py
	# for the full story) or it logs "It is not a elf image" and resets --
	# confirmed live via UART. Append the wrapping step to the plain FIT
	# pipeline Device/FitImage already set up.
	KERNEL += | rn01-wrap-kernel-elf
	# The vendor bootloader's do_bootmiwifi looks up UBI volumes by name
	# ("kernel", static; "ubi_rootfs", dynamic) -- confirmed via a live
	# U-Boot dump of the vendor's own rootfs_1 volume table, which do_bootmiwifi's
	# hardcoded volume lookup can't find in the default "kernel"
	# (dynamic) / "rootfs" (dynamic) layout scripts/ubinize-image.sh
	# otherwise produces.
	UBI_KERNEL_STATIC := 1
	UBI_ROOTFS_VOLNAME := ubi_rootfs
	DEVICE_VENDOR := Xiaomi
	DEVICE_MODEL := BE3600 Pro
	SOC := ipq5332
	# TODO: unlike ubnt_u7-pro-xgs (custom U-Boot, probes config-a6a4), RN01
	# ships Xiaomi's stock bootloader; leaving DEVICE_DTS_CONFIG unset picks
	# up Device/Default's "config@1" for now. Confirm what FIT config name,
	# if any, the stock RN01 U-Boot actually looks for.
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	# Confirmed against a live vendor dmesg on real hardware: the boot
	# storage is a Winbond W25N01GWZEIG SPI NAND (128 MiB, SLC, erase
	# size 128 KiB, page size 2048, OOB 64) -- matches these values
	# exactly, carried over from the same-family ipq50xx Xiaomi UBI
	# devices (xiaomi_ax6000 etc).
	# rootfs/rootfs_1 in the vendor DT are 0x2a00000 (42MiB) each; leave
	# headroom for the "kernel" UBI volume (KERNEL_SIZE) inside that.
	KERNEL_SIZE := 8192k
	IMAGE_SIZE := 43008k
	NAND_SIZE := 128m
	SUPPORTED_DEVICES += xiaomi,rn01
	# TODO: ath12k-firmware-ipq5332/-qcn6432 packages exist in
	# package/firmware/linux-firmware/qca_ath12k.mk but the linux-firmware
	# tarball this build pins (20260810) does not yet contain
	# ath12k/IPQ5332/hw1.0/* or ath12k/QCN6432/hw1.0/* (confirmed by a real
	# package/compile failure: "install: cannot stat
	# .../linux-firmware-20260810/ath12k/IPQ5332/hw1.0/*"). Those files exist
	# in the CodeLinaro ath12k-firmware staging mirror but haven't landed in
	# a released linux-firmware tarball yet. Re-add once either (a) a newer
	# linux-firmware release includes them, or (b) qca_ath12k.mk is given its
	# own PKG_SOURCE_URL pointing at the staging mirror instead of relying on
	# the shared linux-firmware source tree. Left out of DEVICE_PACKAGES for
	# now so Phase 1 (no-WiFi bring-up) can build; WiFi packaging is Phase 2
	# work anyway.
	DEVICE_PACKAGES := kmod-ath12k kmod-leds-pwm
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
