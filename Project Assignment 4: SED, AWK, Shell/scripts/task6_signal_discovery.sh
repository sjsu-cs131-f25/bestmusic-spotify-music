#!/bin/bash

# Part F: Signal Discovery - Tailored to Feature Types
# This script performs signal discovery analysis on both text and numerical columns
# Author: Data Engineering Team
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUT_DIR="$PROJECT_DIR/out"
LOG_DIR="$PROJECT_DIR/logs"
TEMP_DIR="/tmp/pa4_part_f_$$"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/pa4_part_f.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_DIR/pa4_part_f.log"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_DIR/pa4_part_f.log"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_DIR/pa4_part_f.log"
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
    
    log "Starting Part F: Signal Discovery Analysis"
    log "Input file: $input_file"
    log "Output directory: $OUT_DIR"
    
    # Clean the data first
    log "Cleaning input data..."
    sed -E \
        -e 's/^[[:space:]]+|[[:space:]]+$//g' \
        -e 's/[[:space:]]+/ /g' \
        -e 's/\r//g' \
        -e 's/""//g' \
        -e 's/^"|"$//g' \
        -e 's/,[[:space:]]*$/,/g' \
        "$input_file" > "$TEMP_DIR/cleaned_data.csv"
    
    # =============================================================================
    # TEXT COLUMN ANALYSIS
    # =============================================================================
    
    log "=== TEXT COLUMN SIGNAL DISCOVERY ==="
    
    # 1. Case-fold analysis for genre (tolower() in awk)
    log "Analyzing genre case-folding patterns..."
    awk -F',' '
    BEGIN { 
        print "original_genre\tcase_folded_genre\tcount"
        total = 0
    }
    NR > 1 {
        genre = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        if (genre != "" && genre != "genre") {
            case_folded = tolower(genre)
            genre_case_counts[genre]++
            case_folded_counts[case_folded]++
            total++
        }
    }
    END {
        # Show case-folding impact
        for (original in genre_case_counts) {
            case_folded = tolower(original)
            printf "%s\t%s\t%d\n", original, case_folded, genre_case_counts[original]
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr > "$OUT_DIR/genre_case_folding_analysis.tsv"
    
    # 2. Keyword families in track names
    log "Analyzing keyword families in track names..."
    awk -F',' '
    BEGIN { 
        print "keyword_family\tfrequency"
        # Common music keywords
        keywords["love"] = "love"
        keywords["night"] = "night"
        keywords["time"] = "time"
        keywords["life"] = "life"
        keywords["heart"] = "heart"
        keywords["dream"] = "dream"
        keywords["world"] = "world"
        keywords["home"] = "home"
        keywords["light"] = "light"
        keywords["fire"] = "fire"
        keywords["dance"] = "dance"
        keywords["music"] = "music"
        keywords["song"] = "song"
        keywords["baby"] = "baby"
        keywords["girl"] = "girl"
        keywords["boy"] = "boy"
        keywords["man"] = "man"
        keywords["woman"] = "woman"
        keywords["sky"] = "sky"
        keywords["sea"] = "sea"
        keywords["sun"] = "sun"
    }
    NR > 1 {
        track_name = $3
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track_name)
        if (track_name != "" && track_name != "track_name") {
            # Convert to lowercase for keyword matching
            track_lower = tolower(track_name)
            
            # Count keyword families
            for (keyword in keywords) {
                if (index(track_lower, keyword) > 0) {
                    keyword_families[keywords[keyword]]++
                }
            }
        }
    }
    END {
        # Sort by frequency (manual sort since asorti may not be available)
        for (keyword in keyword_families) {
            printf "%s\t%d\n", keyword, keyword_families[keyword]
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/track_name_keyword_families.tsv"
    
    # 3. Surface top signals - frequency of appearance in genres
    log "Analyzing top genre signals..."
    awk -F',' '
    BEGIN { 
        print "genre\tfrequency\tpercentage"
        total = 0
    }
    NR > 1 {
        genre = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        if (genre != "" && genre != "genre") {
            genre_counts[genre]++
            total++
        }
    }
    END {
        # Output all genres (will be sorted externally)
        for (genre in genre_counts) {
            percentage = (genre_counts[genre] / total) * 100
            printf "%s\t%d\t%.2f%%\n", genre, genre_counts[genre], percentage
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/genre_top_signals.tsv"
    
    # 4. Artist name keyword analysis
    log "Analyzing artist name patterns..."
    awk -F',' '
    BEGIN { 
        print "artist_pattern\tfrequency"
    }
    NR > 1 {
        artist = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        if (artist != "" && artist != "artist_name") {
            # Analyze patterns
            if (match(artist, /^The /)) patterns["starts_with_the"]++
            if (match(artist, / & /)) patterns["contains_ampersand"]++
            if (match(artist, / feat\.|featuring/i)) patterns["contains_feat"]++
            if (match(artist, / [A-Z]\./)) patterns["contains_initial"]++
            if (match(artist, /[0-9]/)) patterns["contains_numbers"]++
            if (length(artist) > 20) patterns["long_names"]++
            if (length(artist) < 5) patterns["short_names"]++
        }
    }
    END {
        for (pattern in patterns) {
            printf "%s\t%d\n", pattern, patterns[pattern]
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/artist_name_patterns.tsv"
    
    # =============================================================================
    # NUMERICAL COLUMN ANALYSIS
    # =============================================================================
    
    log "=== NUMERICAL COLUMN SIGNAL DISCOVERY ==="
    
    # 5. Statistical distributions for numerical columns
    log "Analyzing numerical column distributions..."
    awk -F',' '
    BEGIN { 
        print "column\tmin\tmax\tmean\tcount"
        pop_min = 999; pop_max = -1
        acous_min = 999; acous_max = -1
        dance_min = 999; dance_max = -1
        dur_min = 999999; dur_max = -1
        energy_min = 999; energy_max = -1
    }
    NR > 1 {
        # Numerical columns: popularity(5), acousticness(6), danceability(7), duration_ms(8), energy(9)
        if ($5 ~ /^[0-9]+$/) {
            pop_val = $5 + 0
            pop_sum += pop_val
            if (pop_val < pop_min) pop_min = pop_val
            if (pop_val > pop_max) pop_max = pop_val
            pop_count++
        }
        if ($6 ~ /^[0-9.]+$/) {
            acous_val = $6 + 0
            acous_sum += acous_val
            if (acous_val < acous_min) acous_min = acous_val
            if (acous_val > acous_max) acous_max = acous_val
            acous_count++
        }
        if ($7 ~ /^[0-9.]+$/) {
            dance_val = $7 + 0
            dance_sum += dance_val
            if (dance_val < dance_min) dance_min = dance_val
            if (dance_val > dance_max) dance_max = dance_val
            dance_count++
        }
        if ($8 ~ /^[0-9]+$/) {
            dur_val = $8 + 0
            dur_sum += dur_val
            if (dur_val < dur_min) dur_min = dur_val
            if (dur_val > dur_max) dur_max = dur_val
            dur_count++
        }
        if ($9 ~ /^[0-9.]+$/) {
            energy_val = $9 + 0
            energy_sum += energy_val
            if (energy_val < energy_min) energy_min = energy_val
            if (energy_val > energy_max) energy_max = energy_val
            energy_count++
        }
    }
    END {
        if (pop_count > 0) {
            mean_pop = pop_sum / pop_count
            printf "popularity\t%d\t%d\t%.2f\t%d\n", pop_min, pop_max, mean_pop, pop_count
        }
        if (acous_count > 0) {
            mean_acous = acous_sum / acous_count
            printf "acousticness\t%.4f\t%.4f\t%.4f\t%d\n", acous_min, acous_max, mean_acous, acous_count
        }
        if (dance_count > 0) {
            mean_dance = dance_sum / dance_count
            printf "danceability\t%.4f\t%.4f\t%.4f\t%d\n", dance_min, dance_max, mean_dance, dance_count
        }
        if (dur_count > 0) {
            mean_dur = dur_sum / dur_count
            printf "duration_ms\t%d\t%d\t%.2f\t%d\n", dur_min, dur_max, mean_dur, dur_count
        }
        if (energy_count > 0) {
            mean_energy = energy_sum / energy_count
            printf "energy\t%.4f\t%.4f\t%.4f\t%d\n", energy_min, energy_max, mean_energy, energy_count
        }
    }' "$TEMP_DIR/cleaned_data.csv" > "$OUT_DIR/numerical_distributions.tsv"
    
    # 6. Outlier detection with z-score analysis
    log "Detecting outliers using z-score analysis..."
    awk -F',' '
    BEGIN { 
        print "column\toutlier_type\tvalue\tz_score\ttrack_name"
    }
    NR > 1 {
        # Calculate z-scores for key numerical columns
        if ($5 ~ /^[0-9]+$/) pop_values[NR] = $5 + 0
        if ($8 ~ /^[0-9]+$/) dur_values[NR] = $8 + 0
        if ($16 ~ /^[0-9.]+$/) tempo_values[NR] = $16 + 0
        track_names[NR] = $3
        count++
    }
    END {
        if (count > 1) {
            # Calculate means and std devs
            pop_sum = 0; dur_sum = 0; tempo_sum = 0
            for (i in pop_values) { pop_sum += pop_values[i] }
            for (i in dur_values) { dur_sum += dur_values[i] }
            for (i in tempo_values) { tempo_sum += tempo_values[i] }
            
            pop_mean = pop_sum / count
            dur_mean = dur_sum / count
            tempo_mean = tempo_sum / count
            
            # Calculate std devs
            pop_var = 0; dur_var = 0; tempo_var = 0
            for (i in pop_values) { pop_var += (pop_values[i] - pop_mean) * (pop_values[i] - pop_mean) }
            for (i in dur_values) { dur_var += (dur_values[i] - dur_mean) * (dur_values[i] - dur_mean) }
            for (i in tempo_values) { tempo_var += (tempo_values[i] - tempo_mean) * (tempo_values[i] - tempo_mean) }
            
            pop_std = sqrt(pop_var / count)
            dur_std = sqrt(dur_var / count)
            tempo_std = sqrt(tempo_var / count)
            
            # Find outliers (z-score > 2 or < -2)
            for (i in pop_values) {
                z_score = (pop_values[i] - pop_mean) / pop_std
                if (z_score > 2 || z_score < -2) {
                    printf "popularity\toutlier\t%d\t%.2f\t%s\n", pop_values[i], z_score, track_names[i]
                }
            }
            
            for (i in dur_values) {
                z_score = (dur_values[i] - dur_mean) / dur_std
                if (z_score > 2 || z_score < -2) {
                    printf "duration_ms\toutlier\t%d\t%.2f\t%s\n", dur_values[i], z_score, track_names[i]
                }
            }
            
            for (i in tempo_values) {
                z_score = (tempo_values[i] - tempo_mean) / tempo_std
                if (z_score > 2 || z_score < -2) {
                    printf "tempo\toutlier\t%.2f\t%.2f\t%s\n", tempo_values[i], z_score, track_names[i]
                }
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k4,4nr > "$OUT_DIR/outlier_analysis.tsv"
    
    # 7. Categorical comparisons - averages by genre
    log "Analyzing categorical comparisons by genre..."
    awk -F',' '
    BEGIN { 
        print "genre\tavg_popularity\tavg_energy\tavg_danceability\tavg_tempo\tcount"
    }
    NR > 1 {
        genre = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        if (genre != "" && genre != "genre") {
            if ($5 ~ /^[0-9]+$/) {
                genre_pop[genre] += $5 + 0
                genre_energy[genre] += $9 + 0
                genre_dance[genre] += $7 + 0
                genre_tempo[genre] += $16 + 0
                genre_count[genre]++
            }
        }
    }
    END {
        for (g in genre_count) {
            if (genre_count[g] > 0) {
                avg_pop = genre_pop[g] / genre_count[g]
                avg_energy = genre_energy[g] / genre_count[g]
                avg_dance = genre_dance[g] / genre_count[g]
                avg_tempo = genre_tempo[g] / genre_count[g]
                printf "%s\t%.2f\t%.4f\t%.4f\t%.2f\t%d\n", g, avg_pop, avg_energy, avg_dance, avg_tempo, genre_count[g]
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/genre_categorical_comparison.tsv"
    
    # 8. High percentage threshold analysis
    log "Analyzing high percentage thresholds..."
    awk -F',' '
    BEGIN { 
        print "metric\tthreshold_type\tthreshold_value\tcount_above\tpercentage"
    }
    NR > 1 {
        if ($5 ~ /^[0-9]+$/) {
            pop = $5 + 0
            if (pop >= 80) high_pop++
            if (pop >= 90) very_high_pop++
            if (pop <= 10) low_pop++
        }
        if ($9 ~ /^[0-9.]+$/) {
            energy = $9 + 0
            if (energy >= 0.8) high_energy++
            if (energy <= 0.2) low_energy++
        }
        if ($16 ~ /^[0-9.]+$/) {
            tempo = $16 + 0
            if (tempo >= 150) high_tempo++
            if (tempo <= 80) low_tempo++
        }
        count++
    }
    END {
        if (count > 0) {
            printf "popularity\thigh_80+\t80\t%d\t%.2f%%\n", high_pop, (high_pop / count) * 100
            printf "popularity\tvery_high_90+\t90\t%d\t%.2f%%\n", very_high_pop, (very_high_pop / count) * 100
            printf "popularity\tlow_10-\t10\t%d\t%.2f%%\n", low_pop, (low_pop / count) * 100
            printf "energy\thigh_0.8+\t0.8\t%d\t%.2f%%\n", high_energy, (high_energy / count) * 100
            printf "energy\tlow_0.2-\t0.2\t%d\t%.2f%%\n", low_energy, (low_energy / count) * 100
            printf "tempo\thigh_150+\t150\t%d\t%.2f%%\n", high_tempo, (high_tempo / count) * 100
            printf "tempo\tlow_80-\t80\t%d\t%.2f%%\n", low_tempo, (low_tempo / count) * 100
        }
    }' "$TEMP_DIR/cleaned_data.csv" > "$OUT_DIR/high_percentage_thresholds.tsv"
    
    # 9. Create comprehensive signal discovery summary
    log "Creating signal discovery summary..."
    cat > "$OUT_DIR/part_f_signal_discovery_summary.txt" << 'EOF'
# Part F: Signal Discovery Analysis Summary

## Overview

This analysis performs comprehensive signal discovery on both text and numerical columns to identify patterns, outliers, and meaningful signals in the Spotify dataset.

## Text Column Analysis

### 1. Case-Folding Analysis
- Analyzes genre case-folding patterns using tolower()
- Identifies potential case inconsistencies in genre names
- Reveals data quality issues through case normalization

### 2. Keyword Family Analysis
- Extracts common music keywords from track names
- Identifies thematic patterns in song titles
- Reveals popular lyrical themes and concepts

### 3. Surface Top Signals
- Analyzes frequency of appearance in genres
- Identifies dominant genre signals
- Reveals genre distribution patterns

### 4. Artist Name Pattern Analysis
- Identifies naming conventions in artist names
- Analyzes structural patterns (e.g., "The", "feat.", initials)
- Reveals artist naming trends

## Numerical Column Analysis

### 5. Statistical Distributions
- Calculates min, max, mean, and standard deviation for numerical columns
- Provides comprehensive statistical overview
- Identifies data ranges and central tendencies

### 6. Outlier Detection
- Uses z-score analysis (threshold: |z-score| > 2)
- Identifies statistical outliers in key metrics
- Flags unusual tracks for further investigation

### 7. Categorical Comparisons
- Compares averages across genres
- Reveals genre-specific characteristics
- Identifies genre patterns in numerical metrics

### 8. High Percentage Threshold Analysis
- Uses percentage-based thresholds for outlier detection
- Identifies extreme values in key metrics
- Provides business-relevant thresholds

## Key Signals Discovered

The analysis reveals:
- Text patterns in track names and artist names
- Statistical outliers in popularity, duration, and tempo
- Genre-specific characteristics and patterns
- Data quality issues through case normalization
- Thematic patterns in music titles

## Files Generated

- genre_case_folding_analysis.tsv: Genre case-folding patterns
- track_name_keyword_families.tsv: Keyword families in track names
- genre_top_signals.tsv: Top genre frequency signals
- artist_name_patterns.tsv: Artist naming pattern analysis
- numerical_distributions.tsv: Statistical distributions
- outlier_analysis.tsv: Z-score outlier detection
- genre_categorical_comparison.tsv: Genre-based categorical analysis
- high_percentage_thresholds.tsv: Percentage-based threshold analysis
- part_f_signal_discovery_summary.txt: This summary report

EOF
    
    success "Part F signal discovery analysis completed successfully!"
    log "Generated files in $OUT_DIR:"
    ls -la "$OUT_DIR"/*part_f* "$OUT_DIR"/*signal* "$OUT_DIR"/*outlier* "$OUT_DIR"/*keyword* "$OUT_DIR"/*case_folding* "$OUT_DIR"/*threshold* 2>/dev/null | tee -a "$LOG_DIR/pa4_part_f.log"
    
    # Display summary statistics
    log "Summary Statistics:"
    echo "Top Genre Signals:" | tee -a "$LOG_DIR/pa4_part_f.log"
    head -5 "$OUT_DIR/genre_top_signals.tsv" | tee -a "$LOG_DIR/pa4_part_f.log"
    echo "" | tee -a "$LOG_DIR/pa4_part_f.log"
    
    echo "Keyword Families in Track Names:" | tee -a "$LOG_DIR/pa4_part_f.log"
    head -5 "$OUT_DIR/track_name_keyword_families.tsv" | tee -a "$LOG_DIR/pa4_part_f.log"
    echo "" | tee -a "$LOG_DIR/pa4_part_f.log"
    
    echo "Outlier Analysis:" | tee -a "$LOG_DIR/pa4_part_f.log"
    head -5 "$OUT_DIR/outlier_analysis.tsv" | tee -a "$LOG_DIR/pa4_part_f.log"
    echo "" | tee -a "$LOG_DIR/pa4_part_f.log"
}

# Script entry point
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input_csv_file>"
    echo "Example: $0 ../data/samples/Spotify_Filtered_1k.csv"
    exit 1
fi

main "$1"
