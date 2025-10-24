#!/bin/bash


set -euo pipefail

# Configuration
INPUT_FILE="${1:-}"
OUTPUT_DIR="out"
LOG_DIR="logs"

# Usage function
usage() {
    echo "Usage: $0 <INPUT_FILE>"
    echo "Example: $0 out/cleaned_data.csv"
    exit 1
}

# Input validation
if [[ -z "${INPUT_FILE}" ]]; then
    echo "Error: No input file provided"
    usage
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
    echo "Error: Input file does not exist: ${INPUT_FILE}"
    exit 1
fi

if [[ ! -r "${INPUT_FILE}" ]]; then
    echo "Error: Input file is not readable: ${INPUT_FILE}"
    exit 1
fi

# Create directories
mkdir -p "${OUTPUT_DIR}" "${LOG_DIR}"

echo "Starting Step 2: Simplified UNIX EDA Analysis..."

echo "1. Creating frequency tables..."

# Genre frequency table
echo "  - Genre frequency distribution..."
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
}' "${INPUT_FILE}" | sort -t$'\t' -k2,2nr > "${OUTPUT_DIR}/freq_genre.tsv"

# Artist frequency table
echo "  - Artist frequency distribution..."
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
}' "${INPUT_FILE}" | sort -t$'\t' -k2,2nr > "${OUTPUT_DIR}/freq_artists.tsv"

echo "Frequency tables created"


echo "2. Creating Top-N list..."

# Top 10 most popular tracks
echo "  - Top 10 most popular tracks..."
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
}' "${INPUT_FILE}" | sort -t$'\t' -k3,3nr | head -10 > "${OUTPUT_DIR}/top10_popular_tracks.tsv"

echo "Top-N list created"


echo "3. Creating skinny table..."

# Artist popularity skinny table (key columns only)
echo "  - Artist popularity skinny table..."
awk -F',' '
BEGIN { 
    print "artist_name\tgenre\ttrack_id\tpopularity\tenergy\tdanceability" 
}
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
}' "${INPUT_FILE}" | sort -t$'\t' -k1,1 > "${OUTPUT_DIR}/artist_popularity_skinny.tsv"

echo " Skinny table created"

echo "4. Generating summary..."

# Basic summary
{
    echo "=== STEP 2: SIMPLIFIED UNIX EDA ANALYSIS ==="
    echo "Generated on: $(date)"
    echo "Input file: ${INPUT_FILE}"
    echo ""
    
    # Basic file statistics
    echo "=== DATASET STATISTICS ==="
    echo "Total lines: $(wc -l < "${INPUT_FILE}")"
    echo "Total tracks: $(($(wc -l < "${INPUT_FILE}") - 1))"  # Subtract header
    echo ""
    
    # Genre diversity
    echo "=== GENRE DIVERSITY ==="
    echo "Unique genres: $(tail -n +2 "${OUTPUT_DIR}/freq_genre.tsv" | wc -l)"
    echo "Most common genre: $(head -n 2 "${OUTPUT_DIR}/freq_genre.tsv" | tail -n 1 | cut -f1)"
    echo "Most common genre count: $(head -n 2 "${OUTPUT_DIR}/freq_genre.tsv" | tail -n 1 | cut -f2)"
    echo ""
    
    # Artist diversity
    echo "=== ARTIST DIVERSITY ==="
    echo "Unique artists: $(tail -n +2 "${OUTPUT_DIR}/freq_artists.tsv" | wc -l)"
    echo "Most prolific artist: $(head -n 2 "${OUTPUT_DIR}/freq_artists.tsv" | tail -n 1 | cut -f1)"
    echo "Most prolific artist count: $(head -n 2 "${OUTPUT_DIR}/freq_artists.tsv" | tail -n 1 | cut -f2)"
    echo ""
    
    # Top tracks
    echo "=== TOP TRACKS ==="
    echo "Most popular track: $(head -n 2 "${OUTPUT_DIR}/top10_popular_tracks.tsv" | tail -n 1 | cut -f1)"
    echo "Most popular artist: $(head -n 2 "${OUTPUT_DIR}/top10_popular_tracks.tsv" | tail -n 1 | cut -f2)"
    echo "Most popular score: $(head -n 2 "${OUTPUT_DIR}/top10_popular_tracks.tsv" | tail -n 1 | cut -f3)"
    echo ""
    
    echo "=== OUTPUT FILES CREATED ==="
    echo "Frequency Tables: freq_genre.tsv, freq_artists.tsv"
    echo "Top-N List: top10_popular_tracks.tsv"
    echo "Skinny Table: artist_popularity_skinny.tsv"
    
} > "${OUTPUT_DIR}/step2_simple_summary.txt"

echo "Summary generated"

echo ""
echo "Step 2 (Simplified) completed successfully!"
echo "Generated files in ${OUTPUT_DIR}/:"
ls -la "${OUTPUT_DIR}"/*.tsv "${OUTPUT_DIR}"/step2_simple_summary.txt
echo ""
echo "Ready for Step 3 (Quality Filters)!"
