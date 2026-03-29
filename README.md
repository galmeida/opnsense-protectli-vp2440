# ixl-aspm-disable.sh

Protectli VP2440 + coreboot 0.9.0 / 0.9.1-rc3 + OPNsense 26.1.3.

Intel V710 interfaces on high traffic load may cause OPNsense to completely stop processing traffic on all interfaces. Console will still be responsive, and a reboot is required to restore connectivity. During shutdown the message below is printed four times. 

```
ixl0: ixl_del_hw_filters: i40e_aq_remove_macvlan status I40E_ERR_ADMIN_QUEUE_FULL, error OK
```

The issue seems to be caused by ASPM, but setting `hw.pci.enable_aspm` to 0 doesn't resolve the issue. `pciconf -lc` will still show ASPM enabled for ixl interfaces. 

The script will use pciconf to reset the interface's link control register (0xb0) bits 0 and 1, disabling ASPM. That fixed the issue for me.


## Installation

```sh
cp ixl-aspm-disable.sh /usr/local/etc/rc.syshook.d/early/99-ixl-aspm-disable.sh
chmod 755 /usr/local/etc/rc.syshook.d/early/99-ixl-aspm-disable.sh
sudo /usr/local/etc/rc.syshook.d/early/99-ixl-aspm-disable.sh
```

## Validation

After running the script you should see ASPM disabled in pciconf output:

```
$ sudo pciconf -lc pci0:1:0:0
ixl0@pci0:1:0:0:	class=0x020000 rev=0x02 hdr=0x00 vendor=0x8086 device=0x1572 subvendor=0x8086 subdevice=0x0000
    cap 01[40] = powerspec 3  supports D0 D3  current D0
    cap 05[50] = MSI supports 1 message, 64 bit, vector masks 
    cap 11[70] = MSI-X supports 129 messages, enabled
                 Table in map 0x1c[0x0], PBA in map 0x1c[0x1000]
    cap 10[a0] = PCI-Express 2 endpoint max data 256(2048) FLR RO
                 max read 512
---->            link x4(x4) speed 8.0(8.0) ASPM disabled(L1)    <----
    ecap 0001[100] = AER 2 0 fatal 0 non-fatal 2 corrected
    ecap 0003[140] = Serial 1 030525ffff666264
    ecap 000e[150] = ARI 1
    ecap 0010[160] = SR-IOV 1 IOV disabled, Memory Space disabled, ARI enabled
                     0 VFs configured out of 64 supported
                     First VF RID Offset 0x0010, VF RID Stride 0x0001
                     VF Device ID 0x154c
                     Page Sizes: 4096 (enabled), 8192, 65536, 262144, 1048576, 4194304
    ecap 0017[1a0] = TPH Requester 1
    ecap 000d[1b0] = ACS 1 Source Validation unavailable, Translation Blocking unavailable
                     P2P Req Redirect unavailable, P2P Cmpl Redirect unavailable
                     P2P Upstream Forwarding unavailable, P2P Egress Control unavailable
                     P2P Direct Translated unavailable, Enhanced Capability unavailable
    ecap 0019[1d0] = PCIe Sec 1 lane errors 0
```
    
## References

-  https://cdrdv2-public.intel.com/332464/332464_710_Series_Datasheet_v_4_1.pdf (see section 11.3.5.8)
