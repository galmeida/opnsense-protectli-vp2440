#!/bin/sh
#
# ixl-aspm-disable.sh — disable ASPM and Clock PM on all Intel X710 PCIe ports
#
#  bit 0 — ASPM L0s Enable
#  bit 1 — ASPM L1 Enable
#   
#  https://cdrdv2-public.intel.com/332464/332464_710_Series_Datasheet_v_4_1.pdf
#  see section 11.3.5.8 / p 1635
#
#   cp ixl-aspm-disable.sh /usr/local/etc/rc.syshook.d/early/99-ixl-aspm-disable.sh
#   chmod 755 /usr/local/etc/rc.syshook.d/start/99-ixl-aspm-disable.sh
#

MATCH_VENDOR='0x8086'
MATCH_DEVICE='0x1572'
MATCH_SUBVENDOR='0x8086'
MATCH_SUBDEVICE='0x0000'

CAP_ADDRESS='0xb0'
BITS_TO_CLEAR=$(( (1<<0) | (1<<1) ))

PCICONF='/usr/sbin/pciconf'

$PCICONF -l | while read line; do
    echo "$line" | grep -q "vendor=${MATCH_VENDOR}"    || continue
    echo "$line" | grep -q "device=${MATCH_DEVICE}"    || continue
    echo "$line" | grep -q "subvendor=${MATCH_SUBVENDOR}" || continue
    echo "$line" | grep -q "subdevice=${MATCH_SUBDEVICE}" || continue

    dev=$(echo "$line" | cut -f2 -d@ | cut -f-4 -d:)

    cur=$($PCICONF -r "$dev" $CAP_ADDRESS)
    cur=$(( $cur | 0 )) # remove spaces
    new=$(( $cur & ~$BITS_TO_CLEAR ))

    if [ "$cur" -eq "$new" ]; then
        logger -t ixl-aspm-disable "${dev}: already clear at $CAP_ADDRESS (0x$(printf '%08x' $cur)) — no change"
        continue
    fi

    $PCICONF -w "$dev" $CAP_ADDRESS "$new"
    logger -t ixl-aspm-disable "${dev}: cleared ASPM/ClockPM at ${lc_off}: 0x$(printf '%08x' $cur) -> 0x$(printf '%08x' $new)"
done
