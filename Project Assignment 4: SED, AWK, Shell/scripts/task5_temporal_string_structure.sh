#!/bin/bash

# Part E: Temporal OR String Structure Analysis
# This script analyzes dataset structure through bucketing and string normalization
# Author: Data Engineering Team
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUT_DIR="$PROJECT_DIR/out"
LOG_DIR="$PROJECT_DIR/logs"
TEMP_DIR="/tmp/pa4_part_e_$$"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/pa4_part_e.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_DIR/pa4_part_e.log"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_DIR/pa4_part_e.log"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_DIR/pa4_part_e.log"
}

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log "Cleaned up temporary directory: $TEMP_DIR"
    fi
}
trap cleanup EXIT

# Main function
main() {
    local input_file="$1"
    
    # Validate input
    if [[ ! -f "$input_file" ]]; then
        error "Input file does not exist: $input_file"
    fi
    
    if [[ ! -r "$input_file" ]]; then
        error "Input file is not readable: $input_file"
    fi
    
    # Create directories
    mkdir -p "$OUT_DIR" "$LOG_DIR" "$TEMP_DIR"
    chmod 755 "$OUT_DIR" "$LOG_DIR"
    
    log "Starting Part E: Temporal/String Structure Analysis"
    log "Input file: $input_file"
    log "Output directory: $OUT_DIR"
    
    # Clean the data first (reuse existing cleaning logic)
    log "Cleaning input data..."
    sed -E \
        -e 's/^[[:space:]]+|[[:space:]]+$//g' \
        -e 's/[[:space:]]+/ /g' \
        -e 's/\r//g' \
        -e 's/""//g' \
        -e 's/^"|"$//g' \
        -e 's/,[[:space:]]*$/,/g' \
        "$input_file" > "$TEMP_DIR/cleaned_data.csv"
    
    # 1. Track Name Length Analysis (String Structure)
    log "Analyzing track name length distribution..."
    awk -F',' '
    BEGIN { 
        print "length_bucket\tcount\tpercentage"
        total = 0
    }
    NR > 1 {
        track_name = $3
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track_name)
        if (track_name != "" && track_name != "track_name") {
            len = length(track_name)
            if (len <= 10) bucket = "1-10"
            else if (len <= 20) bucket = "11-20"
            else if (len <= 30) bucket = "21-30"
            else if (len <= 40) bucket = "31-40"
            else if (len <= 50) bucket = "41-50"
            else bucket = "50+"
            
            track_lengths[bucket]++
            total++
        }
    }
    END {
        for (bucket in track_lengths) {
            percentage = (track_lengths[bucket] / total) * 100
            printf "%s\t%d\t%.2f%%\n", bucket, track_lengths[bucket], percentage
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/track_name_length_buckets.tsv"
    
    # 2. Artist Name Length Analysis
    log "Analyzing artist name length distribution..."
    awk -F',' '
    BEGIN { 
        print "length_bucket\tcount\tpercentage"
        total = 0
    }
    NR > 1 {
        artist_name = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist_name)
        if (artist_name != "" && artist_name != "artist_name") {
            len = length(artist_name)
            if (len <= 10) bucket = "1-10"
            else if (len <= 20) bucket = "11-20"
            else if (len <= 30) bucket = "21-30"
            else if (len <= 40) bucket = "31-40"
            else bucket = "40+"
            
            artist_lengths[bucket]++
            total++
        }
    }
    END {
        for (bucket in artist_lengths) {
            percentage = (artist_lengths[bucket] / total) * 100
            printf "%s\t%d\t%.2f%%\n", bucket, artist_lengths[bucket], percentage
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/artist_name_length_buckets.tsv"
    
    # 3. Duration Buckets (Temporal-like Structure)
    log "Analyzing track duration buckets..."
    awk -F',' '
    BEGIN { 
        print "duration_bucket\tcount\tpercentage"
        total = 0
    }
    NR > 1 {
        duration = $8
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", duration)
        if (duration != "" && duration != "duration_ms" && duration ~ /^[0-9]+$/) {
            dur_num = duration + 0
            if (dur_num < 120000) bucket = "0-2min"
            else if (dur_num < 240000) bucket = "2-4min"
            else if (dur_num < 360000) bucket = "4-6min"
            else if (dur_num < 480000) bucket = "6-8min"
            else bucket = "8min+"
            
            duration_buckets[bucket]++
            total++
        }
    }
    END {
        for (bucket in duration_buckets) {
            percentage = (duration_buckets[bucket] / total) * 100
            printf "%s\t%d\t%.2f%%\n", bucket, duration_buckets[bucket], percentage
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/duration_buckets.tsv"
    
    # 4. Popularity Range Buckets
    log "Analyzing popularity range distribution..."
    awk -F',' '
    BEGIN { 
        print "popularity_range\tcount\tpercentage"
        total = 0
    }
    NR > 1 {
        popularity = $5
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", popularity)
        if (popularity != "" && popularity != "popularity" && popularity ~ /^[0-9]+$/) {
            pop_num = popularity + 0
            if (pop_num < 20) bucket = "0-19"
            else if (pop_num < 40) bucket = "20-39"
            else if (pop_num < 60) bucket = "40-59"
            else if (pop_num < 80) bucket = "60-79"
            else bucket = "80-100"
            
            popularity_buckets[bucket]++
            total++
        }
    }
    END {
        for (bucket in popularity_buckets) {
            percentage = (popularity_buckets[bucket] / total) * 100
            printf "%s\t%d\t%.2f%%\n", bucket, popularity_buckets[bucket], percentage
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/popularity_range_buckets.tsv"
    
    # 5. Case Normalization Analysis (String Structure)
    log "Analyzing case normalization for duplicate detection..."
    
    # Check for potential duplicates after case normalization
    awk -F',' '
    BEGIN { 
        print "original_artist\tnormalized_artist\toccurrences"
        total = 0
    }
    NR > 1 {
        artist = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        if (artist != "" && artist != "artist_name") {
            normalized = tolower(artist)
            gsub(/[^a-z0-9]/, "", normalized)  # Remove non-alphanumeric for comparison
            artist_normalized[artist] = normalized
            normalized_count[normalized]++
        }
    }
    END {
        # Find potential duplicates
        for (original in artist_normalized) {
            normalized = artist_normalized[original]
            if (normalized_count[normalized] > 1) {
                printf "%s\t%s\t%d\n", original, normalized, normalized_count[normalized]
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr > "$OUT_DIR/case_normalization_analysis.tsv"
    
    # 6. Genre Case Analysis
    log "Analyzing genre case patterns..."
    awk -F',' '
    BEGIN { 
        print "original_genre\tnormalized_genre\toccurrences"
        total = 0
    }
    NR > 1 {
        genre = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        if (genre != "" && genre != "genre") {
            normalized = tolower(genre)
            gsub(/[^a-z0-9]/, "", normalized)
            genre_normalized[genre] = normalized
            normalized_count[normalized]++
        }
    }
    END {
        # Find potential duplicates
        for (original in genre_normalized) {
            normalized = genre_normalized[original]
            if (normalized_count[normalized] > 1) {
                printf "%s\t%s\t%d\n", original, normalized, normalized_count[normalized]
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr > "$OUT_DIR/genre_case_analysis.tsv"
    
    # 7. Create Summary Report
    log "Creating structure analysis summary..."
    cat > "$OUT_DIR/part_e_structure_summary.txt" << 'EOF'
# Part E: Temporal/String Structure Analysis Summary

## Dataset Structure Analysis

This analysis reveals the underlying structure of the Spotify dataset through various bucketing and normalization techniques.

### 1. Track Name Length Distribution
- Reveals naming conventions and patterns
- Helps identify standardization in track naming
- Shows distribution across different length categories

### 2. Artist Name Length Distribution  
- Analyzes artist naming patterns
- Identifies common naming conventions
- Shows distribution of artist name lengths

### 3. Duration Buckets (Temporal-like Structure)
- Groups tracks by duration ranges
- Reveals temporal patterns in the dataset
- Shows distribution of track lengths

### 4. Popularity Range Distribution
- Groups tracks by popularity score ranges
- Reveals popularity distribution patterns
- Identifies concentration of tracks in different popularity tiers

### 5. Case Normalization Analysis
- Identifies potential duplicate artists after case normalization
- Reveals string structure inconsistencies
- Helps detect data quality issues

### 6. Genre Case Analysis
- Identifies potential duplicate genres after case normalization
- Reveals genre naming inconsistencies
- Helps standardize genre classifications

## Key Insights

The bucketing analysis reveals:
- Dataset structure through frequency distributions
- Potential data quality issues through case normalization
- Temporal patterns through duration analysis
- Popularity distribution patterns

## Files Generated

- track_name_length_buckets.tsv: Track name length distribution
- artist_name_length_buckets.tsv: Artist name length distribution  
- duration_buckets.tsv: Duration range distribution
- popularity_range_buckets.tsv: Popularity range distribution
- case_normalization_analysis.tsv: Artist case normalization analysis
- genre_case_analysis.tsv: Genre case normalization analysis
- part_e_structure_summary.txt: This summary report

EOF
    
    success "Part E analysis completed successfully!"
    log "Generated files in $OUT_DIR:"
    ls -la "$OUT_DIR"/*.tsv "$OUT_DIR"/part_e_structure_summary.txt | tee -a "$LOG_DIR/pa4_part_e.log"
    
    # Display summary statistics
    log "Summary Statistics:"
    echo "Track Name Length Buckets:" | tee -a "$LOG_DIR/pa4_part_e.log"
    head -5 "$OUT_DIR/track_name_length_buckets.tsv" | tee -a "$LOG_DIR/pa4_part_e.log"
    echo "" | tee -a "$LOG_DIR/pa4_part_e.log"
    
    echo "Duration Buckets:" | tee -a "$LOG_DIR/pa4_part_e.log"
    head -5 "$OUT_DIR/duration_buckets.tsv" | tee -a "$LOG_DIR/pa4_part_e.log"
    echo "" | tee -a "$LOG_DIR/pa4_part_e.log"
    
    echo "Popularity Range Buckets:" | tee -a "$LOG_DIR/pa4_part_e.log"
    head -5 "$OUT_DIR/popularity_range_buckets.tsv" | tee -a "$LOG_DIR/pa4_part_e.log"
}

# Script entry point
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input_csv_file>"
    echo "Example: $0 ../data/samples/Spotify_Filtered_1k.csv"
    exit 1
fi

main "$1"
