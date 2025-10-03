#!/usr/bin/env python3
"""
Summary statistics script for Spotify artist clusters
Computes summary statistics grouped by artist (cluster anchor) using track popularity
"""

import pandas as pd
import numpy as np

def create_summary_statistics():
    """Create summary statistics grouped by artist cluster anchor"""
    
    print("Reading thresholded edges...")
    # Read the thresholded edges
    edges_df = pd.read_csv('data/edges/edges_thresholded.tsv', sep='\t', header=None, names=['artist', 'track'])
    
    print("Reading original Spotify dataset...")
    # Read the original dataset
    spotify_df = pd.read_csv('data/samples/Spotify_Filtered_1k.csv')
    
    print("Joining edges with original dataset...")
    # Join the thresholded edges with the original dataset on track_name
    # We need to match track names between the two datasets
    merged_df = edges_df.merge(spotify_df, left_on='track', right_on='track_name', how='inner')
    
    print(f"Successfully joined {len(merged_df)} records")
    
    # Group by artist and compute summary statistics for popularity
    print("Computing summary statistics by artist...")
    summary_stats = merged_df.groupby('artist')['popularity'].agg([
        'count',    # number of tracks
        'mean',     # average popularity
        'median',   # median popularity
        'std',      # standard deviation
        'min',      # minimum popularity
        'max'       # maximum popularity
    ]).round(2)
    
    # Reset index to make artist a column
    summary_stats = summary_stats.reset_index()
    
    # Rename columns for clarity
    summary_stats.columns = ['artist', 'track_count', 'mean_popularity', 'median_popularity', 
                           'std_popularity', 'min_popularity', 'max_popularity']
    
    # Sort by track count (descending)
    summary_stats = summary_stats.sort_values('track_count', ascending=False)
    
    print("Top 10 artists by track count:")
    print(summary_stats.head(10))
    
    # Save to TSV file
    output_file = 'data/out/cluster_outcomes.tsv'
    summary_stats.to_csv(output_file, sep='\t', index=False)
    print(f"\nSummary statistics saved to {output_file}")
    
    # Also create a simplified version with just count, mean, median as required
    simple_stats = summary_stats[['artist', 'track_count', 'mean_popularity', 'median_popularity']].copy()
    simple_stats.columns = ['artist', 'count', 'mean', 'median']
    
    simple_output_file = 'data/out/cluster_outcomes_simple.tsv'
    simple_stats.to_csv(simple_output_file, sep='\t', index=False)
    print(f"Simplified summary statistics saved to {simple_output_file}")
    
    # Create a summary plot
    print("\nCreating summary statistics plot...")
    import matplotlib.pyplot as plt
    
    # Plot 1: Track count distribution
    plt.figure(figsize=(15, 5))
    
    plt.subplot(1, 3, 1)
    plt.hist(summary_stats['track_count'], bins=20, edgecolor='black', alpha=0.7)
    plt.xlabel('Number of Tracks per Artist')
    plt.ylabel('Number of Artists')
    plt.title('Distribution of Track Counts per Artist')
    
    # Plot 2: Mean popularity vs track count
    plt.subplot(1, 3, 2)
    plt.scatter(summary_stats['track_count'], summary_stats['mean_popularity'], alpha=0.6)
    plt.xlabel('Number of Tracks')
    plt.ylabel('Mean Popularity')
    plt.title('Track Count vs Mean Popularity')
    
    # Plot 3: Top 15 artists by track count
    plt.subplot(1, 3, 3)
    top_15 = summary_stats.head(15)
    plt.barh(range(len(top_15)), top_15['track_count'])
    plt.yticks(range(len(top_15)), top_15['artist'], fontsize=8)
    plt.xlabel('Number of Tracks')
    plt.title('Top 15 Artists by Track Count')
    plt.gca().invert_yaxis()
    
    plt.tight_layout()
    plt.savefig('data/out/cluster_outcomes_plot.png', dpi=300, bbox_inches='tight')
    print("Summary statistics plot saved to data/out/cluster_outcomes_plot.png")
    
    # Print some insights
    print("\n=== SUMMARY INSIGHTS ===")
    print(f"Total artists in clusters: {len(summary_stats)}")
    print(f"Total tracks in clusters: {summary_stats['track_count'].sum()}")
    print(f"Average tracks per artist: {summary_stats['track_count'].mean():.1f}")
    print(f"Artist with most tracks: {summary_stats.iloc[0]['artist']} ({summary_stats.iloc[0]['track_count']} tracks)")
    print(f"Highest mean popularity: {summary_stats['mean_popularity'].max():.1f} ({summary_stats.loc[summary_stats['mean_popularity'].idxmax(), 'artist']})")
    print(f"Lowest mean popularity: {summary_stats['mean_popularity'].min():.1f} ({summary_stats.loc[summary_stats['mean_popularity'].idxmin(), 'artist']})")

if __name__ == "__main__":
    create_summary_statistics()
