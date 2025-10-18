# PA4 — Task 3: Quality Filters (AWK)
**Goal**  
Enforce business rules on the cleaned TSV before analysis. Always keep the header row and drop low-quality rows.

## Input
- `out/artist_popularity_skinny.tsv` (produced by Tasks 1–2)
## Business Rules
- Keep header with: `NR == 1 || (predicate)`
- Predicate keeps rows where:
  - `artist != ''` (non-empty key)
  - `popularity >= 40` (reasonable floor)
  -  row does **not** look like test/dummy/sample

## Repro (one command)
From repo root:
```bash
scripts/task3_quality_filters.sh

===Outputs===
out/filtered.tsv — filtered dataset for Task 4
logs/task3.log — summary of rows kept/dropped


logs/task3.log: 
[Task3] Total input rows :	950
[Task3] Rows kept        : 	560
[Task3] Rows dropped     :	390
[Task3] Wrote            : 	out/filtered.tsv


