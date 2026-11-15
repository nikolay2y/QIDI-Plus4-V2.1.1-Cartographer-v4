#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
CONFIG_DIR="$HOME/printer_data/config"
KLIPPER_DIR="$HOME/klipper"
KENV_DIR="$HOME/klippy-env"
CARTO_REPO="$HOME/cartographer-klipper"

echo "=========================================================="
echo " Cartographer v4 Installer for QIDI Plus 4 (V2.1.1+ / Box)"
echo "=========================================================="

# 1. Backup existing configuration
BACKUP_DIR="$HOME/printer_data/config_backup_$(date +%Y%m%d_%H%M%S)"
echo "[1/6] Creating backup of current configs in $BACKUP_DIR..."
cp -r "$CONFIG_DIR" "$BACKUP_DIR"

# 2. Clone Cartographer repository (skipping stock install.sh)
echo "[2/6] Downloading Cartographer plugin..."
if [ -d "$CARTO_REPO" ]; then
    echo "      Repository already exists, updating..."
    git -C "$CARTO_REPO" pull
else
    git clone https://github.com "$CARTO_REPO"
fi

# 3. Install Python 3.7 compatible dependencies & TypedDict patch
echo "[3/6] Installing Python 3.7 compatible dependencies (scipy==1.7.3, numpy, typing-extensions)..."
if [ -x "$KENV_DIR/bin/pip" ]; then
    "$KENV_DIR/bin/pip" install "numpy<1.22" "scipy==1.7.3" typing-extensions
else
    "$HOME/moonraker-env/bin/pip" --python "$KENV_DIR/bin/python" install "numpy<1.22" "scipy==1.7.3" typing-extensions
fi

SITE_PKGS=$("$KENV_DIR/bin/python" -c "import site; print(site.getsitepackages()[0])")
echo "      Applying TypedDict patch to $SITE_PKGS/sitecustomize.py..."
cp "$SCRIPT_DIR/sitecustomize.py" "$SITE_PKGS/sitecustomize.py"

# 4. Link Cartographer modules into Klipper
echo "[4/6] Linking Cartographer modules into Klipper..."
for file in idm.py cartographer.py scanner.py; do
    rm -f "$KLIPPER_DIR/klippy/extras/${file}"
    ln -s "$CARTO_REPO/${file}" "$KLIPPER_DIR/klippy/extras/${file}"
done

# 5. Copy pre-configured files & auto-detect USB probe ID
echo "[5/6] Copying V2.1.1+ configs and detecting Cartographer USB ID..."
cp "$SCRIPT_DIR/carto.cfg" "$CONFIG_DIR/carto.cfg"
cp "$SCRIPT_DIR/printer.cfg" "$CONFIG_DIR/printer.cfg"
cp "$SCRIPT_DIR/gcode_macro.cfg" "$CONFIG_DIR/gcode_macro.cfg"

CARTO_DEV=$(ls /dev/serial/by-id/*Cartographer* 2>/dev/null | head -n 1 || true)
if [ -n "$CARTO_DEV" ]; then
    echo "      Found probe: $CARTO_DEV"
    sed -i "s|serial:.*|serial: $CARTO_DEV|" "$CONFIG_DIR/carto.cfg"
else
    echo "      WARNING: Cartographer probe not detected via USB!"
    echo "      Please update 'serial:' in $CONFIG_DIR/carto.cfg manually after plugging it in."
fi

# 6. Restart Klipper
echo "[6/6] Restarting Klipper service..."
sudo systemctl restart klipper

echo "=========================================================="
echo " Installation complete!"
echo " Next steps in Fluidd console:"
echo "   1. Run CARTOGRAPHER_CALIBRATE and SAVE_CONFIG"
echo "   2. Heat bed (M140 S60), run G28, BED_MESH_CALIBRATE, SAVE_CONFIG"
echo "=========================================================="
