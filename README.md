# msiissucks 💜

> Потому что MSI Center под Linux нет, а фиолетовая подсветка нужна.

Bash-скрипт поверх [OpenRGB](https://openrgb.org), который включает, гасит и перекрашивает
подсветку **MSI Mystic Light** на материнской плате **и RGB-оперативке** — из терминала,
из интерактивного меню или прямо из панели [Noctalia Shell](https://noctalia.dev).
Плюс systemd-юнит, чтобы цвет включался сам при загрузке.

```console
$ msiissucks ON
Включено: #8B00FF (плата + память)
$ msiissucks ON 00FFD0
Включено: #00FFD0 (плата + память)
$ msiissucks OFF
Выключено.
```

## Возможности

- `ON` / `OFF` для всех найденных устройств сразу — плата + плашки памяти (ENE DRAM и т.п.)
- любой цвет; последний выбранный запоминается и включается при загрузке
- **TUI**: `msiissucks` без аргументов — меню со стрелками, палитрой и превью цвета
- **плагин Noctalia**: лампочка в баре цветом подсветки, плитка в центре управления
  и панель с палитрой и колор-пикером
- автопоиск устройств в `openrgb --list-devices` с кэшем индексов; кэш сам
  пересканируется, если индексы поменялись
- блокировка: TUI, бар и автозапуск не дерутся за OpenRGB
- systemd-юнит с ретраями: i2c-шина появляется не сразу после старта, юнит ждёт её

## Требования

- Linux с systemd
- [OpenRGB](https://openrgb.org) ≥ 0.9 (проверено на 1.0)
- модуль `i2c-dev` (пакет `openrgb` в Arch подгружает его сам)
- плата MSI с Mystic Light (проверено на **MSI B760 GAMING PLUS WIFI / MS-7D98**)
- для плагина — Noctalia ≥ 5 (plugin API 26)

## Установка

```bash
git clone https://github.com/SEVENinthem/msiissucks.git
cd msiissucks
./install.sh --service --noctalia
```

| Флаг          | Что ставит                                                          |
| ------------- | ------------------------------------------------------------------- |
| _(без флагов)_ | только скрипт в `~/.local/bin/msiissucks`                          |
| `--service`   | + юнит автозапуска `/etc/systemd/system/msiissucks.service` (sudo) |
| `--noctalia`  | + плагин Noctalia из `~/.local/share/msiissucks/noctalia`           |
| `--uninstall` | убирает всё обратно                                                 |

Убедись, что `~/.local/bin` есть в `PATH`.

## Использование

### Командная строка

| Команда                    | Что делает                                      |
| -------------------------- | ----------------------------------------------- |
| `msiissucks`               | интерактивное меню (в терминале)                |
| `msiissucks ON [RRGGBB]`   | включить; без цвета — последний выбранный       |
| `msiissucks OFF`           | выключить подсветку                             |
| `msiissucks STATUS`        | состояние, цвет и закэшированные устройства     |
| `msiissucks LIST`          | список устройств OpenRGB                        |
| `msiissucks RESCAN`        | сбросить кэш устройств                          |

Цвет выбирается так: аргумент → `MSIISSUCKS_COLOR` → последний выбранный → `8B00FF`.

### TUI

```
  msiissucks  ·  MSI Mystic Light

  Сейчас: вкл  ████  #8B00FF

  Что делаем?

   ▸ Включить
    Выключить
    Выбрать цвет…
    Устройства OpenRGB
    Выход

  ↑/↓ или j/k — выбор, Enter — ок, q — назад
```

В «Выбрать цвет…» — 10 пресетов с цветными плашками и ввод своего hex. Цвет применяется сразу.

### Noctalia Shell

После `./install.sh --noctalia`:

- **Виджет в баре** — Настройки → Панель → Добавить виджет → `msiissucks`.
  Лампочка горит текущим цветом. ЛКМ — вкл/выкл, ПКМ — панель с цветами.
- **Плитка** — Настройки → Центр управления → Ярлыки → `msiissucks`.
- **Панель** — палитра, переключатель и «Свой цвет…» (нативный колор-пикер Noctalia).

IPC, например для хоткея в niri:

```bash
noctalia msg plugin seveninthem/msiissucks:service all toggle
noctalia msg plugin seveninthem/msiissucks:service all on FF00FF
noctalia msg panel-toggle seveninthem/msiissucks:panel
```

Плагин сам ничего не делает с железом — он вызывает `msiissucks`, поэтому бар, TUI и
автозапуск всегда показывают одно и то же состояние.

> [!NOTE]
> `OFF` гасит подсветку до перезагрузки — при старте юнит снова включит последний цвет.

## Как это работает

1. `openrgb --list-devices` → ищутся строки, похожие на плату или RGB-память
   (`msi|mystic|motherboard|ene|dram|ddr|ram|spd|memory`).
2. Индексы кэшируются в `~/.local/state/msiissucks/device`, состояние и цвет — в `state` и `color`.
3. Для каждого устройства: `openrgb --device N --mode static --color RRGGBB`
   (для `OFF` — режим `off`, а если устройство его не знает — `static 000000`).

## Если что-то не работает

- **Устройства не найдены** → `sudo modprobe i2c-dev`, затем `msiissucks LIST`.
  Если плата есть в списке, но не подходит под регэксп — открой issue с выводом `LIST`.
- **Permission denied** → проверь udev-правила OpenRGB (`60-openrgb.rules`) или запусти через `sudo`.
- **Юнит висит в activating** → `journalctl -u msiissucks -b`.
- **Плагин пишет «msiissucks не найден»** → укажи путь к скрипту в настройках плагина.

## Лицензия

[MIT](LICENSE)
