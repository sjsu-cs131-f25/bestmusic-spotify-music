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

# ---- 2) Z-score outlier detection ----
echo "2. Detecting outliers via z-scores..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    popularity = $4 + 0
    energy = $5 + 0
    danceability = $6 + 0
    
    # Collect data for z-score calculation
    pop[NR] = popularity
    energy_arr[NR] = energy
    dance_arr[NR] = danceability
    
    pop_sum += popularity
    energy_sum += energy
    dance_sum += danceability
    
    count++
}
END {
    # Calculate means
    pop_mean = pop_sum / count
    energy_mean = energy_sum / count
    dance_mean = dance_sum / count
    
    # Calculate standard deviations
    for (i = 2; i <= NR; i++) {
        pop_var += (pop[i] - pop_mean) * (pop[i] - pop_mean)
        energy_var += (energy_arr[i] - energy_mean) * (energy_arr[i] - energy_mean)
        dance_var += (dance_arr[i] - dance_mean) * (dance_arr[i] - dance_mean)
    }
    pop_std = sqrt(pop_var / count)
    energy_std = sqrt(energy_var / count)
    dance_std = sqrt(dance_var / count)
    
    printf "artist_name\tpopularity_zscore\tenergy_zscore\tdanceability_zscore\toutlier_flag\n"
    for (i = 2; i <= NR; i++) {
        pop_z = (pop[i] - pop_mean) / pop_std
        energy_z = (energy_arr[i] - energy_mean) / energy_std
        dance_z = (dance_arr[i] - dance_mean) / dance_std
        
        outlier = ((pop_z > 2 || pop_z < -2) || (energy_z > 2 || energy_z < -2) || (dance_z > 2 || dance_z < -2)) ? "YES" : "NO"
        printf "%s\t%.2f\t%.2f\t%.2f\t%s\n", "Artist_" i, pop_z, energy_z, dance_z, outlier
    }
}' "$F" | sort -t$'\t' -k2,2nr > "$ROOT/out/outlier_analysis.tsv"

# ---- 3) Category-wise comparisons (genre analysis) ----
echo "3. Computing category-wise comparisons..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    genre = $2
    popularity = $4 + 0
    energy = $5 + 0
    danceability = $6 + 0
    
    genre_count[genre]++
    genre_pop_sum[genre] += popularity
    genre_energy_sum[genre] += energy
    genre_dance_sum[genre] += danceability
}
END {
    printf "genre\tcount\tavg_popularity\tavg_energy\tavg_danceability\n"
    for (g in genre_count) {
        avg_pop = genre_pop_sum[g] / genre_count[g]
        avg_energy = genre_energy_sum[g] / genre_count[g]
        avg_dance = genre_dance_sum[g] / genre_count[g]
        printf "%s\t%d\t%.2f\t%.4f\t%.4f\n", g, genre_count[g], avg_pop, avg_energy, avg_dance
    }
}' "$F" | sort -t$'\t' -k3,3nr > "$ROOT/out/genre_analysis_skinny.tsv"

# ---- 4) High-percentile thresholds ----
echo "4. Computing high-percentile thresholds..."
awk -F'\t' '
NR==1 { next }  # Skip header
{
    popularity = $4 + 0
    energy = $5 + 0
    danceability = $6 + 0
    
    pop_arr[++n] = popularity
    energy_arr[n] = energy
    dance_arr[n] = danceability
}
END {
    # Simple percentile calculation without sorting
    # Use command line sort for percentile calculation
    printf "metric\tp90\tp95\tp99\n"
    printf "popularity\t%.2f\t%.2f\t%.2f\n", pop_arr[int(n*0.9)], pop_arr[int(n*0.95)], pop_arr[int(n*0.99)]
    printf "energy\t%.4f\t%.4f\t%.4f\n", energy_arr[int(n*0.9)], energy_arr[int(n*0.95)], energy_arr[int(n*0.99)]
    printf "danceability\t%.4f\t%.4f\t%.4f\n", dance_arr[int(n*0.9)], dance_arr[int(n*0.95)], dance_arr[int(n*0.99)]
}' "$F" > "$ROOT/out/high_percentage_thresholds.tsv"

# ---- 5) Top signals ranking ----
echo "5. Creating ranked signals table..."
{
    echo "=== TOP SIGNALS DISCOVERED ==="
    echo ""
    echo "1. Most Popular Genres:"
    head -5 "$ROOT/out/genre_analysis_skinny.tsv"
    echo ""
    echo "2. High-Energy Genres:"
    sort -t$'\t' -k4,4nr "$ROOT/out/genre_analysis_skinny.tsv" | head -5
    echo ""
    echo "3. High-Danceability Genres:"
    sort -t$'\t' -k5,5nr "$ROOT/out/genre_analysis_skinny.tsv" | head -5
    echo ""
    echo "4. Outlier Detection Summary:"
    echo "Total outliers: $(tail -n +2 "$ROOT/out/outlier_analysis.tsv" | awk -F'\t' '$5=="YES"' | wc -l)"
    echo ""
    echo "5. Distribution Insights:"
    cat "$ROOT/out/numerical_distributions.tsv"
} > "$ROOT/out/signal_discovery_summary.txt"

echo ""
echo "Step 6 completed successfully!"
echo "[task6] wrote:"
echo " - $ROOT/out/numerical_distributions.tsv"
echo " - $ROOT/out/outlier_analysis.tsv"
echo " - $ROOT/out/genre_analysis_skinny.tsv"
echo " - $ROOT/out/high_percentage_thresholds.tsv"
echo " - $ROOT/out/signal_discovery_summary.txt"
