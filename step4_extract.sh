#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "Files in data/raw:"
ls -lh data/raw/

echo "Extracting zip..."
python3 << 'PYEOF'
import zipfile, os

raw_dir = "data/raw"
files = os.listdir(raw_dir)
print(f"Files: {files}")

zips = [f for f in files if f.endswith('.zip')]
if not zips:
    print("No zip found!")
    exit(1)

zip_path = os.path.join(raw_dir, zips[0])
print(f"Extracting: {zip_path} ({os.path.getsize(zip_path)/1024/1024:.1f} MB)")

with zipfile.ZipFile(zip_path, 'r') as z:
    names = z.namelist()
    print(f"Files in zip ({len(names)}):")
    for name in names:
        info = z.getinfo(name)
        print(f"  {name}: {info.file_size/1024/1024:.1f} MB")
    print("Extracting all...")
    z.extractall(raw_dir)

print("\nExtracted files:")
for f in sorted(os.listdir(raw_dir)):
    fp = os.path.join(raw_dir, f)
    size = os.path.getsize(fp) / 1024 / 1024
    print(f"  {f}: {size:.1f} MB")
print("Done!")
PYEOF
echo "✓ STEP 4 COMPLETE"
