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

echo "Done."

