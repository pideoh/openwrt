PART_NAME=firmware
REQUIRE_IMAGE_METADATA=1
RAMFS_COPY_BIN='fitblk fit_check_sign fw_printenv fw_setenv head seq'
RAMFS_COPY_DATA='/etc/fw_env.config /var/lock/fw_printenv.lock'

# Wipe the "rootfs" UBI (kernel + rootfs volumes together, per
# Device/UbiFit's KERNEL_IN_UBI) when booted from initramfs, mirroring the
# xiaomi_initramfs_prepare() helper used by the qualcommax xiaomi,ax6000
# family -- RN01 has no separate ubi_kernel partition, so there's only the
# one MTD partition to reformat.
xiaomi_rn01_initramfs_prepare() {
	[ "$(rootfs_type)" = "tmpfs" ] || return 0

	local rootfs_mtdnum="$( find_mtd_index rootfs )"
	if [ ! "$rootfs_mtdnum" ]; then
		echo "unable to find mtd partition rootfs"
		return 1
	fi

	ubidetach -m "$rootfs_mtdnum"
	ubiformat /dev/mtd$rootfs_mtdnum -y
}

platform_pre_upgrade() {
	case "$(board_name)" in
	xiaomi,rn01)
		xiaomi_rn01_initramfs_prepare
		;;
	esac
}

platform_do_upgrade() {
	case "$(board_name)" in
	ubnt,u7-pro-xgs)
		CI_KERNPART="kernel0"
		fit_do_upgrade "$1"
		;;
	xiaomi,rn01)
		# Make sure UART is enabled, matching the qualcommax
		# xiaomi,ax6000/xiaomi,ax3600/xiaomi,ax9000/redmi,ax6 devices
		# (same vendor U-Boot lineage).
		fw_setenv boot_wait on
		fw_setenv uart_en 1

		# TODO: the vendor DT gives RN01 two raw NAND banks, "rootfs" and
		# "rootfs_1", which looks like real A/B firmware support -- but
		# none of the existing qualcommax xiaomi,ax* devices (which use
		# this same flag_boot_rootfs/flag_try_sysN_failed env scheme)
		# actually implement bank switching in nand_do_upgrade; they all
		# just pin flag_boot_rootfs to 0 and always reflash bank 0. Follow
		# that same known-safe "single partition" precedent here rather
		# than guessing at untested A/B switching logic -- revisit once
		# we understand how the RN01 bootloader picks a bank.
		fw_setenv flag_boot_rootfs 0
		fw_setenv flag_last_success 0
		fw_setenv flag_boot_success 1
		fw_setenv flag_try_sys1_failed 8
		fw_setenv flag_try_sys2_failed 8

		# Unlike xiaomi,ax6000 (separate "ubi_kernel" + "rootfs" MTD
		# partitions), RN01 has no ubi_kernel partition: kernel and
		# rootfs share one UBI (KERNEL_IN_UBI, see Device/xiaomi_rn01),
		# living inside the single "rootfs" MTD partition.
		CI_UBIPART="rootfs"
		nand_do_upgrade "$1"
		;;
	*)
		echo "Sysupgrade is not supported on your board yet."
		return 1
		;;
	esac
}

platform_check_image() {
	[ "$#" -gt 1 ] && return 1

	case "$(board_name)" in
	ubnt,u7-pro-xgs)
		fit_check_image "$1"
		;;
	xiaomi,rn01)
		return 0
		;;
	*)
		echo "Sysupgrade is not supported on your board yet."
		return 1
		;;
	esac
}

platform_copy_config() {
	case "$(board_name)" in
	ubnt,u7-pro-xgs)
		emmc_copy_config
		;;
	esac
	# xiaomi,rn01 needs no entry here: it's a plain NAND/UBI device with
	# its config in the ubifs overlay, same as the qualcommax xiaomi,ax6000
	# family (which also has no platform_copy_config case).
}
