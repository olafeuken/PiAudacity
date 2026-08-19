# PiAudacity

Automatyczny build **Audacity 4 Beta** pod **Raspberry Pi 5** — kompilowany w chmurze na GitHub Actions (natywny runner `ubuntu-24.04-arm`), zoptymalizowany pod **Cortex-A76**.

> ⚠️ **Nic nie kompiluje się na malince.** RPi5 jest wyłącznie urządzeniem docelowym: pobierasz gotowy AppImage z GitHub i uruchamiasz.

## Jak uruchomić build

1. Wejdź na https://github.com/olafeuken/PiAudacity → zakładka **Actions**
2. Wybierz workflow **„Audacity 4 Beta — build aarch64 (Raspberry Pi 5)"** → **Run workflow**
3. Ustaw parametry (domyślne są OK):
   - **audacity_ref**: `Audacity-4.0.0-beta-2` (najnowsza publiczna beta) — możesz wpisać `master` lub inny tag/commit
   - **build_mode**: `nightly_build` / `testing_build` / `stable_build`
   - **lto**: `off` (na start — gwarantowany poprawny build; `on` daje odrobinę wydajności, ale link trwa dłużej i bywa zawodny)
   - **create_release**: `true` (utworzy draft Release z AppImage)
4. Po skończeniu: gotowy plik `.AppImage` znajdziesz w **Release (draft)** lub w **Artifacts** bieżącego runu.

## Co jest optymalizowane

| Element | Ustawienie |
|---|---|
| CPU | `-mcpu=cortex-a76` (armv8.2-a + crc + lse + fp16 + dotprod + rcpc + tuning A76) |
| Poziom opt. | `-O3` (pełna wektoryzacja — DSP/FFT/efekty) |
| OpenMP | `-fopenmp` — równoległy render spektrogramu (`#ifdef _OPENMP` w źródłach Audacity) |
| Dodatkowo | `-fomit-frame-pointer -pipe`, ccache, unity build, Ninja |
| LTO (opcjonalnie) | `-flto` + `gcc-ar`/`gcc-ranlib` — włącz przez input `lto=on` |
| Page size | 4K — domyślny kernel RPi OS, **nie wymaga żadnych flag** (ELF `max-page-size` = 64K działa pod 4K/16K/64K) |

Świadomie **nie** używamy: `-march=native` (niedeterministyczne w CI), `-ffast-math`/`-Ofast` (łamie IEEE — niebezpieczne dla audio).

## Instalacja na Raspberry Pi

Pobierz `.AppImage` z Release i:

```bash
chmod +x Audacity*.AppImage
./Audacity*.AppImage                      # lub: --appimage-extract-and-run
```

Możesz też użyć helpera (pobiera najnowszy Release, instaluje do `~/.local` i tworzy wpis w menu KDE):

```bash
bash scripts/install-on-pi.sh
```

## Dlaczego to działa bezbłędnie na arm64

- **Natywny runner arm64** (`ubuntu-24.04-arm`) — GA, darmowy dla repo publicznych. Żadnego qemu/cross-compile.
- **Wzorzec 1:1 z oficjalnego CI Audacity**: `ci_configure.cmake` → `ci_build.cmake` → `package.cmake` (produkuje aarch64 AppImage — oficjalny pipeline buduje tak samo na `ubuntu-24.04-arm`).
- **Obejście pułapki**: oficjalny `buildscripts/ci/linux/setup.sh` pobiera cmake/ninja **x86_64-only** (zepsute na arm64). Nasz workflow pomija go i instaluje wszystko z **apt** (natywne arm64: cmake 3.28+, ninja, gcc).
- **Qt 6.10.1** dla aarch64 instalowany prebuilternie (`host: linux_arm64`, `arch: linux_gcc_arm64`).
- `qemu-user-static` doinstalowany — `make_appimage.sh` używa go przy ekstrakcji narzędzi AppImage dla `aarch64`.

## Flagi procesora — uzasadnienie (badanie)

`/proc/cpuinfo` Cortex-A76 (RPi5): `fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp`. A76 **nie ma SVE** — `-mcpu=cortex-a76` pokrywa dokładnie wszystko, co procesor ma (ISA + strojenie w jednej fladze). GCC: `armv8.2-a` zawiera już `crc`/`lse`/`simd`, więc ręczne wyliczanie `+crc+simd+lse` jest zbędne.
