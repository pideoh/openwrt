#!/usr/bin/env python3
#
# RN01's vendor bootloader (do_bootmiwifi) requires the "kernel" UBI volume
# to start with a small ELF wrapper -- a fixed 12288-byte header/metadata
# region (ELF32 header + 3 program headers, the last a PT_LOAD entry
# pointing past the header to the real payload) followed by the actual FIT
# image. Without it the bootloader logs "It is not a elf image" and resets.
# be3600-pro-kernel-elf-header.bin is that exact 12288-byte prefix, dumped
# byte-for-byte from the vendor's own working "kernel" UBI volume (via a
# live U-Boot/UART session) -- everything in it is unchanged and untouched
# except the PT_LOAD segment's p_filesz/p_memsz fields (offset 0x84/0x88),
# which this script patches to match the actual FIT image size being
# wrapped. The purpose of the header's other content (an apparently
# auxiliary metadata table around offset 0x1000, trailing off into blank
# NAND before the 0x3000 payload offset) is not understood -- it is not
# known whether it is content-independent boilerplate or something that
# would need regenerating for a genuinely different board/vendor build.
import struct
import sys

HEADER_SIZE = 12288
PT_LOAD_FILESZ_OFFSET = 0x84
PT_LOAD_MEMSZ_OFFSET = 0x88

header_path, fit_path, out_path = sys.argv[1:4]

with open(header_path, "rb") as f:
    header = bytearray(f.read())
assert len(header) == HEADER_SIZE, f"header template must be {HEADER_SIZE} bytes"

with open(fit_path, "rb") as f:
    fit_data = f.read()

size_bytes = struct.pack("<I", len(fit_data))
header[PT_LOAD_FILESZ_OFFSET:PT_LOAD_FILESZ_OFFSET + 4] = size_bytes
header[PT_LOAD_MEMSZ_OFFSET:PT_LOAD_MEMSZ_OFFSET + 4] = size_bytes

with open(out_path, "wb") as f:
    f.write(header)
    f.write(fit_data)
