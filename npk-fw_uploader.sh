# v2.0
# делать на внешнем пк или контейнере где есть sshpass curl scp unzip
# проверяет версию через ssh затем скачивает main и распаковывает extra у себя и закачивает на микрот в указанную папку (для капсман) после чего подчищает у себя zip npk. Есть проверка на версию, не тратит трафик если версия не менялась.
# >npk-fw_uploader.sh
# chmod +x npk-fw_uploader.sh
#!/bin/bash
# Конфигурация
#!/bin/bash

# Конфигурация
MIKROTIK_IP=""   # IP-адрес MikroTik
MIKROTIK_USER=""        # Имя пользователя MikroTik
MIKROTIK_PASSWORD="" # Пароль пользователя MikroTik
MIKROTIK_TARGET_PATH="/sata3/caps"
ARCHITECTURE=("arm" "mipsbe") # Архитектуры
CURRENT_DIR= # Текущая директория
LOG_FILE="$CURRENT_DIR/update_log.txt" # Файл для логирования

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Функция для получения версии прошивки MikroTik
get_mikrotik_version() {
    sshpass -p "$MIKROTIK_PASSWORD" ssh -o StrictHostKeyChecking=no "$MIKROTIK_USER@$MIKROTIK_IP" \
        '/system resource print' | grep -oP '(?<=version: )[\d.]+'
}

# Функция для загрузки файла на MikroTik через FTP
upload_to_mikrotik_ftp() {
    local file=$1
    curl -T "$file" -u "$MIKROTIK_USER:$MIKROTIK_PASSWORD" "ftp://$MIKROTIK_IP$MIKROTIK_TARGET_PATH/"
}

# Получение текущей версии прошивки на MikroTik
MIKROTIK_VERSION=$(get_mikrotik_version)
if [ -z "$MIKROTIK_VERSION" ]; then
    log "error: unable to retrieve version from MikroTik"
    exit 1
fi

log "MikroTik version: $MIKROTIK_VERSION"

# Обновление для каждой архитектуры
for arch in "${ARCHITECTURE[@]}"; do
    ARCH_DIR="$CURRENT_DIR/$arch"
    mkdir -p "$ARCH_DIR"

    MAIN_NPK_FILE="$ARCH_DIR/routeros-$MIKROTIK_VERSION-$arch.npk"
    if [ ! -f "$MAIN_NPK_FILE" ]; then
        MAIN_NPK_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/routeros-$MIKROTIK_VERSION-$arch.npk"
        log "downloading main package from $MAIN_NPK_URL"
        curl -o "$MAIN_NPK_FILE" "$MAIN_NPK_URL"

        if [ $? -ne 0 ]; then
            log "error: failed to download the main package for $arch"
            exit 1
        fi
    else
        log "main package already exists: $MAIN_NPK_FILE"
    fi

    EXTRA_ZIP_FILE="$ARCH_DIR/all_packages-$arch-$MIKROTIK_VERSION.zip"
    if [ ! -f "$EXTRA_ZIP_FILE" ] || [ -z "$(ls -A "$ARCH_DIR"/*.npk 2>/dev/null)" ]; then
        EXTRA_ZIP_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/all_packages-$arch-$MIKROTIK_VERSION.zip"
        log "downloading extra packages from $EXTRA_ZIP_URL"
        curl -o "$EXTRA_ZIP_FILE" "$EXTRA_ZIP_URL"

        if [ $? -ne 0 ]; then
            log "error: failed to download the extra packages for $arch"
            exit 1
        fi

        log "unzipping extra packages to $ARCH_DIR"
        unzip -o "$EXTRA_ZIP_FILE" -d "$ARCH_DIR"

        if [ $? -ne 0 ]; then
            log "error: failed to unzip the extra packages for $arch"
            exit 1
        fi
    else
        log "extra packages already exist for $arch"
    fi

    log "uploading main package to MikroTik via FTP"
    upload_to_mikrotik_ftp "$MAIN_NPK_FILE"
    if [ $? -eq 0 ]; then
        log "main package uploaded successfully: $MAIN_NPK_FILE"
    else
        log "error: failed to upload main package for $arch"
    fi

    log "uploading npk files from extra packages to MikroTik via FTP"
    for file in "$ARCH_DIR"/*.npk; do
        if [ -f "$file" ]; then
            log "uploading $file to MikroTik"
            upload_to_mikrotik_ftp "$file"
            if [ $? -eq 0 ]; then
                log "upload successful: $file"
            else
                log "error: failed to upload $file"
            fi
        fi
    done

    log "cleaning up old versions..."
    find "$ARCH_DIR" -type f -name "*.npk" ! -name "*$MIKROTIK_VERSION*" -exec rm -f {} \;
    find "$ARCH_DIR" -type f -name "*.zip" ! -name "*$MIKROTIK_VERSION*" -exec rm -f {} \;

done

log "update completed successfully"
