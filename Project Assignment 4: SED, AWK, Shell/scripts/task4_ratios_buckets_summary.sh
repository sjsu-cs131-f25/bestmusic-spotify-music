

#!/usr/bin/env bash
# ============================================================
# Project Assignment 4 — Task 4: Ratios, Buckets, Per-entity (AWK)
# Inputs:  out/filtered.tsv (from Task 3)
# Outputs: out/ratio_report.txt, out/energy_buckets.tsv, out/per_artist_summary.tsv
# ============================================================

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="$ROOT/out/filtered.tsv"

mkdir -p "$ROOT/out"
# ---- 1) Ratio: Hip-Hop / Total (guard divide-by-zero) ----
awk -F'\t' '
NR==1{for(i=1;i<=NF;i++) h[tolower($i)]=i; next}
{tot++}
$(h["genre"])=="Hip-Hop"{num++}
END{
   ratio = (tot ? num/tot : 0);
     printf("Hip-Hop songs: %d / Total: %d = %.4f\n", num, tot, ratio);
     }' "$F" | tee "$ROOT/out/ratio_report.txt"

 # ---- 2) Buckets on a 0–1 feature: prefer energy, else c4, else c5 ----
    awk -F'\t' -v OFS='\t' '
    NR==1{
    for(i=1;i<=NF;i++) h[tolower($i)]=i
	fx = (h["energy"] ? h["energy"] : (h["c4"] ? h["c4"] : (h["c5"] ? h["c5"] : 0)))
	if(!fx){ print "ERROR: need energy or c4/c5 for buckets" > "/dev/stderr"; exit 1 }
	 next
 	}
	{
	   v = $(fx) + 0
	     b = (v <= 0.33) ? "LOW" : (v <= 0.66 ? "MID" : "HIGH")
	       buckets[b]++
       }
       END{
       printf("%-6s\t%8s\n","bucket","count")
       printf("%-6s\t%8d\n","LOW",  buckets["LOW"]+0)
       printf("%-6s\t%8d\n","MID",  buckets["MID"]+0)
       printf("%-6s\t%8d\n","HIGH", buckets["HIGH"]+0)
       }' "$F" > "$ROOT/out/energy_buckets.tsv"

   
 # ---- 3) Per-artist summary: count + avg(popularity) with printf ----	
	awk -F'\t' -v OFS='\t' '
	NR==1{
	for(i=1;i<=NF;i++) h[tolower($i)]=i
	if(!h["artist"] || !h["popularity"]){ print "ERROR: need artist and popularity" > "/dev/stderr"; exit 2 }
	next
	}
	{
		a = $(h["artist"])
		p = $(h["popularity"])+0
		cnt[a]++
		sum[a]+=p
		if (!(a in min) || p < min[a]) min[a]=p
		if (!(a in max) || p > max[a]) max[a]=p
	}
	END{
	  printf("%-30s\t%6s\t%8s\t%8s\t%8s\n","artist","count","avg_pop","min_pop","max_pop")
	  for(k in cnt){
	   avg = (cnt[k] ? sum[k]/cnt[k] : 0)
	       printf("%-30s\t%6d\t%8.2f\t%8.2f\t%8.2f\n", k, cnt[k], avg, min[k], max[k])
	   }
	}' "$F" | sort -k2,2nr > "$ROOT/out/per_artist_summary.tsv"


	echo "[task4] wrote:"
	echo " - $ROOT/out/ratio_report.txt"
	echo " - $ROOT/out/energy_buckets.tsv"
	echo " - $ROOT/out/per_artist_summary.tsv"


