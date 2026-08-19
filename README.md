# PiAudacity

Build **Audacity 4** (aarch64) pod **Raspberry Pi 5**. Kompilowany w chmurze przez GitHub Actions na natywnym runnerze `ubuntu-24.04-arm`, optymalizowany pod Cortex-A76 (`-mcpu=cortex-a76 -O3`). Wynik: AppImage w [Releases](https://github.com/olafeuken/PiAudacity/releases).

## Kompatybilność

- **Sprzęt:** Raspberry Pi 5 / CM5 / Pi 500 (Cortex-A76, ARMv8.2). Nie działa na Pi 4 i starszych (ARMv8.0).
- **System:** aarch64 z glibc ≥ 2.39 — Raspberry Pi OS (trixie), Debian trixie, Ubuntu 24.04+, Arch/Manjaro ARM.
- **Dźwięk:** ALSA, PulseAudio, PipeWire, JACK (przez PortAudio: ALSA + JACK).

## Instalacja

Pobierz `Audacity*.AppImage` z [Releases](https://github.com/olafeuken/PiAudacity/releases) i uruchom:

```bash
chmod +x Audacity*.AppImage
./Audacity*.AppImage
```

Albo użyj instalatora (pobiera najnowszy Release, instaluje do `~/.local/bin` i tworzy wpis w menu KDE):

```bash
curl -sL -o /tmp/install-on-pi.sh \
  https://raw.githubusercontent.com/olafeuken/PiAudacity/main/scripts/install-on-pi.sh
bash /tmp/install-on-pi.sh
```
