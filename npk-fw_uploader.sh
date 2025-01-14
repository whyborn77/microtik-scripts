# v1.0
# делать на внешнем пк или контейнере где есть sshpass curl scp unzip
# проверяет версию через ssh затем скачивает main и распаковывает extra у себя и закачивает на микрот в указанную папку (для капсман) после чего подчищает у себя zip npk. Есть проверка на версию, не тратит трафик если версия не менялась.
# >update_mikrotik.sh
# chmod +x update_mikrotik.sh
#!/bin/bash
MIKROTIK_IP="192.168.88.1"   
MIKROTIK_USER="admin"        
MIKROTIK_PASSWORD="password" 
MIKROTIK_TARGET_PATH="/sd1/caps"
ARCHITECTURE=("arm" "mipsbe")
CURRENT_DIR=$(pwd) # текущая директория
LOCAL_VERSION_FILE="$CURRENT_DIR/current_version.txt"

# функция для получения версии прошивки
get_mikrotik_version() {
    sshpass -p "$MIKROTIK_PASSWORD" ssh -o StrictHostKeyChecking=no "$MIKROTIK_USER@$MIKROTIK_IP" \
        '/system resource print' | grep -oP '(?<=version: )[\d.]+'
}

# функция для закачки файла на MikroTik
upload_to_mikrotik() {
    local file=$1
    sshpass -p "$MIKROTIK_PASSWORD" scp -o StrictHostKeyChecking=no "$file" \
        "$MIKROTIK_USER@$MIKROTIK_IP:$MIKROTIK_TARGET_PATH"
}

# проверка наличия файлов .npk в локальной директории
check_local_npk_files() {
    local arch=$1
    if [ ! -d "$CURRENT_DIR/$arch" ] || [ -z "$(ls -A "$CURRENT_DIR/$arch"/*.npk 2>/dev/null)" ]; then
        return 1
    fi
    return 0
}

# получение текущей версии прошивки на MikroTik
MIKROTIK_VERSION=$(get_mikrotik_version)
if [ -z "$MIKROTIK_VERSION" ]; then
    echo "error: unable to retrieve version from MikroTik"
    exit 1
fi

echo "MikroTik version: $MIKROTIK_VERSION"

# сохранение текущей версии в файл при запуске
if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE")
else
    LOCAL_VERSION=""
fi

echo "local version: $LOCAL_VERSION"

if [ "$MIKROTIK_VERSION" == "$LOCAL_VERSION" ]; then
    echo "version $MIKROTIK_VERSION is already installed. no update needed"
    exit 0
fi

echo "$MIKROTIK_VERSION" > "$LOCAL_VERSION_FILE"

echo "updated local version to: $MIKROTIK_VERSION"

for arch in "${ARCHITECTURE[@]}"; do
    # создание папки для архитектуры
    ARCH_DIR="$CURRENT_DIR/$arch"
    mkdir -p "$ARCH_DIR"

    # скачивание main package
    MAIN_NPK_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/routeros-$MIKROTIK_VERSION-$arch.npk"
    MAIN_NPK_FILE="$ARCH_DIR/routeros-$MIKROTIK_VERSION-$arch.npk"

    if [ ! -f "$MAIN_NPK_FILE" ]; then
        echo "downloading main package from $MAIN_NPK_URL"
        curl -o "$MAIN_NPK_FILE" "$MAIN_NPK_URL"

        if [ $? -ne 0 ]; then
            echo "error: failed to download the main package for $arch"
            exit 1
        fi
    else
        echo "main package already exists: $MAIN_NPK_FILE"
    fi

    EXTRA_ZIP_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/all_packages-$arch-$MIKROTIK_VERSION.zip"
    EXTRA_ZIP_FILE="$ARCH_DIR/all_packages-$arch-$MIKROTIK_VERSION.zip"

    if [ ! -f "$EXTRA_ZIP_FILE" ]; then
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
        echo "extra packages already downloaded and unzipped for $arch"
    fi

    # проверка наличия файлов .npk
    check_local_npk_files "$arch"
    if [ $? -ne 0 ]; then
        echo "no .npk files found for $arch. re-downloading extra packages."
        curl -o "$EXTRA_ZIP_FILE" "$EXTRA_ZIP_URL"
        unzip -o "$EXTRA_ZIP_FILE" -d "$ARCH_DIR"
    fi

    # закачка main package
    echo "uploading main package to MikroTik $MIKROTIK_TARGET_PATH"
    upload_to_mikrotik "$MAIN_NPK_FILE"
    if [ $? -eq 0 ]; then
        echo "main package uploaded successfully: $MAIN_NPK_FILE"
    else
        echo "error: failed to upload main package for $arch"
    fi

    # закачка npk файлов из extra packages
    echo "uploading npk files from extra packages to MikroTik $MIKROTIK_TARGET_PATH"
    for file in "$ARCH_DIR"/*.npk; do
        if [ -f "$file" ]; then
            echo "uploading $file to MikroTik"
            upload_to_mikrotik "$file"
            if [ $? -eq 0 ]; then
                echo "upload successful: $file"
                rm -f "$file"  # удаление файла после успешной отправки
            else
                echo "error: failed to upload $file"
            fi
        fi
    done

    # удаление zip архива
    echo "cleaning up..."
    rm -f "$EXTRA_ZIP_FILE"

done

# сохранение текущей версии в файл
echo "$MIKROTIK_VERSION" > "$LOCAL_VERSION_FILE"

echo "update completed successfully"
