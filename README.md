# PiAudacity

Automatyczny build **Audacity 4 Beta** pod **Raspberry Pi 5** — kompilowany w chmurze na GitHub Actions (natywny runner `ubuntu-24.04-arm`), zoptymalizowany pod **Cortex-A76**.

`/proc/cpuinfo` Cortex-A76 (RPi5): `fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp`. A76 **nie ma SVE** — `-mcpu=cortex-a76` pokrywa dokładnie wszystko, co procesor ma (ISA + strojenie w jednej fladze). GCC: `armv8.2-a` zawiera już `crc`/`lse`/`simd`, więc ręczne wyliczanie `+crc+simd+lse` jest zbędne.
