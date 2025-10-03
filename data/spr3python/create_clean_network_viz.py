#!/usr/bin/env python3
"""
Clean network visualization script for Spotify artist-track clusters
Creates a much more readable visualization with better layout and filtering
"""

import networkx as nx
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

def create_clean_network_visualization():
    """Create a clean, readable network visualization"""
    
    print("Reading thresholded edges...")
    edges_df = pd.read_csv('data/edges/edges_thresholded.tsv', sep='\t', header=None, names=['artist', 'track'])
    
    # Get top 3 artists for a very clean visualization
    top_artists = edges_df['artist'].value_counts().head(3)
    print(f"Top 3 artists: {top_artists.index.tolist()}")
    
    # Filter to only these 3 artists
    filtered_edges = edges_df[edges_df['artist'].isin(top_artists.index)]
    
    # Sample tracks to avoid overcrowding (max 20 tracks per artist)
    sampled_edges = []
    for artist in top_artists.index:
        artist_tracks = filtered_edges[filtered_edges['artist'] == artist]
        # Take up to 20 tracks per artist
        sampled_tracks = artist_tracks.sample(n=min(20, len(artist_tracks)), random_state=42)
        sampled_edges.append(sampled_tracks)
    
    sampled_edges_df = pd.concat(sampled_edges, ignore_index=True)
    
    # Create network graph
    G = nx.Graph()
    for _, row in sampled_edges_df.iterrows():
        G.add_edge(row['artist'], row['track'])
    
    print(f"Clean graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
    
    # Create a much cleaner visualization
    plt.figure(figsize=(16, 12))
    
    # Use a better layout algorithm
    pos = nx.spring_layout(G, k=4, iterations=100, seed=42)
    
    # Separate artist and track nodes
    artist_nodes = [node for node in G.nodes() if node in top_artists.index]
    track_nodes = [node for node in G.nodes() if node not in top_artists.index]
    
    # Draw artist nodes (large, prominent)
    nx.draw_networkx_nodes(G, pos, nodelist=artist_nodes, 
                          node_color='red', node_size=800, alpha=0.9, 
                          edgecolors='black', linewidths=2)
    
    # Draw track nodes (smaller, different color)
    nx.draw_networkx_nodes(G, pos, nodelist=track_nodes, 
                          node_color='lightblue', node_size=100, alpha=0.7,
                          edgecolors='darkblue', linewidths=0.5)
    
    # Draw edges with better styling
    nx.draw_networkx_edges(G, pos, alpha=0.6, width=1.5, edge_color='gray')
    
    # Add labels for artists (large, bold)
    artist_labels = {node: node for node in artist_nodes}
    nx.draw_networkx_labels(G, pos, artist_labels, font_size=14, font_weight='bold', 
                           font_color='white', bbox=dict(boxstyle="round,pad=0.3", facecolor='red', alpha=0.8))
    
    # Add some track labels (sample a few)
    if len(track_nodes) > 0:
        sample_tracks = np.random.choice(track_nodes, min(10, len(track_nodes)), replace=False)
        track_labels = {track: track for track in sample_tracks}
        nx.draw_networkx_labels(G, pos, track_labels, font_size=8, font_color='darkblue',
                               bbox=dict(boxstyle="round,pad=0.1", facecolor='lightblue', alpha=0.7))
    
    plt.title('Spotify Artist-Track Network (Top 3 Artists)\nClean Visualization', 
              fontsize=18, fontweight='bold', pad=20)
    
    # Add legend
    from matplotlib.patches import Patch
    legend_elements = [Patch(facecolor='red', label='Artists'),
                      Patch(facecolor='lightblue', label='Tracks')]
    plt.legend(handles=legend_elements, loc='upper right', fontsize=12)
    
    plt.axis('off')
    plt.tight_layout()
    
    # Save the clean plot
    plt.savefig('data/out/cluster_viz_clean.png', dpi=300, bbox_inches='tight')
    print("Clean network visualization saved to data/out/cluster_viz_clean.png")
    
    # Also create a simple bar chart showing track counts
    plt.figure(figsize=(12, 8))
    
    # Create a subplot for track counts
    plt.subplot(2, 2, 1)
    track_counts = sampled_edges_df['artist'].value_counts()
    bars = plt.bar(range(len(track_counts)), track_counts.values, color=['red', 'blue', 'green'])
    plt.xlabel('Artists')
    plt.ylabel('Number of Tracks (Sampled)')
    plt.title('Track Counts per Artist')
    plt.xticks(range(len(track_counts)), track_counts.index, rotation=45)
    
    # Add value labels on bars
    for i, bar in enumerate(bars):
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2., height + 0.5,
                f'{int(height)}', ha='center', va='bottom')
    
    # Create a simple network diagram (much simpler)
    plt.subplot(2, 2, 2)
    
    # Create a simple bipartite layout
    artist_y = 1
    track_y = 0
    
    # Position artists
    artist_positions = {}
    for i, artist in enumerate(artist_nodes):
        artist_positions[artist] = (i * 2, artist_y)
    
    # Position tracks
    track_positions = {}
    tracks_per_artist = len(track_nodes) // len(artist_nodes)
    for i, track in enumerate(track_nodes):
        artist_idx = i // tracks_per_artist
        track_positions[track] = (artist_idx * 2 + (i % tracks_per_artist) * 0.3, track_y)
    
    # Draw simple network
    for artist in artist_nodes:
        plt.scatter(*artist_positions[artist], s=200, c='red', alpha=0.8, edgecolors='black')
        plt.text(*artist_positions[artist], artist, ha='center', va='bottom', fontweight='bold')
    
    for track in track_nodes:
        plt.scatter(*track_positions[track], s=50, c='lightblue', alpha=0.7, edgecolors='darkblue')
    
    # Draw connections
    for _, row in sampled_edges_df.iterrows():
        artist_pos = artist_positions[row['artist']]
        track_pos = track_positions[row['track']]
        plt.plot([artist_pos[0], track_pos[0]], [artist_pos[1], track_pos[1]], 
                'k-', alpha=0.3, linewidth=0.5)
    
    plt.title('Simplified Network View')
    plt.axis('off')
    
    # Add summary statistics
    plt.subplot(2, 2, 3)
    plt.text(0.1, 0.8, f"Total Artists: {len(artist_nodes)}", fontsize=12, transform=plt.gca().transAxes)
    plt.text(0.1, 0.7, f"Total Tracks: {len(track_nodes)}", fontsize=12, transform=plt.gca().transAxes)
    plt.text(0.1, 0.6, f"Total Connections: {G.number_of_edges()}", fontsize=12, transform=plt.gca().transAxes)
    plt.text(0.1, 0.5, f"Avg Tracks per Artist: {len(track_nodes)/len(artist_nodes):.1f}", fontsize=12, transform=plt.gca().transAxes)
    plt.title('Network Statistics')
    plt.axis('off')
    
    # Add track list
    plt.subplot(2, 2, 4)
    sample_tracks = track_nodes[:15]  # Show first 15 tracks
    track_text = '\n'.join([f"• {track}" for track in sample_tracks])
    if len(track_nodes) > 15:
        track_text += f"\n... and {len(track_nodes) - 15} more"
    plt.text(0.05, 0.95, track_text, fontsize=8, transform=plt.gca().transAxes, 
             verticalalignment='top', fontfamily='monospace')
    plt.title('Sample Tracks')
    plt.axis('off')
    
    plt.tight_layout()
    plt.savefig('data/out/cluster_viz_dashboard.png', dpi=300, bbox_inches='tight')
    print("Dashboard visualization saved to data/out/cluster_viz_dashboard.png")

if __name__ == "__main__":
    create_clean_network_visualization()
