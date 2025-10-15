# Project Assignment 4: SED, AWK, Shell Scripting

## Overview

This project implements a comprehensive data analysis pipeline for Spotify music data using Unix command-line tools: SED, AWK, and Shell scripting. The solution demonstrates proficiency in stream editing, data transformation, and reproducible data engineering practices.

## Features

### 🔧 **Shell Engineering**
- **Strict Mode**: Uses `set -euo pipefail` for robust error handling
- **Reproducible**: Deterministic outputs with proper directory management
- **Permission Checks**: Validates input file accessibility and sets appropriate permissions
- **Clean Logging**: Color-coded output with informative messages
- **Error Recovery**: Graceful cleanup of temporary files

### 📊 **SED Data Cleaning**
- **Whitespace Normalization**: Trims leading/trailing spaces, collapses internal whitespace
- **Character Encoding**: Removes carriage returns and normalizes quotes
- **Delimiter Consistency**: Standardizes CSV formatting
- **Before/After Samples**: Generates verification samples for data quality assessment

### 📈 **AWK Data Analysis**
- **Frequency Tables**: Genre and artist distribution analysis
- **Top-N Lists**: Most popular tracks and highest tempo tracks
- **Skinny Tables**: Key columns for downstream analysis
- **Statistical Aggregation**: Genre-level metrics with averages and counts
- **Deterministic Sorting**: Consistent output ordering

## Usage

```bash
# Run the analysis pipeline
./run_pa4.sh <INPUT_FILE>

# Example
./run_pa4.sh ../data/samples/Spotify_Filtered_1k.csv
```

## Output Files

The script generates the following outputs in the `out/` directory:

### 📋 **Data Quality**
- `before_sample.txt` - Original data sample
- `after_sample.txt` - Cleaned data sample

### 📊 **Frequency Analysis**
- `freq_genre.tsv` - Genre frequency distribution
- `freq_artists.tsv` - Artist frequency distribution

### 🏆 **Top Lists**
- `top10_popular_tracks.tsv` - Most popular tracks by Spotify popularity score
- `top10_tempo_tracks.tsv` - Tracks with highest tempo

### 📈 **Analysis Tables**
- `artist_popularity_skinny.tsv` - Artist-level metrics (popularity, energy, danceability)
- `genre_analysis_skinny.tsv` - Genre-level aggregated statistics

### 📝 **Summary**
- `analysis_summary.txt` - Comprehensive analysis overview

## Technical Implementation

### SED Cleaning Rules
```bash
# Trim whitespace and normalize formatting
sed -E \
    -e 's/^[[:space:]]+|[[:space:]]+$//g' \
    -e 's/[[:space:]]+/ /g' \
    -e 's/\r//g' \
    -e 's/""//g' \
    -e 's/^"|"$//g' \
    -e 's/,[[:space:]]*$/,/g'
```

### AWK Analysis Patterns
```bash
# Frequency counting with proper header handling
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
}' | sort -t$'\t' -k2,2nr
```

## Data Insights

### Key Findings
- **Genre Diversity**: 27 unique genres with Rock being most common (49 tracks)
- **Artist Diversity**: 814 unique artists with Beyoncé being most prolific
- **Popular Tracks**: "Con Calma" by Daddy Yankee leads with 98 popularity score
- **High Tempo**: Various tracks exceed 150 BPM for high-energy music

### Statistical Summary
- **Total Tracks**: 950 analyzed
- **Most Common Genre**: Rock (49 tracks)
- **Most Prolific Artist**: Beyoncé
- **Average Popularity**: Varies significantly across genres

## Compliance & Best Practices

### ✅ **Assignment Requirements Met**
- [x] SED for stream editing and normalization
- [x] AWK for frequency tables and Top-N lists  
- [x] Shell scripting with strict mode and error handling
- [x] Reproducible pipeline with deterministic outputs
- [x] Proper directory management and permission checks
- [x] Tab-separated outputs with headers
- [x] Before/after data quality samples

### 🔒 **Reproducibility Features**
- Single command execution: `bash run_pa4.sh <INPUT>`
- Automatic directory creation
- Deterministic sorting for consistent outputs
- Comprehensive error handling and logging
- Temporary file cleanup on exit

## File Structure

```
Project Assignment 4: SED, AWK, Shell/
├── run_pa4.sh                    # Main executable script
├── README.md                     # This documentation
├── out/                          # Generated outputs (created at runtime)
│   ├── before_sample.txt
│   ├── after_sample.txt
│   ├── freq_genre.tsv
│   ├── freq_artists.tsv
│   ├── top10_popular_tracks.tsv
│   ├── top10_tempo_tracks.tsv
│   ├── artist_popularity_skinny.tsv
│   ├── genre_analysis_skinny.tsv
│   └── analysis_summary.txt
├── logs/                         # Log files (created at runtime)
└── tmp/                          # Temporary files (cleaned up automatically)
```

## Team Roles

- **PM (Product Manager)**: Requirements analysis, acceptance criteria, project coordination
- **Data Engineers**: SED/AWK implementation, pipeline development, testing
- **Data Storyteller**: Analysis interpretation, insights documentation, reporting

---

*This project demonstrates mastery of Unix command-line tools for data engineering and analysis, following industry best practices for reproducible research and data processing pipelines.*
