#!/bin/bash

# Project Assignment 4: SED, AWK, Shell Scripting
# Spotify Music Data Analysis Pipeline
# Author: Data Engineering Team

set -euo pipefail  # Strict mode: exit on error, undefined vars, pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INPUT_FILE="${1:-}"
readonly OUTPUT_DIR="out"
readonly LOG_DIR="logs"
readonly TEMP_DIR="tmp"

# Global variables
INPUT_BASENAME=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Error handling
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}" 2>/dev/null || true
}

trap cleanup EXIT

# Usage function
usage() {
    cat << EOF
Usage: $0 <INPUT_FILE>

This script analyzes Spotify music data using SED, AWK, and shell scripting.

Requirements:
- INPUT_FILE: Path to the input CSV file (e.g., Spotify_Filtered_1k.csv)

Examples:
    $0 data/samples/Spotify_Filtered_1k.csv
    $0 /path/to/your/spotify_data.csv

The script will:
1. Clean and normalize the data using SED
2. Generate frequency tables using AWK
3. Create Top-N lists and skinny tables
4. Save all outputs to the 'out/' directory

EOF
}

# Input validation
validate_input() {
    if [[ -z "${INPUT_FILE}" ]]; then
        log_error "No input file provided"
        usage
        exit 1
    fi

    if [[ ! -f "${INPUT_FILE}" ]]; then
        log_error "Input file does not exist: ${INPUT_FILE}"
        exit 1
    fi

    if [[ ! -r "${INPUT_FILE}" ]]; then
        log_error "Input file is not readable: ${INPUT_FILE}"
        exit 1
    fi

    # Set permissions for group access
    chmod -R g+rX "$(dirname "${INPUT_FILE}")" 2>/dev/null || true

    INPUT_BASENAME="$(basename "${INPUT_FILE}" .csv)"
    log_success "Input file validated: ${INPUT_FILE}"
}

# Directory setup
setup_directories() {
    log_info "Setting up output directories..."
    mkdir -p "${OUTPUT_DIR}" "${LOG_DIR}" "${TEMP_DIR}"
    log_success "Directories created successfully"
}

# Main execution function
main() {
    log_info "Starting Project Assignment 4: Spotify Data Analysis"
    log_info "Using strict mode with error handling"
    
    # Validate input
    validate_input
    
    # Setup directories
    setup_directories
    
    # Clean the data with SED
    log_info "Starting data cleaning with SED..."
    local cleaned_file="${TEMP_DIR}/${INPUT_BASENAME}_cleaned.csv"
    
    # SED cleaning rules:
    # 1. Trim leading/trailing whitespace
    # 2. Collapse multiple spaces to single space
    # 3. Remove any carriage returns (\r)
    # 4. Normalize quotes and punctuation
    # 5. Handle empty fields consistently
    
    sed -E \
        -e 's/^[[:space:]]+|[[:space:]]+$//g' \
        -e 's/[[:space:]]+/ /g' \
        -e 's/\r//g' \
        -e 's/""//g' \
        -e 's/^"|"$//g' \
        -e 's/,[[:space:]]*$/,/g' \
        "${INPUT_FILE}" > "${cleaned_file}"
    
    # Create before/after sample for verification
    log_info "Creating before/after samples..."
    head -n 5 "${INPUT_FILE}" > "${OUTPUT_DIR}/before_sample.txt"
    head -n 5 "${cleaned_file}" > "${OUTPUT_DIR}/after_sample.txt"
    
    log_success "Data cleaning completed"
    
    # Create frequency tables with AWK
    log_info "Creating frequency tables with AWK..."
    
    # Genre frequency table
    awk -F',' '
    BEGIN { 
        print "genre\tcount" 
    }
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
    }' "${cleaned_file}" | sort -t$'\t' -k2,2nr > "${OUTPUT_DIR}/freq_genre.tsv"
    
    # Artist frequency table
    awk -F',' '
    BEGIN { 
        print "artist_name\tcount" 
    }
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
    }' "${cleaned_file}" | sort -t$'\t' -k2,2nr > "${OUTPUT_DIR}/freq_artists.tsv"
    
    log_success "Frequency tables created"
    
    # Create Top-N lists with AWK
    log_info "Creating Top-N lists with AWK..."
    
    # Top 10 most popular tracks
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
    }' "${cleaned_file}" | sort -t$'\t' -k3,3nr | head -10 > "${OUTPUT_DIR}/top10_popular_tracks.tsv"
    
    # Top 10 highest tempo tracks
    awk -F',' '
    BEGIN { 
        print "track_name\tartist_name\ttempo" 
    }
    NR > 1 {
        track = $3
        artist = $2
        tempo = $16
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", tempo)
        if (tempo != "" && tempo != "tempo" && tempo ~ /^[0-9]+\.?[0-9]*$/) {
            tracks[tempo] = track "\t" artist "\t" tempo
        }
    }
    END {
        for (t in tracks) {
            print tracks[t]
        }
    }' "${cleaned_file}" | sort -t$'\t' -k3,3nr | head -10 > "${OUTPUT_DIR}/top10_tempo_tracks.tsv"
    
    log_success "Top-N lists created"
    
    # Create skinny tables for analysis
    log_info "Creating skinny tables with AWK..."
    
    # Artist popularity skinny table (key columns only)
    awk -F',' '
    BEGIN { 
        print "artist_name\tgenre\tpopularity\tenergy\tdanceability" 
    }
    NR > 1 {
        artist = $2
        genre = $1
        pop = $5
        energy = $9
        dance = $7
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", pop)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", energy)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", dance)
        if (artist != "" && artist != "artist_name") {
            printf "%s\t%s\t%s\t%s\t%s\n", artist, genre, pop, energy, dance
        }
    }' "${cleaned_file}" | sort -t$'\t' -k1,1 > "${OUTPUT_DIR}/artist_popularity_skinny.tsv"
    
    # Genre analysis skinny table
    awk -F',' '
    BEGIN { 
        print "genre\tavg_popularity\tavg_energy\tavg_danceability\tcount" 
    }
    NR > 1 {
        genre = $1
        pop = $5
        energy = $9
        dance = $7
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", genre)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", pop)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", energy)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", dance)
        if (genre != "" && genre != "genre" && pop ~ /^[0-9]+$/ && energy ~ /^[0-9]+\.?[0-9]*$/ && dance ~ /^[0-9]+\.?[0-9]*$/) {
            pop_sum[genre] += pop
            energy_sum[genre] += energy
            dance_sum[genre] += dance
            count[genre]++
        }
    }
    END {
        for (g in count) {
            avg_pop = (count[g] > 0) ? pop_sum[g] / count[g] : 0
            avg_energy = (count[g] > 0) ? energy_sum[g] / count[g] : 0
            avg_dance = (count[g] > 0) ? dance_sum[g] / count[g] : 0
            printf "%s\t%.2f\t%.3f\t%.3f\t%d\n", g, avg_pop, avg_energy, avg_dance, count[g]
        }
    }' "${cleaned_file}" | sort -t$'\t' -k5,5nr > "${OUTPUT_DIR}/genre_analysis_skinny.tsv"
    
    log_success "Skinny tables created"
    
    # Generate summary statistics
    log_info "Generating summary statistics..."
    
    {
        echo "=== SPOTIFY DATA ANALYSIS SUMMARY ==="
        echo "Generated on: $(date)"
        echo "Input file: ${INPUT_FILE}"
        echo ""
        
        # Basic file statistics
        echo "=== FILE STATISTICS ==="
        echo "Total lines: $(wc -l < "${cleaned_file}")"
        echo "Total tracks: $(($(wc -l < "${cleaned_file}") - 1))"  # Subtract header
        echo ""
        
        # Genre diversity
        echo "=== GENRE DIVERSITY ==="
        echo "Unique genres: $(tail -n +2 "${OUTPUT_DIR}/freq_genre.tsv" | wc -l)"
        echo "Most common genre: $(head -n 2 "${OUTPUT_DIR}/freq_genre.tsv" | tail -n 1 | cut -f1)"
        echo ""
        
        # Artist diversity
        echo "=== ARTIST DIVERSITY ==="
        echo "Unique artists: $(tail -n +2 "${OUTPUT_DIR}/freq_artists.tsv" | wc -l)"
        echo "Most prolific artist: $(head -n 2 "${OUTPUT_DIR}/freq_artists.tsv" | tail -n 1 | cut -f1)"
        echo ""
        
        echo "=== OUTPUT FILES CREATED ==="
        echo "Cleaned data samples: before_sample.txt, after_sample.txt"
        echo "Frequency tables: freq_genre.tsv, freq_artists.tsv"
        echo "Top-N lists: top10_popular_tracks.tsv, top10_tempo_tracks.tsv"
        echo "Skinny tables: artist_popularity_skinny.tsv, genre_analysis_skinny.tsv"
        
    } > "${OUTPUT_DIR}/analysis_summary.txt"
    
    log_success "Summary generated"
    log_success "Analysis pipeline completed successfully!"
    log_info "All outputs saved to: ${OUTPUT_DIR}/"
    log_info "Check analysis_summary.txt for overview"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi