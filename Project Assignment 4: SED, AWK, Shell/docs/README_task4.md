

cat > docs/README_task4.md <<'EOF'
# PA4 – Task 4: Ratios, Buckets, and Per-Artist Summary (AWK)

**Goal:** From the Task-3 output (`out/filtered.tsv`), compute:
1) a ratio (Hip-Hop / Total),  
2) energy buckets (LOW/MID/HIGH),  
3) a per-artist summary with count/avg/min/max popularity.

## Inputs & Script
- **Input:** `out/filtered.tsv` (created by Task 3)
- **Script:** `scripts/task4_ratios_buckets_summary.sh`
> Bucketing uses a 0–1 feature in this order of preference: `energy` → `c4` → `c5`.

## How to Run
```bash
scripts/task4_ratios_buckets_summary.sh


Outputs (written to out/)
ratio_report.txt – Hip-Hop / Total ratio (divide-by-zero safe)

energy_buckets.tsv – counts for LOW / MID / HIGH

per_artist_summary.tsv – per-artist count, avg_pop, min_pop, max_pop



out/ratio_report.txt
Hip-Hop songs: 44 / Total: 560 = 0.0786



out/energy_buckets.tsv
bucket   count
LOW          55
MID         241
HIGH        264



Example (first few): out/per_artist_summary.tsv
artist                         	count	avg_pop	min_pop	max_pop
Powerman 5000                  	    1	63.00	63.00	63.00
Sum 41                         	    1	62.00	62.00	62.00
Beyoncé                        	    4	61.50	58.00	67.00
Future                         	    4	63.00	51.00	85.00
Drake                          	    3	62.33	61.00	63.00
...

