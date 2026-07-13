#!/usr/bin/env python3
"""Convert a UF2 file to Intel HEX (for adafruit-nrfutil serial DFU)."""
import struct
import sys

UF2_MAGIC_START0 = 0x0A324655
UF2_MAGIC_START1 = 0x9E5D5157
UF2_MAGIC_END = 0x0AB16F30
BLOCK_SIZE = 512


def hex_record(rectype, addr, data):
    length = len(data)
    rec = [length, (addr >> 8) & 0xFF, addr & 0xFF, rectype] + list(data)
    checksum = (-sum(rec)) & 0xFF
    return ":" + "".join(f"{b:02X}" for b in rec + [checksum])


def uf2_to_hex(uf2_path, hex_path):
    with open(uf2_path, "rb") as f:
        blob = f.read()

    lines = []
    upper = None
    for off in range(0, len(blob), BLOCK_SIZE):
        block = blob[off:off + BLOCK_SIZE]
        if len(block) < 32:
            break
        (m0, m1, flags, addr, size, blkno, numblk, fam) = struct.unpack(
            "<8I", block[:32])
        if m0 != UF2_MAGIC_START0 or m1 != UF2_MAGIC_START1:
            continue
        data = block[32:32 + size]
        pos = 0
        while pos < size:
            chunk = data[pos:pos + 16]
            a = addr + pos
            hi = (a >> 16) & 0xFFFF
            if hi != upper:
                upper = hi
                lines.append(hex_record(0x04, 0, [(hi >> 8) & 0xFF, hi & 0xFF]))
            lines.append(hex_record(0x00, a & 0xFFFF, chunk))
            pos += len(chunk)
    lines.append(hex_record(0x01, 0, []))

    with open(hex_path, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    uf2_to_hex(sys.argv[1], sys.argv[2])
    print(f"wrote {sys.argv[2]}")
