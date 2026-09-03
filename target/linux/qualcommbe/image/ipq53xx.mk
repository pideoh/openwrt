
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

define Build/be3600-pro-wrap-kernel-elf
	python3 $(TOPDIR)/target/linux/qualcommbe/image/be3600-pro-wrap-kernel-elf.py \
		$(TOPDIR)/target/linux/qualcommbe/image/be3600-pro-kernel-elf-header.bin \
		$@ $@.new
	mv $@.new $@
endef

define Device/xiaomi_be3600-pro
	$(call Device/FitImage)
	$(call Device/UbiFit)
	# The vendor bootloader's do_bootmiwifi requires the "kernel" UBI
	# volume to start with a small ELF wrapper (see be3600-pro-wrap-kernel-elf.py
	# for the full story) or it logs "It is not a elf image" and resets --
	# confirmed live via UART. Append the wrapping step to the plain FIT
	# pipeline Device/FitImage already set up.
	KERNEL += | be3600-pro-wrap-kernel-elf
	# The vendor bootloader's do_bootmiwifi looks up UBI volumes by name
	# ("kernel", static; "ubi_rootfs", dynamic) -- confirmed via a live
	# U-Boot dump of the vendor's own rootfs_1 volume table, which the
	# hardcoded lookup can't find in the default "kernel" (dynamic) /
	# "rootfs" (dynamic) layout scripts/ubinize-image.sh otherwise produces.
	UBI_KERNEL_STATIC := 1
	UBI_ROOTFS_VOLNAME := ubi_rootfs
	DEVICE_VENDOR := Xiaomi
	DEVICE_MODEL := BE3600 Pro
	SOC := ipq5332
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	# Winbond W25N01GWZEIG SPI NAND (128 MiB, SLC, erase 128 KiB, page 2048,
	# OOB 64), confirmed against a live vendor dmesg on real hardware.
	# rootfs/rootfs_1 in the vendor DT are 42 MiB each; keep the "kernel"
	# UBI volume (KERNEL_SIZE) inside that.
	KERNEL_SIZE := 8192k
	IMAGE_SIZE := 43008k
	NAND_SIZE := 128m
	SUPPORTED_DEVICES += xiaomi,be3600-pro
	DEVICE_PACKAGES := kmod-leds-pwm
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
	ARTIFACTS := initramfs-factory.ubi
	ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-uImage.itb | ubinize-kernel
endif
endef
TARGET_DEVICES += xiaomi_be3600-pro
