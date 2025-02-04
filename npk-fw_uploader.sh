# v2.0
# делать на внешнем пк или контейнере где есть sshpass curl scp unzip
# проверяет версию через ssh затем скачивает main и распаковывает extra у себя и закачивает на микрот в указанную папку (для капсман) после чего подчищает у себя zip npk. Есть проверка на версию, не тратит трафик если версия не менялась.
# >npk-fw_uploader.sh
# chmod +x npk-fw_uploader.sh
#!/bin/bash
# Конфигурация
MIKROTIK_IP="192.168.10.1"   # IP-адрес MikroTik
MIKROTIK_USER="mk-upgrade"  # Имя пользователя MikroTik
MIKROTIK_PASSWORD="9rbj3k7gauvmyo" # Пароль пользователя MikroTik
MIKROTIK_TARGET_PATH="/usb1-part1/routerupgrade" # Путь на MikroTik
ARCHITECTURE=("arm" "mipsbe") # Архитектуры
CURRENT_DIR="/sharedfolders/raid5-8tb/mikrotik_fw" # Локальная директория

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

# Функция для проверки наличия файлов .npk в локальной директории
check_local_npk_files() {
    local arch=$1
    if [ ! -d "$CURRENT_DIR/$arch" ] || [ -z "$(ls -A "$CURRENT_DIR/$arch"/*.npk 2>/dev/null)" ]; then
        return 1
    fi
    return 0
}

# Получение текущей версии прошивки на MikroTik
MIKROTIK_VERSION=$(get_mikrotik_version)
if [ -z "$MIKROTIK_VERSION" ]; then
    echo "error: unable to retrieve version from MikroTik"
    exit 1
fi

echo "MikroTik version: $MIKROTIK_VERSION"

# Обновление для каждой архитектуры
for arch in "${ARCHITECTURE[@]}"; do
    # Создание папки для архитектуры
    ARCH_DIR="$CURRENT_DIR/$arch"
    mkdir -p "$ARCH_DIR"

    # Проверка наличия основного пакета (main package)
    MAIN_NPK_FILE="$ARCH_DIR/routeros-$MIKROTIK_VERSION-$arch.npk"
    if [ ! -f "$MAIN_NPK_FILE" ]; then
        MAIN_NPK_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/routeros-$MIKROTIK_VERSION-$arch.npk"
        echo "downloading main package from $MAIN_NPK_URL"
        curl -o "$MAIN_NPK_FILE" "$MAIN_NPK_URL"

        if [ $? -ne 0 ]; then
            echo "error: failed to download the main package for $arch"
            exit 1
        fi
    else
        echo "main package already exists: $MAIN_NPK_FILE"
    fi

    # Проверка наличия дополнительных пакетов (extra packages)
    if [ -z "$(ls -A "$ARCH_DIR"/*.npk 2>/dev/null)" ]; then
        EXTRA_ZIP_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/all_packages-$arch-$MIKROTIK_VERSION.zip"
        EXTRA_ZIP_FILE="$ARCH_DIR/all_packages-$arch-$MIKROTIK_VERSION.zip"

        echo "downloading extra packages from $EXTRA_ZIP_URL"
        curl -o "$EXTRA_ZIP_FILE" "$EXTRA_ZIP_URL"

        if [ $? -ne 0 ]; then
            echo "error: failed to download the extra packages for $arch"
            exit 1
        fi

        echo "unzipping extra packages to $ARCH_DIR"
        unzip -o "$EXTRA_ZIP_FILE" -d "$ARCH_DIR"

        if [ $? -ne 0 ]; then
            echo "error: failed to unzip the extra packages for $arch"
            exit 1
        fi
    else
        echo "extra packages already exist for $arch"
    fi

    # Загрузка основного пакета на MikroTik через FTP
    echo "uploading main package to MikroTik via FTP"
    upload_to_mikrotik_ftp "$MAIN_NPK_FILE"
    if [ $? -eq 0 ]; then
        echo "main package uploaded successfully: $MAIN_NPK_FILE"
    else
        echo "error: failed to upload main package for $arch"
    fi

    # Загрузка дополнительных пакетов на MikroTik через FTP
    echo "uploading npk files from extra packages to MikroTik via FTP"
    for file in "$ARCH_DIR"/*.npk; do
        if [ -f "$file" ]; then
            echo "uploading $file to MikroTik"
            upload_to_mikrotik_ftp "$file"
            if [ $? -eq 0 ]; then
                echo "upload successful: $file"
            else
                echo "error: failed to upload $file"
            fi
        fi
    done

    # Удаление старых версий файлов
    echo "cleaning up old versions..."
    find "$ARCH_DIR" -type f -name "*.npk" ! -name "*$MIKROTIK_VERSION*" -exec rm -f {} \;
    find "$ARCH_DIR" -type f -name "*.zip" ! -name "*$MIKROTIK_VERSION*" -exec rm -f {} \;

done

echo "update completed successfully"
