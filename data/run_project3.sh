#!/bin/bash

TEAM_NAME="team02_sec2"
DATASET_FILE="ultimate-spotify-tracks-db"
OUT=out
cd /mnt/scratch/CS131_jelenag/projects/${TEAM_NAME}/
mkdir -p $OUT/data/outSpr3
SAMPLES=$OUT/data/outSpr3

# 1.Defining a two column edge list of Artist, Tracks.
# gawk was used given to us by the professor on discord
echo "Creating a two column edge list with Artists, Tracks"
unzip -p ultimate-spotify-tracks-db | gawk -v FPAT='([^,]+)|(\"([^\"]|\"\")*\")' -v OFS='\t' 'FNR>1{gsub(/^"|"$/,"",$2);gsub(/^"|"$/,"",$3);gsub(/""/,"\"",$2);gsub(/""/,"\"",$3);if($2!~/,/&&$3!~/,/)print $2,$3}' > edges.tsv

#2. Filter significant clusters n>= 51
echo "Filtering significant clusters"
cut -f1 edges.tsv | sort | uniq -c | sort -k1,1nr > entity_counts.tsv
awk '$1 > 50 { $1=""; sub(/^ +/, ""); print }' entity_counts.tsv > good_artists.txt
sort good_artists.txt > good_artists_sorted.tsv
sort -t $'\t' -k1,1 edges.tsv > edges_sorted.tsv
join -t $'\t' -1 1 -2 1 good_artists_sorted.tsv edges_sorted.tsv> edges_thresholded.tsv

#3 Histogram of cluster sizes
echo "Creating cluster sizes"
cut -f1 edges_thresholded.tsv | sort | uniq -c | awk '{num=$1; $1=""; sub(/^ +/, ""); print $1 "\t" num}' | sort -k2,2nr > cluster_sizes.tsv

echo ""
echo "=== STEP 4: Top-30 tokens inside clusters ==="
echo "Extracting top-30 most frequent track names from clusters..."

# Extract top-30 most frequent tracks from thresholded clusters
cut -f2 data/edges/edges_thresholded.tsv | sort | uniq -c | sort -nr | head -30 > top30_clusters.txt

# Extract top-30 most frequent tracks from overall dataset
cut -f2 data/edges/edges.tsv | sort | uniq -c | sort -nr | head -30 > top30_overall.txt

# Create comparison file
echo "=== TOP 30 IN CLUSTERS ===" > diff_top30.txt
cat top30_clusters.txt >> diff_top30.txt
echo -e "\n=== TOP 30 OVERALL ===" >> diff_top30.txt
cat top30_overall.txt >> diff_top30.txt

echo "Step 4 completed. Files created."

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
