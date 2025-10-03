#!/bin/bash
# run_project2.sh
# 
# The dataset is defined by the DATASET_FILE variable as referenced from the
# slides. The delimiter of our files is all commas, but it causes some issues
# when columns use commas within them. 
# To fix this, we are temporarily dropping all rows with an excess column count
# by checking for commas in quotations, as that is the exclusive scenario where
# they occur.
# The assumptions for this file is that the data will all be stored in the "out"
# folder, and the random samples will be stored in the out/data/samples folder.

TEAM_NAME="team02_sec2"
DATASET_FILE="ultimate-spotify-tracks-db"
OUT=out
cd /mnt/scratch/CS131_jelenag/projects/${TEAM_NAME}/
mkdir -p $OUT/data/samples
SAMPLES=$OUT/data/samples

# 1. Creating the ~1k Sample
# It is less for us because some column entries have commas inside of them, 
# causing errors. To avoid this, we have to create a filtered version with grep.
echo "Creating 1k Sample (Filtered) with Header"
(unzip -p $DATASET_FILE | head -n1 && unzip -p $DATASET_FILE | tail -n +2 | shuf -n 1000) > $SAMPLES/Spotify_Random_1k.csv 2> $OUT/errors.txt

echo "Filtering Sample"
grep -vi '".*,.*"' $SAMPLES/Spotify_Random_1k.csv > $SAMPLES/Spotify_Filtered_1k.csv

#2. Frequency Tables
echo "Writing Frequency Table for Genre"
cut -d, -f1 $SAMPLES/Spotify_Filtered_1k.csv | sort | uniq -c | sort -nr | tee $OUT/freq_genre.txt

echo "Writing Frequency Table for Artists"
cut -d, -f2 $SAMPLES/Spotify_Filtered_1k.csv | sort | uniq -c | sort -nr | tee $OUT/freq_artists.txt

#3. Top-N List
echo "Writing Top 10 List for Tempo"
cut -d, -f3,16 $SAMPLES/Spotify_Filtered_1k.csv | tail -n +2 | sort -t, -k2 -nr | head -10 | tee $OUT/top_tempo.txt

#4. "Skinny" Table
echo "Writing Skinny Table for Artists and Popularity"
cut -d, -f2,5 $SAMPLES/Spotify_Filtered_1k.csv | sort -t, -k2 -nru | tee $OUT/artist_pop.txt

# Steps 4, 5, 6: Network Analysis (Project 3)
echo ""
echo "=== PROJECT 3: NETWORK ANALYSIS STEPS 4, 5, 6 ==="

# Check if we have the required files from previous steps
if [ ! -f "data/edges/edges_thresholded.tsv" ]; then
    echo "Error: edges_thresholded.tsv not found. Please run steps 1-3 first."
    exit 1
fi

# Step 4: Top-30 tokens inside clusters
echo "Step 4: Extracting top-30 most frequent track names from clusters..."
cut -f2 data/edges/edges_thresholded.tsv | sort | uniq -c | sort -nr | head -30 > $OUT/top30_clusters.txt

echo "Extracting top-30 most frequent track names from overall dataset..."
cut -f2 data/edges/edges.tsv | sort | uniq -c | sort -nr | head -30 > $OUT/top30_overall.txt

echo "Creating comparison file..."
echo "=== TOP 30 IN CLUSTERS ===" > $OUT/diff_top30.txt
cat $OUT/top30_clusters.txt >> $OUT/diff_top30.txt
echo -e "\n=== TOP 30 OVERALL ===" >> $OUT/diff_top30.txt
cat $OUT/top30_overall.txt >> $OUT/diff_top30.txt

# Step 5: Network visualization
echo "Step 5: Creating network visualization..."
# Check if Python packages are available
python3 -c "import networkx, matplotlib, pandas, scipy" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing required Python packages..."
    pip3 install networkx matplotlib pandas scipy
fi

# Run network visualization script
python3 create_network_viz.py

# Step 6: Summary statistics about clusters
echo "Step 6: Computing summary statistics grouped by artist cluster anchor..."
python3 create_summary_stats.py

echo ""
echo "=== PROJECT 3 COMPLETE ==="
echo "All deliverables created in $OUT/ directory:"
echo "  - top30_clusters.txt, top30_overall.txt, diff_top30.txt"
echo "  - cluster_viz.png, cluster_viz_clean.png, cluster_viz_dashboard.png"
echo "  - cluster_outcomes.tsv, cluster_outcomes_simple.tsv, cluster_outcomes_plot.png"

echo ""
echo "Done."

