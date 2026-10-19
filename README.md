# msiissucks 💜

> Потому что MSI Center под Linux нет, а фиолетовая подсветка нужна.

Маленький bash-скрипт поверх [OpenRGB](https://openrgb.org), который одной командой включает
или гасит подсветку **MSI Mystic Light** на материнской плате **и RGB-оперативке**, плюс
systemd-юнит, чтобы цвет включался сам при загрузке.

```console
$ msiissucks ON
Включено: фиолетовый #8B00FF (плата + память)
$ msiissucks OFF
Выключено.
```

## Возможности

- `ON` / `OFF` для всех найденных устройств сразу — плата + плашки памяти (ENE DRAM и т.п.)
- свой цвет через переменную окружения `MSIISSUCKS_COLOR`
- автопоиск устройств в `openrgb --list-devices` с кэшем индексов; кэш сам сбрасывается и
  пересканируется, если индексы поменялись
- фолбэк на `sudo`, если нет прав на `/dev/i2c-*`
- systemd-юнит с ретраями: i2c-шина появляется не сразу после старта, юнит ждёт её

## Требования

- Linux с systemd
- [OpenRGB](https://openrgb.org) ≥ 0.9 (проверено на 1.0)
- модуль `i2c-dev` (пакет `openrgb` в Arch подгружает его сам)
- плата MSI с Mystic Light (проверено на **MSI B760 GAMING PLUS WIFI / MS-7D98**)

## Установка

```bash
git clone https://github.com/SEVENinthem/msiissucks.git
cd msiissucks
./install.sh --service   # без --service — только скрипт, без автозапуска
```

Скрипт ставится в `~/.local/bin/msiissucks`, юнит — в `/etc/systemd/system/msiissucks.service`.
Убедись, что `~/.local/bin` есть в `PATH`.

Удаление: `./install.sh --uninstall`.

## Использование

| Команда              | Что делает                                    |
| -------------------- | --------------------------------------------- |
| `msiissucks ON`      | включить цвет (по умолчанию `#8B00FF`)        |
| `msiissucks OFF`     | выключить подсветку                           |
| `msiissucks STATUS`  | последнее состояние и закэшированные устройства |
| `msiissucks LIST`    | список устройств OpenRGB                      |
| `msiissucks RESCAN`  | сбросить кэш устройств                        |

Другой цвет:

```bash
MSIISSUCKS_COLOR=FF00FF msiissucks ON
```

> [!NOTE]
> `OFF` гасит подсветку до перезагрузки — при старте юнит снова включит цвет.
> Чтобы цвет при загрузке был другим, добавь в юнит `Environment=MSIISSUCKS_COLOR=...`
> (`sudo systemctl edit msiissucks`).

## Как это работает

1. `openrgb --list-devices` → ищутся строки, похожие на плату или RGB-память
   (`msi|mystic|motherboard|ene|dram|ddr|ram|spd|memory`).
2. Индексы кэшируются в `~/.local/state/msiissucks/device`.
3. Для каждого устройства: `openrgb --device N --mode static --color RRGGBB`
   (для `OFF` — режим `off`, а если устройство его не знает — `static 000000`).

## Если что-то не работает

- **Устройства не найдены** → `sudo modprobe i2c-dev`, затем `msiissucks LIST`.
  Если плата есть в списке, но не подходит под регэксп — открой issue с выводом `LIST`.
- **Permission denied** → проверь udev-правила OpenRGB (`60-openrgb.rules`) или запусти через `sudo`.
- **Юнит висит в activating** → `journalctl -u msiissucks -b`.

## Лицензия

[MIT](LICENSE)
