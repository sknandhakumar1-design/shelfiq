#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "=== Installing py7zr for 7z extraction ==="
pip3 install py7zr -q
echo "py7zr installed"

echo "=== Extracting 7z files ==="
python3 << 'PYEOF'
import py7zr, os, glob

raw_dir = "data/raw"
seven_z_files = glob.glob(os.path.join(raw_dir, "*.7z"))
print(f"Found {len(seven_z_files)} .7z files:")
for f in seven_z_files:
    size = os.path.getsize(f) / 1024 / 1024
    print(f"  {f}: {size:.1f} MB")

for archive_path in seven_z_files:
    out_name = os.path.basename(archive_path).replace('.7z', '')
    out_path = os.path.join(raw_dir, out_name)
    if os.path.exists(out_path):
        print(f"Skipping {archive_path} (already exists: {out_path})")
        continue
    print(f"\nExtracting {archive_path}...")
    with py7zr.SevenZipFile(archive_path, mode='r') as z:
        z.extractall(path=raw_dir)
    if os.path.exists(out_path):
        size = os.path.getsize(out_path) / 1024 / 1024
        print(f"Extracted: {out_path} ({size:.1f} MB)")
    else:
        # Check what files were created
        print(f"Looking for extracted files...")
        for f in os.listdir(raw_dir):
            if f not in [os.path.basename(a) for a in seven_z_files] and not f.endswith('.zip'):
                fp = os.path.join(raw_dir, f)
                size = os.path.getsize(fp) / 1024 / 1024
                print(f"  Created: {f} ({size:.1f} MB)")

print("\n=== All files in data/raw/ ===")
for f in sorted(os.listdir(raw_dir)):
    fp = os.path.join(raw_dir, f)
    size = os.path.getsize(fp) / 1024 / 1024
    print(f"  {f}: {size:.1f} MB")
PYEOF
echo "✓ STEP 4 COMPLETE"
