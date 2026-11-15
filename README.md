# Cartographer v4 Installer for QIDI Plus 4 (Firmware V2.1.1+ & QIDI Box)

This repository provides a ready-to-use configuration set and an automated installer script to run the **Cartographer v4** eddy current probe on the **QIDI Plus 4** running the latest **V2.1.1+** firmware without breaking **QIDI Box** multi-color support.

## Why This Is Needed
In firmware **V2.1.1+**, QIDI introduced closed-source binary modules for the QIDI Box (`box_detect.so`, etc.) compiled strictly for **Python 3.7**. 
* Upgrading Klipper to Python 3.12 (as recommended in older guides) crashes Klipper with `ImportError: undefined symbol: _Py_CheckRecursionLimit`.
* Running the stock Cartographer `install.sh` fails on Python 3.7 because it requires `scipy~=1.10` and `TypedDict` (Python 3.8+).

This installer keeps the stock **Python 3.7** environment intact, installs compatible binary wheels (`scipy==1.7.3`, `numpy<1.22`), patches `TypedDict` via `sitecustomize.py`, and merges Cartographer probing macros with the updated QIDI Box macros.

---

## Prerequisites
1. **Printer Firmware:** Your QIDI Plus 4 mainboard (SOC) and touchscreen (UI) must be updated to **V2.1.1** (or newer).
2. **Hardware Mounted:** Cartographer v4 supports USB out of the box—simply mount the probe to your toolhead and connect it to an available USB port on the printer.

---

## Quick Installation (1-Click Script)

### Step 1. Upload Files to the Printer
Copy the entire `QIDI_Plus4_V2.1.1_Carto` folder to your printer's home directory via `scp` from your computer:
```bash
scp -r QIDI_Plus4_V2.1.1_Carto mks@YOUR_PRINTER_IP:~/
```
*(Default SSH password is `makerbase`)*.

### Step 2. Run the Installer
Connect to your printer via SSH and execute the installation script:
```bash
ssh mks@YOUR_PRINTER_IP
bash ~/QIDI_Plus4_V2.1.1_Carto/install.sh
```

**What the script does automatically:**
1. Creates a full backup of your existing configs in `~/printer_data/config_backup_...`.
2. Clones `cartographer-klipper` from GitHub (skipping the incompatible stock installer).
3. Installs `numpy<1.22`, `scipy==1.7.3`, and `typing-extensions` into the stock Python 3.7 `klippy-env`.
4. Applies `sitecustomize.py` to backport `TypedDict` into Python 3.7.
5. Links `idm.py`, `cartographer.py`, and `scanner.py` into `~/klipper/klippy/extras/`.
6. Copies the pre-configured `printer.cfg`, `gcode_macro.cfg`, and `carto.cfg`, automatically detects your probe's USB serial ID, and restarts Klipper.

---

## Step 3. Initial Calibration
Once Klipper restarts and shows **Ready** in the Fluidd web interface (`http://YOUR_PRINTER_IP`):

1. **Calibrate Z-Offset (Nozzle Touch):**
   Open the Fluidd console and run:
   ```gcode
   CARTOGRAPHER_CALIBRATE
   ```
   Wait for the 3 nozzle touches and coil scan to finish, then save the profile:
   ```gcode
   SAVE_CONFIG
   ```

2. **Generate a Bed Mesh:**
   Heat the bed to your typical printing temperature (e.g., 60 °C for PLA), home all axes, scan the bed, and save:
   ```gcode
   M140 S60
   G28
   BED_MESH_CALIBRATE
   SAVE_CONFIG
   ```

Your QIDI Plus 4 is now fully calibrated and ready for both high-speed Cartographer scanning and plug-and-play **QIDI Box** printing!

---

## Included Files
* `install.sh` — Automated installation and configuration script.
* `carto.cfg` — Cartographer v4 MCU, scanner, bed mesh, and temperature sensor configuration.
* `printer.cfg` — Adapted V2.1.1 main configuration with stock inductive/piezo probes disabled.
* `gcode_macro.cfg` — Adapted homing (`G28`), `PRINT_START`, and `G29` macros preserving QIDI Box sensor logic (`CLEAR_MOTION_DATA SENSOR=box_motion_sensor`).
* `sitecustomize.py` — Python 3.7 compatibility patch for `typing.TypedDict`.
