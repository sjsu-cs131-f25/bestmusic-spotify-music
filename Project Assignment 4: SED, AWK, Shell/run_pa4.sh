#!/bin/bash
# ============================================================
# Project Assignment 4 - Complete Pipeline (Steps 1-6)
# Compiles all steps into a single reproducible script
# Usage: bash run_pa4.sh <INPUT_CSV>
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/out"
LOG_DIR="$SCRIPT_DIR/logs"
TEMP_DIR="/tmp/spotify_analysis_$$"

# Input validation
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <INPUT_CSV>"
    echo "Example: $0 ../SpotifyFeatures.csv"
    exit 1
fi

INPUT_FILE="$1"
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found" >&2
    exit 1
fi

# Create directories
mkdir -p "$OUT_DIR" "$LOG_DIR" "$TEMP_DIR"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "=========================================="
echo "Project Assignment 4 - Complete Pipeline"
echo "=========================================="
echo "Input: $INPUT_FILE"
echo "Output: $OUT_DIR/"
echo "Logs: $LOG_DIR/"
echo ""

# =============================================================================
# STEP 1: CLEAN & NORMALIZE (SED)
# =============================================================================
echo "STEP 1: Data Cleaning and Normalization..."
{
    echo "Starting Step 1: Data Cleaning and Normalization..."
    echo "Input: $INPUT_FILE"
    echo "Output: $OUT_DIR/cleaned_data.csv"
    echo ""
    
    # SED cleaning rules
    # 1. Check for commas in entries enclosed with "";
        # Note: This is a very simple approach to cleaning these for now
        # Note: Must check commas in this order otherwise SED cleaning breaks
    # 2. Check for trailing whitespace
    # 3. Check for 2+ whitespaces for each space
    # 4. Check for carriage returns
    # 5. Normalize quotations
    # 6 and 7. Fringe cases of title or white space in front of columns  
    # Right after, filter out any other additional column issues we come across when we can't deal with it
    sed -E \
        -e 's/("[^,"]*),+([^,"]*),([^,"]*),([^,"]*),([^,"]*")/\1 \2 \3 \4 \5/g' \
        -e 's/("[^,"]*),+([^,"]*),([^,"]*),([^,"]*")/\1 \2 \3 \4/g' \
        -e 's/("[^,"]*),+([^,"]*),([^,"]*")/\1 \2 \3/g' \
        -e 's/("[^,"]*),+([^,"]*")/\1 \2/g' \
        -e 's/^[[:space:]]+|[[:space:]]+$//g' \
        -e 's/[[:space:]]+/ /g' \
        -e 's/\r//g' \
        -e 's/""//g' \
        -e 's/^"|"$//g' \
        -e 's/,[[:space:]]*$/,/g' \
        -e 's/\///g' \
        "$INPUT_FILE" > "$OUT_DIR/cleaned_data.csv"
    
    # Generate samples
    head -50 "$INPUT_FILE" > "$OUT_DIR/before_sample.txt"
    head -50 "$OUT_DIR/cleaned_data.csv" > "$OUT_DIR/after_sample.txt"
    
    original_lines=$(wc -l < "$INPUT_FILE")
    cleaned_lines=$(wc -l < "$OUT_DIR/cleaned_data.csv")
    
    echo "Step 1 Results:"
    echo "  Original lines: $original_lines"
    echo "  Cleaned lines: $cleaned_lines"
    echo "  Samples saved to: before_sample.txt, after_sample.txt"
    echo "  Output: cleaned_data.csv"
    
} | tee "$LOG_DIR/step1.log"

echo " Step 1 completed"

# =============================================================================
# STEP 2: UNIX EDA (FREQUENCY TABLES, TOP-N, SKINNY TABLE)
# =============================================================================
echo ""
echo "STEP 2: UNIX EDA Analysis..."
{
    echo "Starting Step 2: UNIX EDA Analysis..."
    echo "Input: $OUT_DIR/cleaned_data.csv"
    echo ""
    
    # 1. Genre frequency table
    echo "1. Creating genre frequency table..."
    awk -F',' '
    NR > 1 {
        genre = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        if (genre != "" && genre != "genre") {
            freq[genre]++
        }
    }
    END {
        for (g in freq) {
            printf "%s\t%d\n", g, freq[g]
        }
    }' "$OUT_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr | 
    # Keeps header on top of file after sort
    awk -F',' 'BEGIN { print "genre\tcount" }
    {print}' > "$OUT_DIR/freq_genre.tsv"
    
    # 2. Artist frequency table
    echo "2. Creating artist frequency table..."
    awk -F',' '
    NR > 1 {
        artist = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        if (artist != "" && artist != "artist_name") {
            freq[artist]++
        }
    }
    END {
        for (a in freq) {
            printf "%s\t%d\n", a, freq[a]
        }
    }' "$OUT_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr | 
    # Keeps header on top of file after sort
    awk -F',' 'BEGIN { print "artist_name\tcount" }
    {print}' > "$OUT_DIR/freq_artists.tsv"
    
    # 3. Top 10 popular tracks
    echo "3. Creating top 10 popular tracks..."

    awk -F',' '
    BEGIN { 
        print "track_name\tartist_name\tpopularity" 
    }
    NR > 1 {
        track = $3
        artist = $2
        pop = $5
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", pop)
        if (pop != "" && pop != "popularity" && pop ~ /^[0-9]+$/) {
            tracks[pop] = track "\t" artist "\t" pop
        }
    }
    END {
        for (p in tracks) {
            print tracks[p]
        }
    }' "$OUT_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr | head -10 |
    # Keeps header on top of file after sort
    awk -F',' 'BEGIN { 
        print "track_name\tartist_name\tpopularity" 
    } {print}'> "${OUT_DIR}/top10_popular_tracks.tsv"
    
    # 4. Artist popularity skinny table
    echo "4. Creating artist popularity skinny table..."
    awk -F',' '
    NR > 1 {
        artist = $2
        genre = $1
        track_id = $4
        pop = $5
        energy = $9
        dance = $7
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track_id)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", pop)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", energy)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", dance)
        if (artist != "" && artist != "artist_name") {
            printf "%s\t%s\t%s\t%s\t%s\t%s\n", artist, genre, track_id, pop, energy, dance
        }
    }' "$OUT_DIR/cleaned_data.csv" | sort -t$'\t' -k1,1 |
    # Keeps header on top of file after sort
    awk -F',' 'BEGIN { 
        print "artist_name\tgenre\ttrack_id\tpopularity\tenergy\tdanceability" 
    } {print}' > "$OUT_DIR/artist_popularity_skinny.tsv"
    
    echo "Step 2 Results:"
    echo "  Frequency tables: freq_genre.tsv, freq_artists.tsv"
    echo "  Top-N list: top10_popular_tracks.tsv"
    echo "  Skinny table: artist_popularity_skinny.tsv"
    
} | tee "$LOG_DIR/step2.log"

echo "Step 2 completed"

# =============================================================================
# STEP 3: QUALITY FILTERS (AWK)
# =============================================================================
echo ""
echo "STEP 3: Quality Filters..."
{
    echo "Starting Step 3: Quality Filters..."
    echo "Input: $OUT_DIR/artist_popularity_skinny.tsv"
    echo "Output: $OUT_DIR/filtered.tsv"
    echo "Rules: artist != '', popularity >= 40, drop test/dummy/sample"
    echo ""
    
    # Apply quality filters
    awk -F'\t' -v OFS='\t' -v min_pop=40 ' 
    NR>1 {
        artist = $1
        genre = $2
        track_id = $3
        popularity = $4+0
        energy = $5+0
        danceability = $6+0
        
        # Business rules
        req_ok = (artist != "" && popularity != "")
        pop_ok = (popularity >= min_pop)
        test_hit = (artist ~ /(test|dummy|sample)/)
        keep = (req_ok && pop_ok && !test_hit)
        
        if (keep) {
            printf "%s\t%s\t%s\t%d\t%.4f\t%.4f\n", 
                   artist, genre, track_id, popularity, energy, danceability
        }
    }' "$OUT_DIR/artist_popularity_skinny.tsv" |
    awk -F'\t' 'BEGIN {
        print "artist_name\tgenre\ttrack_id\tpopularity\tenergy\tdanceability"
    } {print}' > "$OUT_DIR/filtered.tsv"
    
    # Generate statistics
    total_rows=$(($(wc -l < "$OUT_DIR/artist_popularity_skinny.tsv")))
    kept_rows=$(($(wc -l < "$OUT_DIR/filtered.tsv") - 1))  # Subtract header
    dropped_rows=$((total_rows - kept_rows))
    
    echo "Step 3 Results:"
    echo "  Total input rows: $total_rows"
    echo "  Rows kept: $kept_rows"
    echo "  Rows dropped: $dropped_rows"
    echo "  Filtered data: filtered.tsv"
    
} | tee "$LOG_DIR/step3.log"

echo "Step 3 completed"

# =============================================================================
# STEP 4: RATIOS, BUCKETS, PER-ARTIST SUMMARY (AWK)
# =============================================================================
echo ""
echo "STEP 4: Ratios, Buckets, and Per-Artist Summary..."
{
    echo "Starting Step 4: Ratios, Buckets, and Per-Artist Summary..."
    echo "Input: $OUT_DIR/filtered.tsv"
    echo ""
    
    # 1. Hip-Hop/Total ratio
    echo "1. Computing Hip-Hop/Total ratio..."
    awk -F'\t' '
    NR==1{for(i=1;i<=NF;i++) h[tolower($i)]=i; next}
    {tot++}
    $(h["genre"])=="Hip-Hop"{num++}
    END{
       ratio = (tot ? num/tot : 0);
         printf("Hip-Hop songs: %d / Total: %d = %.4f\n", num, tot, ratio);
         }' "$OUT_DIR/filtered.tsv" | tee "$OUT_DIR/ratio_report.txt"
    
    # 2. Energy buckets
    echo "2. Creating energy buckets..."
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
       }' "$OUT_DIR/filtered.tsv" > "$OUT_DIR/energy_buckets.tsv"
    
    # 3. Per-artist summary
    echo "3. Creating per-artist summary..."
    awk -F'\t' -v OFS='\t' '
    NR==1{
    for(i=1;i<=NF;i++) h[tolower($i)]=i
    if(!h["artist_name"] || !h["popularity"]){ print "ERROR: need artist_name and popularity" > "/dev/stderr"; exit 2 }
    next
    }
    {
    	a = $(h["artist_name"])
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
    }' "$OUT_DIR/filtered.tsv" | sort -k2,2nr |
    awk -F'\t' 'BEGIN {print "artist\tcount\tavg_pop\tmin_pop\tmax_pop"}
        {print}' > "$OUT_DIR/per_artist_summary.tsv"
    
    echo "Step 4 Results:"
    echo "  Ratio report: ratio_report.txt"
    echo "  Energy buckets: energy_buckets.tsv"
    echo "  Per-artist summary: per_artist_summary.tsv"
    
} | tee "$LOG_DIR/step4.log"

echo "Step 4 completed"

# =============================================================================
# STEP 5: STRING STRUCTURE ANALYSIS
# =============================================================================
echo ""
echo "STEP 5: String Structure Analysis..."
{
    echo "Starting Step 5: String Structure Analysis..."
    echo "Input: $OUT_DIR/filtered.tsv"
    echo ""
    
    # 1. Artist name length buckets
    echo "1. Analyzing artist name length distribution..."
    awk -F'\t' -v OFS='\t' '
    NR==1 { next }  # Skip header
    {
        artist = $1
        len = length(artist)
        if (len <= 10) {
            buckets["SHORT"]++
        } else if (len <= 20) {
            buckets["MEDIUM"]++
        } else {
            buckets["LONG"]++
        }
        total_len += len
        count++
    }
    END {
        printf "length_bucket\tcount\tavg_length\n"
        printf "SHORT\t%d\t%.2f\n", buckets["SHORT"]+0, (buckets["SHORT"] ? total_len/count : 0)
        printf "MEDIUM\t%d\t%.2f\n", buckets["MEDIUM"]+0, (buckets["MEDIUM"] ? total_len/count : 0)
        printf "LONG\t%d\t%.2f\n", buckets["LONG"]+0, (buckets["LONG"] ? total_len/count : 0)
        printf "TOTAL\t%d\t%.2f\n", count, (count ? total_len/count : 0)
    }' "$OUT_DIR/filtered.tsv" > "$OUT_DIR/artist_name_length_buckets.tsv"
    
    echo "Step 5 Results:"
    echo "  Artist name length: artist_name_length_buckets.tsv"
    
} | tee "$LOG_DIR/step5.log"

echo "Step 5 completed"

# =============================================================================
# STEP 6: SIGNAL DISCOVERY
# =============================================================================
echo ""
echo "STEP 6: Signal Discovery..."
{
    echo "Starting Step 6: Signal Discovery..."
    echo "Input: $OUT_DIR/filtered.tsv"
    echo ""
    
    # 1. Distribution profiles
    echo "1. Computing distribution profiles..."
    awk -F'\t' '
    NR==1 { next }  # Skip header
    {
        popularity = $4+0
        energy = $5+0
        danceability = $6+0
        
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
    }' "$OUT_DIR/filtered.tsv" > "$OUT_DIR/numerical_distributions.tsv"
    
    echo "Step 6 Results:"
    echo "  Numerical distributions: numerical_distributions.tsv"
    
} | tee "$LOG_DIR/step6.log"

echo "Step 6 completed"

# =============================================================================
# FINAL SUMMARY
# =============================================================================
echo ""
echo "=========================================="
echo "PIPELINE COMPLETED SUCCESSFULLY!"
echo "=========================================="
echo ""
echo "Generated Files:"
echo "  Step 1: cleaned_data.csv, before_sample.txt, after_sample.txt"
echo "  Step 2: freq_genre.tsv, freq_artists.tsv, top10_popular_tracks.tsv, artist_popularity_skinny.tsv"
echo "  Step 3: filtered.tsv"
echo "  Step 4: ratio_report.txt, energy_buckets.tsv, per_artist_summary.tsv"
echo "  Step 5: artist_name_length_buckets.tsv"
echo "  Step 6: numerical_distributions.tsv"
echo ""
echo "Output Directory: $OUT_DIR/"
echo "Logs Directory: $LOG_DIR/"
echo ""
echo "Key Insights:"
echo "  - Data cleaned and normalized with SED"
echo "  - Quality filters applied (popularity >= 40)"
echo "  - Hip-Hop ratio and energy buckets computed"
echo "  - String structure analysis completed"
echo "  - Signal discovery with outlier detection"
echo ""
echo "All steps completed successfully!"
