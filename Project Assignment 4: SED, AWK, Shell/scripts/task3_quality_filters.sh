#!/usr/bin/env bash
# ============================================================
# Project Assignment 4 — Task 3: Quality Filters (AWK)
# Enforce business rules; keep header (NR==1 || predicate);
# write filtered TSV to out/.
# Repo-root paths are resolved automatically.
# ============================================================
set -euo pipefail

# ---- Resolve repo root (directory above this script) ----
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---- Paths (now absolute) ----
DEFAULT_INPUT="$ROOT/out/artist_popularity_skinny.tsv"
INPUT_TSV="${INPUT_TSV:-$DEFAULT_INPUT}"
OUTPUT_TSV="${OUTPUT_TSV:-$ROOT/out/filtered.tsv}"
LOG_FILE="${LOG_FILE:-$ROOT/logs/task3.log}"

# ---- Business rules ----
MIN_POP="${MIN_POP:-40}"

mkdir -p "$(dirname "$OUTPUT_TSV")" "$(dirname "$LOG_FILE")"

echo "[Task3] Input : $INPUT_TSV"
echo "[Task3] Output: $OUTPUT_TSV"
echo "[Task3] Rules : artist != '', popularity >= $MIN_POP, drop test/dummy/sample"
echo "----------------------------------------------------------"

# ---- Ensure we have an input TSV ----
if [[ ! -s "$INPUT_TSV" ]]; then
	  # Fall back to newest TSV under repo out/
	    if ls "$ROOT"/out/*.tsv >/dev/null 2>&1; then
		        INPUT_TSV="$(ls -1t "$ROOT"/out/*.tsv | head -1)"
			    echo "[Task3] Default input not found; using newest TSV: $INPUT_TSV"
	else
	  echo "[ERROR] No TSVs found in $ROOT/out/. Run your PA4 pipeline first (./run_pa4.sh)." >&2
	      exit 1
		  fi
	  fi

# ---- AWK quality filter ----
# If header has "artist" and "popularity": NR==1 || keep
# Else assume: col1=artist, col3=popularity; synthesize header, then filter.
awk -F'\t' -v OFS='\t' -v min_pop="$MIN_POP" '
  BEGIN {
      IGNORECASE=1
          have_named_header = 0
	      printed_header = 0
	        }
	NR==1 {
	    for (i=1;i<=NF;i++) name[$i]=i
		        if ( ("artist" in name) && ("popularity" in name) )
	 {      
	      	 have_named_header=1
		      artist_idx=name["artist"]
			  pop_idx=name["popularity"]
		} else {
		      artist_idx=1
		            pop_idx=(NF>=3 ? 3 : 2)
			          header=""
		for (i=1;i<=NF;i++){
		 if (i==artist_idx)      h="artist"
		else if (i==pop_idx)    h="popularity"
		else if (i==2)          h="genre"
		else                  h="c"i
		header = (i==1 ? h : header OFS h)
		      }
		         print header
			   printed_header=1
			  }
		  }
	
	{
		    a = $artist_idx
		    p = $pop_idx + 0
		    req_ok   = (a != "" && $pop_idx != "")
		    pop_ok   = (p >= min_pop)
		    test_hit = (a ~ /(test|dummy|sample)/)
		    keep = (req_ok && pop_ok && !test_hit)

		    if (have_named_header) {
			if (NR==1 || keep) print $0
			} else {
			if (keep) print $0
			}
		    }
		    ' "$INPUT_TSV" > "$OUTPUT_TSV"

	# ---- Stats ----
	total_rows=0; kept_rows=0
	if [[ -s "$INPUT_TSV" ]]; then total_rows=$(( $(wc -l < "$INPUT_TSV") - 1 )); fi
	if [[ -s "$OUTPUT_TSV" ]]; then kept_rows=$(( $(wc -l < "$OUTPUT_TSV") - 1 )); fi
	dropped=$(( total_rows - kept_rows ))
	{
	echo "[Task3] Total input rows : $total_rows"
	echo "[Task3] Rows kept        : $kept_rows"
	echo "[Task3] Rows dropped     : $dropped"
	echo "[Task3] Wrote            : $OUTPUT_TSV"
	} | tee "$LOG_FILE"
	echo "[Task3] Done"
