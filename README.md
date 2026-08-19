# PiAudacity

Automatyczny build **Audacity 4 Beta** pod **Raspberry Pi 5** — kompilowany w chmurze na GitHub Actions (natywny runner `ubuntu-24.04-arm`), zoptymalizowany pod **Cortex-A76**.

`/proc/cpuinfo` Cortex-A76 (RPi5): `fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp`. A76 **nie ma SVE** — `-mcpu=cortex-a76` pokrywa dokładnie wszystko, co procesor ma (ISA + strojenie w jednej fladze). GCC: `armv8.2-a` zawiera już `crc`/`lse`/`simd`, więc ręczne wyliczanie `+crc+simd+lse` jest zbędne.

## Build

Domyślnie budujemy **`master`** (najnowszy kod Audacity 4). Tag `Audacity-4.0.0-beta-2` **nie buduje się** — jego `SetupDependencies.cmake` pobiera zależności ze starych ścieżek `musescore/muse_deps/main` (np. `wxwidgets/3.1.3.9`), które po restrukturyzacji `muse_deps` zwracają **404** (`Unknown CMake command "wxwidgets_Populate"`). `master` używa nowego systemu `extdeps` (submoduł `muse_deps` + prebuilt dla aarch64) i jest CI-testowany na `ubuntu-24.04-arm`.

Uruchomienie: **Actions** → **„Audacity 4 Beta — build aarch64 (Raspberry Pi 5)"** → **Run workflow**. Po zakończeniu AppImage jest w draft Release / Artifacts. Na Pi instalujesz przez `piaudacity-install` (wpis w menu KDE).
