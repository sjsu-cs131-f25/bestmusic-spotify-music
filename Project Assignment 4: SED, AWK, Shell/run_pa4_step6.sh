#!/bin/bash


set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
F="$ROOT/out/filtered.tsv"

mkdir -p "$ROOT/out"

echo "Starting Step 6: Signal Discovery..."
echo "Input: $F"
echo ""

# Check if input exists
if [[ ! -f "$F" ]]; then
    echo "Error: Input file $F not found. Run Step 3 first." >&2
    exit 1
fi

# ---- 1) Distribution profiles for numeric features ----
echo "1. Computing distribution profiles..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    popularity = $4 + 0
    energy = $5 + 0
    danceability = $6 + 0
    
    # Popularity stats
    pop_sum += popularity
    pop_sum_sq += popularity * popularity
    if (NR == 2 || popularity < pop_min) pop_min = popularity
    if (NR == 2 || popularity > pop_max) pop_max = popularity
    
    # Energy stats
    energy_sum += energy
    energy_sum_sq += energy * energy
    if (NR == 2 || energy < energy_min) energy_min = energy
    if (NR == 2 || energy > energy_max) energy_max = energy
    
    # Danceability stats
    dance_sum += danceability
    dance_sum_sq += danceability * danceability
    if (NR == 2 || danceability < dance_min) dance_min = danceability
    if (NR == 2 || danceability > dance_max) dance_max = danceability
    
    count++
}
END {
    # Calculate means
    pop_mean = pop_sum / count
    energy_mean = energy_sum / count
    dance_mean = dance_sum / count
    
    # Calculate standard deviations
    pop_std = sqrt((pop_sum_sq / count) - (pop_mean * pop_mean))
    energy_std = sqrt((energy_sum_sq / count) - (energy_mean * energy_mean))
    dance_std = sqrt((dance_sum_sq / count) - (dance_mean * dance_mean))
    
    printf "metric\tmean\tstd\tmin\tmax\n"
    printf "popularity\t%.2f\t%.2f\t%.2f\t%.2f\n", pop_mean, pop_std, pop_min, pop_max
    printf "energy\t%.4f\t%.4f\t%.4f\t%.4f\n", energy_mean, energy_std, energy_min, energy_max
    printf "danceability\t%.4f\t%.4f\t%.4f\t%.4f\n", dance_mean, dance_std, dance_min, dance_max
}' "$F" > "$ROOT/out/numerical_distributions.tsv"

echo ""
echo "Step 6 completed successfully!"
echo "[task6] wrote:"
echo " - $ROOT/out/numerical_distributions.tsv"
