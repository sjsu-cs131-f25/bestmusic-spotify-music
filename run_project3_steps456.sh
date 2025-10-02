#!/bin/bash
# Spotify Music Analysis - Steps 4, 5, and 6
# This script performs network analysis on Spotify artist-track relationships

echo "=== Spotify Music Analysis - Steps 4, 5, and 6 ==="
echo "Starting analysis at $(date)"

# Create output directory if it doesn't exist
mkdir -p data/out

echo ""
echo "=== STEP 4: Top-30 tokens inside clusters ==="
echo "Extracting top-30 most frequent track names from clusters..."

# Extract top-30 most frequent tracks from thresholded clusters
cut -f2 data/edges/edges_thresholded.tsv | sort | uniq -c | sort -nr | head -30 > data/out/top30_clusters.txt

# Extract top-30 most frequent tracks from overall dataset
cut -f2 data/edges/edges.tsv | sort | uniq -c | sort -nr | head -30 > data/out/top30_overall.txt

# Create comparison file
echo "=== TOP 30 IN CLUSTERS ===" > data/out/diff_top30.txt
cat data/out/top30_clusters.txt >> data/out/diff_top30.txt
echo -e "\n=== TOP 30 OVERALL ===" >> data/out/diff_top30.txt
cat data/out/top30_overall.txt >> data/out/diff_top30.txt

echo "Step 4 completed. Files created:"
echo "  - data/out/top30_clusters.txt"
echo "  - data/out/top30_overall.txt" 
echo "  - data/out/diff_top30.txt"

echo ""
echo "=== STEP 5: Network visualization ==="
echo "Creating network visualization of artist-track clusters..."

# Check if Python packages are available
python3 -c "import networkx, matplotlib, pandas, scipy" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing required Python packages..."
    pip3 install networkx matplotlib pandas scipy
fi

# Run network visualization script
python3 create_network_viz.py

echo "Step 5 completed. Files created:"
echo "  - data/out/cluster_viz.png"
echo "  - data/out/cluster_viz_small.png"

echo ""
echo "=== STEP 6: Summary statistics about clusters ==="
echo "Computing summary statistics grouped by artist cluster anchor..."

# Run summary statistics script
python3 create_summary_stats.py

echo "Step 6 completed. Files created:"
echo "  - data/out/cluster_outcomes.tsv"
echo "  - data/out/cluster_outcomes_simple.tsv"
echo "  - data/out/cluster_outcomes_plot.png"

echo ""
echo "=== ANALYSIS COMPLETE ==="
echo "All steps completed at $(date)"
echo ""
echo "Summary of deliverables:"
echo "Step 4:"
echo "  - top30_clusters.txt: Top-30 most frequent tracks in clusters"
echo "  - top30_overall.txt: Top-30 most frequent tracks overall"
echo "  - diff_top30.txt: Comparison between cluster and overall top-30"
echo ""
echo "Step 5:"
echo "  - cluster_viz.png: Network visualization of top 20 artists"
echo "  - cluster_viz_small.png: Network visualization of top 5 artists"
echo ""
echo "Step 6:"
echo "  - cluster_outcomes.tsv: Detailed summary statistics by artist"
echo "  - cluster_outcomes_simple.tsv: Simplified summary (count, mean, median)"
echo "  - cluster_outcomes_plot.png: Visualization of summary statistics"
