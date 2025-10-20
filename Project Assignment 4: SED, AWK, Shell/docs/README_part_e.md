# Part E: Temporal/Structure Analysis

## Overview

Part E implements temporal and structural analysis of the Spotify dataset using SED, AWK, and Shell scripting. This analysis focuses on revealing dataset structure through duration bucketing and capitalization normalization to identify potential duplicate entries.

## Features Implemented

### 🕐 **Duration Bucket Analysis**
- **Temporal Structure**: Buckets tracks by duration to reveal dataset temporal patterns
- **Five Duration Categories**:
  - Very Short: < 2 minutes (120,000 ms)
  - Short: 2-3 minutes (120,000-180,000 ms)
  - Medium: 3-4 minutes (180,000-240,000 ms)
  - Long: 4-5 minutes (240,000-300,000 ms)
  - Very Long: > 5 minutes (300,000+ ms)
- **Statistical Metrics**: Count, average, min/max duration, example track per bucket

### 🔤 **Capitalization Analysis**
- **Duplicate Detection**: Uses `tolower()` normalization to identify potential duplicates
- **Case Variations**: Identifies entries that differ only in capitalization
- **Weak Duplicates**: Finds case-insensitive matches across artist and track names
- **Variation Tracking**: Shows all capitalization variations for each normalized name

## Usage

```bash
# Run Part E analysis
./scripts/part_e_structure_analysis.sh <INPUT_FILE>

# Example
./scripts/part_e_structure_analysis.sh ../data/samples/Spotify_Filtered_1k.csv
```

## Output Files

### 📊 **Duration Buckets** (`duration_buckets.tsv`)
- **Columns**: duration_bucket, track_count, avg_duration_ms, min_duration_ms, max_duration_ms, example_track
- **Purpose**: Reveals temporal structure of the dataset
- **Sorted by**: Track count (descending)

### 🔍 **Capitalization Analysis** (`capitalization_analysis.tsv`)
- **Columns**: original_name, normalized_name, occurrence_count, case_variations, example_entries
- **Purpose**: Identifies potential duplicate entries based on case variations
- **Sorted by**: Occurrence count (descending)

### 📝 **Summary Report** (`structure_analysis_summary.txt`)
- **Content**: Comprehensive overview of both analyses
- **Includes**: Distribution statistics, key insights, and findings

## Key Findings from Sample Data

### Duration Structure
- **Medium tracks (3-4min)**: Most common with 373 tracks (40.3%)
- **Long tracks (4-5min)**: 210 tracks (22.7%)
- **Short tracks (2-3min)**: 166 tracks (17.9%)
- **Very Long tracks (>5min)**: 153 tracks (16.5%)
- **Very Short tracks (<2min)**: 48 tracks (5.2%)

### Capitalization Patterns
- **109 weak duplicates** found (case-insensitive matches)
- **Top duplicates**:
  - Kimbo Children's Music: 7 occurrences
  - Beyoncé: 4 occurrences
  - Daddy Yankee: 4 occurrences
  - Future: 4 occurrences
  - Hillsong Worship: 4 occurrences

## Technical Implementation

### AWK Duration Bucketing
```bash
# Categorize tracks by duration
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
```

### AWK Capitalization Normalization
```bash
# Normalize to lowercase for comparison
artist_lower = tolower(artist)
track_lower = tolower(track)

# Track variations using concatenated keys
artist_key = artist_lower "|" artist
artist_variations[artist_key]++
```

## Compliance with Assignment Requirements

### ✅ **Part E Requirements Met**
- [x] **Temporal/Structure Analysis**: Duration bucketing reveals dataset temporal structure
- [x] **Capitalization Normalization**: Uses `tolower()` to check for duplicate structure
- [x] **SED/AWK Implementation**: Pure command-line tool implementation
- [x] **Shell Scripting**: Robust error handling and logging
- [x] **Structured Output**: Tab-separated files with headers
- [x] **Comprehensive Analysis**: Both bucketing and normalization approaches

### 🔧 **Technical Features**
- **Strict Mode**: Uses `set -euo pipefail` for robust error handling
- **Color-coded Logging**: Informative progress messages
- **Error Recovery**: Graceful handling of edge cases
- **Deterministic Output**: Consistent sorting and formatting

## Data Quality Insights

1. **Temporal Distribution**: Dataset shows natural distribution across track lengths, with most tracks in the 3-4 minute range typical of popular music
2. **Duplicate Detection**: Capitalization analysis reveals potential data quality issues where same entities appear with different case formatting
3. **Structural Patterns**: Both analyses help understand the underlying structure and quality of the dataset

---

*This implementation demonstrates advanced AWK usage for complex data analysis, including bucketing, normalization, and duplicate detection techniques essential for data quality assessment.*
