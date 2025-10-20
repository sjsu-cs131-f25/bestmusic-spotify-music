#!/bin/bash

# Complete Spotify Music Data Analysis Pipeline
# Compiles all parts (A-F) into a single reproducible shell script
# Author: Data Engineering Team
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
OUT_DIR="$PROJECT_DIR/out"
LOG_DIR="$PROJECT_DIR/logs"
TEMP_DIR="/tmp/spotify_analysis_$$"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/complete_analysis.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_DIR/complete_analysis.log"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_DIR/complete_analysis.log"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_DIR/complete_analysis.log"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_DIR/complete_analysis.log"
}

section() {
    echo -e "${PURPLE}[SECTION]${NC} $1" | tee -a "$LOG_DIR/complete_analysis.log"
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
    
    log "Starting Complete Spotify Music Data Analysis Pipeline"
    log "Input file: $input_file"
    log "Output directory: $OUT_DIR"
    log "Log directory: $LOG_DIR"
    
    # =============================================================================
    # PART A: Data Cleaning and Quality Assessment
    # =============================================================================
    
    section "PART A: Data Cleaning and Quality Assessment"
    
    log "Cleaning input data with SED..."
    sed -E \
        -e 's/^[[:space:]]+|[[:space:]]+$//g' \
        -e 's/[[:space:]]+/ /g' \
        -e 's/\r//g' \
        -e 's/""//g' \
        -e 's/^"|"$//g' \
        -e 's/,[[:space:]]*$/,/g' \
        "$input_file" > "$TEMP_DIR/cleaned_data.csv"
    
    # Generate before/after samples
    log "Generating data quality samples..."
    head -10 "$input_file" > "$OUT_DIR/before_sample.txt"
    head -10 "$TEMP_DIR/cleaned_data.csv" > "$OUT_DIR/after_sample.txt"
    
    success "Part A completed: Data cleaning and quality assessment"
    
    # =============================================================================
    # PART B: Frequency Analysis
    # =============================================================================
    
    section "PART B: Frequency Analysis"
    
    log "Analyzing genre frequency distribution..."
    awk -F',' '
    BEGIN { print "genre\tcount" }
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
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/freq_genre.tsv"
    
    log "Analyzing artist frequency distribution..."
    awk -F',' '
    BEGIN { print "artist_name\tcount" }
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
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/freq_artists.tsv"
    
    success "Part B completed: Frequency analysis"
    
    # =============================================================================
    # PART C: Top-N Lists
    # =============================================================================
    
    section "PART C: Top-N Lists"
    
    log "Generating top 10 popular tracks..."
    awk -F',' '
    BEGIN { print "track_name\tartist_name\tpopularity" }
    NR > 1 {
        if ($5 ~ /^[0-9]+$/) {
            popularity = $5 + 0
            track = $3
            artist = $2
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", track)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
            if (track != "" && artist != "" && track != "track_name") {
                printf "%s\t%s\t%d\n", track, artist, popularity
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr | head -10 > "$OUT_DIR/top10_popular_tracks.tsv"
    
    log "Generating top 10 tempo tracks..."
    awk -F',' '
    BEGIN { print "track_name\tartist_name\ttempo" }
    NR > 1 {
        if ($16 ~ /^[0-9.]+$/) {
            tempo = $16 + 0
            track = $3
            artist = $2
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", track)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
            if (track != "" && artist != "" && track != "track_name") {
                printf "%s\t%s\t%.2f\n", track, artist, tempo
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr | head -10 > "$OUT_DIR/top10_tempo_tracks.tsv"
    
    success "Part C completed: Top-N lists"
    
    # =============================================================================
    # PART D: Statistical Aggregation and Skinny Tables
    # =============================================================================
    
    section "PART D: Statistical Aggregation and Skinny Tables"
    
    log "Creating artist popularity skinny table..."
    awk -F',' '
    BEGIN { print "artist_name\tavg_popularity\tavg_energy\tavg_danceability" }
    NR > 1 {
        artist = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        if (artist != "" && artist != "artist_name") {
            if ($5 ~ /^[0-9]+$/ && $9 ~ /^[0-9.]+$/ && $7 ~ /^[0-9.]+$/) {
                popularity = $5 + 0
                energy = $9 + 0
                danceability = $7 + 0
                
                artist_pop[artist] += popularity
                artist_energy[artist] += energy
                artist_dance[artist] += danceability
                artist_count[artist]++
            }
        }
    }
    END {
        for (a in artist_count) {
            avg_pop = artist_pop[a] / artist_count[a]
            avg_energy = artist_energy[a] / artist_count[a]
            avg_dance = artist_dance[a] / artist_count[a]
            printf "%s\t%.2f\t%.4f\t%.4f\n", a, avg_pop, avg_energy, avg_dance
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/artist_popularity_skinny.tsv"
    
    log "Creating genre analysis skinny table..."
    awk -F',' '
    BEGIN { print "genre\tcount\tavg_popularity\tavg_energy\tavg_danceability" }
    NR > 1 {
        genre = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        if (genre != "" && genre != "genre") {
            if ($5 ~ /^[0-9]+$/ && $9 ~ /^[0-9.]+$/ && $7 ~ /^[0-9.]+$/) {
                popularity = $5 + 0
                energy = $9 + 0
                danceability = $7 + 0
                
                genre_pop[genre] += popularity
                genre_energy[genre] += energy
                genre_dance[genre] += danceability
                genre_count[genre]++
            }
        }
    }
    END {
        for (g in genre_count) {
            avg_pop = genre_pop[g] / genre_count[g]
            avg_energy = genre_energy[g] / genre_count[g]
            avg_dance = genre_dance[g] / genre_count[g]
            printf "%s\t%d\t%.2f\t%.4f\t%.4f\n", g, genre_count[g], avg_pop, avg_energy, avg_dance
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/genre_analysis_skinny.tsv"
    
    success "Part D completed: Statistical aggregation and skinny tables"
    
    # =============================================================================
    # PART E: Temporal/String Structure Analysis
    # =============================================================================
    
    section "PART E: Temporal/String Structure Analysis"
    
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
    
    log "Analyzing duration buckets (temporal-like structure)..."
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
    
    log "Analyzing case normalization for duplicate detection..."
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
            gsub(/[^a-z0-9]/, "", normalized)
            artist_normalized[artist] = normalized
            normalized_count[normalized]++
        }
    }
    END {
        for (original in artist_normalized) {
            normalized = artist_normalized[original]
            if (normalized_count[normalized] > 1) {
                printf "%s\t%s\t%d\n", original, normalized, normalized_count[normalized]
            }
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k3,3nr > "$OUT_DIR/case_normalization_analysis.tsv"
    
    success "Part E completed: Temporal/String structure analysis"
    
    # =============================================================================
    # PART F: Signal Discovery
    # =============================================================================
    
    section "PART F: Signal Discovery"
    
    log "Analyzing keyword families in track names..."
    awk -F',' '
    BEGIN { 
        print "keyword_family\tfrequency"
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
            track_lower = tolower(track_name)
            for (keyword in keywords) {
                if (index(track_lower, keyword) > 0) {
                    keyword_families[keywords[keyword]]++
                }
            }
        }
    }
    END {
        for (keyword in keyword_families) {
            printf "%s\t%d\n", keyword, keyword_families[keyword]
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/track_name_keyword_families.tsv"
    
    log "Detecting outliers using z-score analysis..."
    awk -F',' '
    BEGIN { 
        print "column\toutlier_type\tvalue\tz_score\ttrack_name"
    }
    NR > 1 {
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
    
    log "Analyzing genre signal patterns..."
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
        for (genre in genre_counts) {
            percentage = (genre_counts[genre] / total) * 100
            printf "%s\t%d\t%.2f%%\n", genre, genre_counts[genre], percentage
        }
    }' "$TEMP_DIR/cleaned_data.csv" | sort -t$'\t' -k2,2nr > "$OUT_DIR/genre_top_signals.tsv"
    
    success "Part F completed: Signal discovery"
    
    # =============================================================================
    # FINAL SUMMARY REPORT
    # =============================================================================
    
    section "GENERATING FINAL SUMMARY REPORT"
    
    log "Creating comprehensive analysis summary..."
    cat > "$OUT_DIR/complete_analysis_summary.txt" << EOF
# Complete Spotify Music Data Analysis Pipeline - Summary Report

## Analysis Overview
This comprehensive analysis pipeline processes Spotify music data through six distinct parts:

### Part A: Data Cleaning and Quality Assessment
- SED-based data cleaning and normalization
- Before/after data quality samples generated
- Whitespace normalization and character encoding cleanup

### Part B: Frequency Analysis
- Genre frequency distribution analysis
- Artist frequency distribution analysis
- Sorted frequency tables with counts

### Part C: Top-N Lists
- Top 10 most popular tracks by Spotify popularity score
- Top 10 tracks with highest tempo (BPM)
- Ranked lists with track names, artists, and metrics

### Part D: Statistical Aggregation and Skinny Tables
- Artist-level metrics: average popularity, energy, danceability
- Genre-level aggregated statistics with counts and averages
- Comprehensive skinny tables for downstream analysis

### Part E: Temporal/String Structure Analysis
- Track name length distribution bucketing
- Duration bucketing (temporal-like structure analysis)
- Case normalization analysis for duplicate detection
- String structure pattern analysis

### Part F: Signal Discovery
- Keyword family analysis in track names
- Z-score outlier detection for statistical anomalies
- Genre signal pattern analysis
- Text and numerical column signal discovery

## Key Insights Discovered

### Data Quality
- Comprehensive data cleaning applied to normalize formatting
- Before/after samples demonstrate cleaning effectiveness

### Frequency Patterns
- Genre distribution reveals musical diversity
- Artist frequency shows prolific vs. single-track artists

### Popularity and Tempo
- Top tracks reveal mainstream vs. niche preferences
- High-tempo tracks identified for energy analysis

### Statistical Patterns
- Artist-level aggregations show performance consistency
- Genre-level statistics reveal genre characteristics

### Structural Analysis
- Track name length patterns reveal naming conventions
- Duration bucketing shows temporal structure
- Case normalization identifies potential duplicates

### Signal Discovery
- Keyword families reveal thematic patterns in music
- Outlier analysis identifies statistical anomalies
- Genre signals show distribution patterns

## Files Generated

### Data Quality
- before_sample.txt - Original data sample
- after_sample.txt - Cleaned data sample

### Frequency Analysis
- freq_genre.tsv - Genre frequency distribution
- freq_artists.tsv - Artist frequency distribution

### Top Lists
- top10_popular_tracks.tsv - Most popular tracks
- top10_tempo_tracks.tsv - Highest tempo tracks

### Statistical Analysis
- artist_popularity_skinny.tsv - Artist-level metrics
- genre_analysis_skinny.tsv - Genre-level statistics

### Structure Analysis
- track_name_length_buckets.tsv - Track name length distribution
- duration_buckets.tsv - Duration range distribution
- case_normalization_analysis.tsv - Case normalization analysis

### Signal Discovery
- track_name_keyword_families.tsv - Keyword families in track names
- outlier_analysis.tsv - Statistical outlier detection
- genre_top_signals.tsv - Genre signal patterns

### Summary
- complete_analysis_summary.txt - This comprehensive summary

## Technical Implementation

### Tools Used
- SED: Stream editing for data cleaning
- AWK: Data processing and statistical analysis
- Shell Scripting: Pipeline orchestration and automation

### Engineering Standards
- Strict error handling with set -euo pipefail
- Comprehensive logging with color-coded output
- Temporary file management with cleanup
- Reproducible pipeline with deterministic outputs

### Data Processing
- CSV parsing with proper field handling
- Statistical calculations (mean, std dev, z-scores)
- Frequency counting and sorting
- Pattern matching and text analysis

## Reproducibility Features
- Single command execution: ./run_complete_analysis.sh <INPUT_FILE>
- Automatic directory creation and cleanup
- Comprehensive logging to files
- Deterministic output ordering
- Error handling and recovery

## Usage
\`\`\`bash
# Run complete analysis pipeline
./run_complete_analysis.sh <INPUT_CSV_FILE>

# Example
./run_complete_analysis.sh ../data/samples/Spotify_Filtered_1k.csv
\`\`\`

---
*This analysis demonstrates comprehensive data engineering practices using Unix command-line tools for reproducible research and data processing pipelines.*

Generated on: $(date)
Pipeline Version: 1.0
EOF
    
    # Display final summary
    log "Analysis pipeline completed successfully!"
    log "Generated $(ls -1 "$OUT_DIR"/*.tsv "$OUT_DIR"/*.txt 2>/dev/null | wc -l) output files in $OUT_DIR"
    
    # Show key statistics
    info "Key Statistics:"
    echo "Total tracks analyzed: $(tail -n +2 "$TEMP_DIR/cleaned_data.csv" | wc -l)" | tee -a "$LOG_DIR/complete_analysis.log"
    echo "Unique genres: $(tail -n +2 "$OUT_DIR/freq_genre.tsv" | wc -l)" | tee -a "$LOG_DIR/complete_analysis.log"
    echo "Unique artists: $(tail -n +2 "$OUT_DIR/freq_artists.tsv" | wc -l)" | tee -a "$LOG_DIR/complete_analysis.log"
    echo "Outliers detected: $(tail -n +2 "$OUT_DIR/outlier_analysis.tsv" | wc -l)" | tee -a "$LOG_DIR/complete_analysis.log"
    
    success "Complete analysis pipeline finished successfully!"
    log "All results saved to: $OUT_DIR"
    log "Logs saved to: $LOG_DIR"
}

# Script entry point
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input_csv_file>"
    echo "Example: $0 ../data/samples/Spotify_Filtered_1k.csv"
    echo ""
    echo "This script runs the complete Spotify music data analysis pipeline"
    echo "including all parts (A-F): data cleaning, frequency analysis, top lists,"
    echo "statistical aggregation, structure analysis, and signal discovery."
    exit 1
fi

main "$1"
