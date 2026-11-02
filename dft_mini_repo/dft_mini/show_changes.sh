#!/bin/bash
# Show what each DFT step changed in the RTL. Run from the repo root after
# step 1 and/or step 2. Lists the Verilog Tessent wrote into the TSDB and diffs
# the original RTL against the modified RTL for each design_id.
set -u
echo "== generated Verilog in TSDB =="
find tsdb -name "*.v" 2>/dev/null | sort
for id in rtl1 rtl2; do
  d=$(find tsdb -type d -name "*${id}.dft_inserted_design" 2>/dev/null | head -1)
  [ -z "$d" ] && continue
  echo; echo "== diff original RTL vs $id ($d/modified_rtl_files) =="
  for f in "$d"/modified_rtl_files/*.v; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    if [ -f "rtl/$b" ]; then diff -u "rtl/$b" "$f"; else echo "--- new file: $b"; fi
  done
done
