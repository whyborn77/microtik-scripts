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
ARCHITECTURE="arm"
CURRENT_DIR=$(pwd) # текущая директория
LOCAL_VERSION_FILE="$CURRENT_DIR/current_version.txt"

# функция для получения версии прошивки
get_mikrotik_version() {
    sshpass -p "$MIKROTIK_PASSWORD" ssh -o StrictHostKeyChecking=no "$MIKROTIK_USER@$MIKROTIK_IP" \
        '/system resource print' | grep -oP '(?<=version: )[\d.]+'
}

# функция для закачки файла на mikroTik
upload_to_mikrotik() {
    local file=$1
    sshpass -p "$MIKROTIK_PASSWORD" scp -o StrictHostKeyChecking=no "$file" \
        "$MIKROTIK_USER@$MIKROTIK_IP:$MIKROTIK_TARGET_PATH"
}

# получение текущей версии прошивки на mikroTik
MIKROTIK_VERSION=$(get_mikrotik_version)
if [ -z "$MIKROTIK_VERSION" ]; then
    echo "error: unable to retrieve version from mikroTik"
    exit 1
fi

echo "mikroTik version: $MIKROTIK_VERSION"

# проверка локальной версии
if [ -f "$LOCAL_VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE")
else
    LOCAL_VERSION=""
fi

if [ "$MIKROTIK_VERSION" == "$LOCAL_VERSION" ]; then
    echo "version $MIKROTIK_VERSION is already installed. no update needed"
    exit 0
fi

# скачивание main package
MAIN_NPK_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/routeros-$ARCHITECTURE-$MIKROTIK_VERSION.npk"
MAIN_NPK_FILE="$CURRENT_DIR/routeros-$ARCHITECTURE-$MIKROTIK_VERSION.npk"

echo "downloading main package from $MAIN_NPK_URL"
curl -o "$MAIN_NPK_FILE" "$MAIN_NPK_URL"

if [ $? -ne 0 ]; then
    echo "error: failed to download the main package"
    exit 1
fi

EXTRA_ZIP_URL="https://download.mikrotik.com/routeros/$MIKROTIK_VERSION/all_packages-$ARCHITECTURE-$MIKROTIK_VERSION.zip"
EXTRA_ZIP_FILE="$CURRENT_DIR/all_packages-$ARCHITECTURE-$MIKROTIK_VERSION.zip"

echo "downloading extra packages from $EXTRA_ZIP_URL"
curl -o "$EXTRA_ZIP_FILE" "$EXTRA_ZIP_URL"

if [ $? -ne 0 ]; then
    echo "error: failed to download the extra packages"
    exit 1
fi

# распаковка extra packages
echo "unzipping extra packages to $CURRENT_DIR"
unzip -o "$EXTRA_ZIP_FILE" -d "$CURRENT_DIR"

if [ $? -ne 0 ]; then
    echo "error: failed to unzip the extra packages"
    exit 1
fi

# закачка main package
echo "uploading main package to mikroTik $MIKROTIK_TARGET_PATH"
upload_to_mikrotik "$MAIN_NPK_FILE"
if [ $? -eq 0 ]; then
    echo "main package uploaded successfully: $MAIN_NPK_FILE"
    rm -f "$MAIN_NPK_FILE"
else
    echo "error: failed to upload main package"
fi

# закачка npk файлов из extra packages
echo "uploading npk files from extra packages to mikroTik $MIKROTIK_TARGET_PATH"
for file in "$CURRENT_DIR"/*.npk; do
    if [ -f "$file" ]; then
        echo "uploading $file to mikroTik"
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

# сохранение текущей версии в файл
echo "$MIKROTIK_VERSION" > "$LOCAL_VERSION_FILE"

echo "update completed successfully"
