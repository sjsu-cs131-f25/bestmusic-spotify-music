#!/bin/bash

# Part E: Temporal/Structure Analysis
# This script implements:
# 1. Duration bucketing to reveal dataset structure
# 2. Capitalization normalization to check for duplicates

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUT_DIR="$PROJECT_DIR/out"
LOG_DIR="$PROJECT_DIR/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create directories
mkdir -p "$OUT_DIR" "$LOG_DIR"

# Function to analyze duration buckets
analyze_duration_buckets() {
    local input_file="$1"
    local output_file="$OUT_DIR/duration_buckets.tsv"
    
    log "Analyzing duration buckets to reveal dataset structure..."
    
    # Create duration buckets and analyze distribution
    awk -F',' '
    BEGIN {
        # Define duration buckets (in milliseconds)
        # Very Short: < 2 minutes (120,000 ms)
        # Short: 2-3 minutes (120,000-180,000 ms)  
        # Medium: 3-4 minutes (180,000-240,000 ms)
        # Long: 4-5 minutes (240,000-300,000 ms)
        # Very Long: > 5 minutes (300,000+ ms)
    }
    NR > 1 {
        duration = $8  # duration_ms column
        track_name = $3
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", duration)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track_name)
        
        if (duration == "" || duration == "duration_ms") next
        
        # Categorize into buckets
        if (duration < 120000) {
            bucket = "Very Short (< 2min)"
        } else if (duration < 180000) {
            bucket = "Short (2-3min)"
        } else if (duration < 240000) {
            bucket = "Medium (3-4min)"
        } else if (duration < 300000) {
            bucket = "Long (4-5min)"
        } else {
            bucket = "Very Long (> 5min)"
        }
        
        # Store data for each bucket
        bucket_count[bucket]++
        bucket_total[bucket] += duration
        if (bucket_min[bucket] == "" || duration < bucket_min[bucket]) {
            bucket_min[bucket] = duration
        }
        if (bucket_max[bucket] == "" || duration > bucket_max[bucket]) {
            bucket_max[bucket] = duration
        }
        if (bucket_example[bucket] == "") {
            bucket_example[bucket] = track_name
        }
    }
    END {
        for (bucket in bucket_count) {
            avg_duration = bucket_total[bucket] / bucket_count[bucket]
            printf "%s\t%d\t%.0f\t%s\t%s\t%s\n", 
                bucket, bucket_count[bucket], avg_duration, 
                bucket_min[bucket], bucket_max[bucket], bucket_example[bucket]
        }
    }' "$input_file" | sort -t$'\t' -k2,2nr | cat <(echo "duration_bucket\ttrack_count\tavg_duration_ms\tmin_duration_ms\tmax_duration_ms\texample_track") - > "$output_file"
    
    success "Duration bucket analysis completed: $output_file"
}

# Function to normalize capitalization and check for duplicates
analyze_capitalization_duplicates() {
    local input_file="$1"
    local output_file="$OUT_DIR/capitalization_analysis.tsv"
    
    log "Analyzing capitalization normalization and duplicate detection..."
    
    # Analyze artist names and track names for capitalization patterns
    awk -F',' '
    BEGIN {
        # Skip header in output - will add it separately
    }
    NR > 1 {
        artist = $2
        track = $3
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", artist)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", track)
        
        if (artist == "" || artist == "artist_name") next
        
        # Normalize to lowercase for comparison
        artist_lower = tolower(artist)
        track_lower = tolower(track)
        
        # Track artist variations using concatenated keys
        artist_key = artist_lower "|" artist
        artist_variations[artist_key]++
        artist_total[artist_lower]++
        
        # Track track variations using concatenated keys
        track_key = track_lower "|" track
        track_variations[track_key]++
        track_total[track_lower]++
    }
    END {
        # Analyze artist name capitalization patterns
        for (key in artist_variations) {
            split(key, parts, "|")
            normalized = parts[1]
            original = parts[2]
            
            if (artist_total[normalized] > 1) {
                # Build variations string for this normalized name
                variations = ""
                example = ""
                count = 0
                
                for (k in artist_variations) {
                    split(k, k_parts, "|")
                    if (k_parts[1] == normalized) {
                        if (variations != "") variations = variations "; "
                        variations = variations k_parts[2]
                        if (count == 0) example = k_parts[2]
                        count += artist_variations[k]
                    }
                }
                
                # Only print once per normalized name
                if (!printed_artist[normalized]) {
                    printf "%s\t%s\t%d\t%s\t%s\n", 
                        normalized, normalized, count, variations, example
                    printed_artist[normalized] = 1
                }
            }
        }
        
        # Analyze track name capitalization patterns
        for (key in track_variations) {
            split(key, parts, "|")
            normalized = parts[1]
            original = parts[2]
            
            if (track_total[normalized] > 1) {
                # Build variations string for this normalized name
                variations = ""
                example = ""
                count = 0
                
                for (k in track_variations) {
                    split(k, k_parts, "|")
                    if (k_parts[1] == normalized) {
                        if (variations != "") variations = variations "; "
                        variations = variations k_parts[2]
                        if (count == 0) example = k_parts[2]
                        count += track_variations[k]
                    }
                }
                
                # Only print once per normalized name
                if (!printed_track[normalized]) {
                    printf "%s\t%s\t%d\t%s\t%s\n", 
                        normalized, normalized, count, variations, example
                    printed_track[normalized] = 1
                }
            }
        }
    }' "$input_file" | sort -t$'\t' -k3,3nr | cat <(echo "original_name\tnormalized_name\toccurrence_count\tcase_variations\texample_entries") - > "$output_file"
    
    success "Capitalization analysis completed: $output_file"
}

# Function to create structure summary
create_structure_summary() {
    local input_file="$1"
    local output_file="$OUT_DIR/structure_analysis_summary.txt"
    
    log "Creating structure analysis summary..."
    
    {
        echo "=== PART E: TEMPORAL/STRUCTURE ANALYSIS SUMMARY ==="
        echo "Generated on: $(date)"
        echo "Input file: $input_file"
        echo ""
        
        echo "=== DURATION BUCKET ANALYSIS ==="
        echo "This analysis reveals the temporal structure of the dataset by bucketing tracks by duration:"
        echo ""
        if [ -f "$OUT_DIR/duration_buckets.tsv" ]; then
            echo "Duration Distribution:"
            awk -F$'\t' 'NR > 1 { 
                printf "  %-20s: %d tracks (%.1f%%)\n", $1, $2, ($2/total)*100 
            }' total=$(awk -F$'\t' 'NR > 1 {sum += $2} END {print sum}' "$OUT_DIR/duration_buckets.tsv") "$OUT_DIR/duration_buckets.tsv"
            echo ""
            echo "Detailed bucket information:"
            cat "$OUT_DIR/duration_buckets.tsv" | column -t -s$'\t'
        fi
        
        echo ""
        echo "=== CAPITALIZATION ANALYSIS ==="
        echo "This analysis checks for duplicate structure by normalizing capitalization:"
        echo ""
        if [ -f "$OUT_DIR/capitalization_analysis.tsv" ]; then
            duplicate_count=$(awk -F$'\t' 'NR > 1' "$OUT_DIR/capitalization_analysis.tsv" | wc -l)
            echo "Found $duplicate_count weak duplicates (case-insensitive matches)"
            echo ""
            if [ "$duplicate_count" -gt 0 ]; then
                echo "Top capitalization variations:"
                head -5 "$OUT_DIR/capitalization_analysis.tsv" | column -t -s$'\t'
            else
                echo "No capitalization-based duplicates found."
            fi
        fi
        
        echo ""
        echo "=== KEY INSIGHTS ==="
        echo "1. Duration Structure: The dataset shows distribution across different track lengths"
        echo "2. Capitalization: Case variations help identify potential duplicate entries"
        echo "3. Data Quality: Both analyses reveal structural patterns in the dataset"
        
    } > "$output_file"
    
    success "Structure analysis summary completed: $output_file"
}

# Main execution
main() {
    local input_file="$1"
    
    if [ ! -f "$input_file" ]; then
        error "Input file not found: $input_file"
        exit 1
    fi
    
    log "Starting Part E: Temporal/Structure Analysis"
    log "Input file: $input_file"
    
    # Run analyses
    analyze_duration_buckets "$input_file"
    analyze_capitalization_duplicates "$input_file"
    create_structure_summary "$input_file"
    
    success "Part E analysis completed successfully!"
    log "Output files generated in: $OUT_DIR"
    log "Check structure_analysis_summary.txt for overview"
}

# Execute main function with all arguments
main "$@"
