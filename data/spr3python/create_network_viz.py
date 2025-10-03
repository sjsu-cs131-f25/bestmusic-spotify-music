#!/usr/bin/env python3
"""
Network visualization script for Spotify artist-track clusters
Creates a visualization of a subset of the thresholded edges
"""

import networkx as nx
import matplotlib.pyplot as plt
import pandas as pd
from collections import Counter

def create_network_visualization():
    """Create network visualization of artist-track clusters"""
    
    # Read the thresholded edges
    print("Reading thresholded edges...")
    edges_df = pd.read_csv('data/edges/edges_thresholded.tsv', sep='\t', header=None, names=['artist', 'track'])
    
    # Get the top 20 artists by number of tracks for visualization
    top_artists = edges_df['artist'].value_counts().head(20)
    print(f"Top artists by track count: {top_artists.head()}")
    
    # Filter edges to only include top artists
    filtered_edges = edges_df[edges_df['artist'].isin(top_artists.index)]
    
    # Create network graph
    G = nx.Graph()
    
    # Add edges
    for _, row in filtered_edges.iterrows():
        G.add_edge(row['artist'], row['track'])
    
    print(f"Graph created with {G.number_of_nodes()} nodes and {G.number_of_edges()} edges")
    
    # Create visualization
    plt.figure(figsize=(15, 12))
    
    # Use spring layout for better visualization
    pos = nx.spring_layout(G, k=3, iterations=50)
    
    # Draw nodes with different colors for artists vs tracks
    artist_nodes = [node for node in G.nodes() if node in top_artists.index]
    track_nodes = [node for node in G.nodes() if node not in top_artists.index]
    
    # Draw artist nodes (larger, different color)
    nx.draw_networkx_nodes(G, pos, nodelist=artist_nodes, 
                          node_color='red', node_size=100, alpha=0.8, label='Artists')
    
    # Draw track nodes (smaller, different color)
    nx.draw_networkx_nodes(G, pos, nodelist=track_nodes, 
                          node_color='lightblue', node_size=20, alpha=0.6, label='Tracks')
    
    # Draw edges
    nx.draw_networkx_edges(G, pos, alpha=0.3, width=0.5)
    
    # Add labels only for artists (to avoid clutter)
    artist_labels = {node: node for node in artist_nodes}
    nx.draw_networkx_labels(G, pos, artist_labels, font_size=8, font_weight='bold')
    
    plt.title('Spotify Artist-Track Network Visualization\n(Top 20 Artists by Track Count)', 
              fontsize=16, fontweight='bold')
    plt.legend()
    plt.axis('off')
    plt.tight_layout()
    
    # Save the plot
    plt.savefig('data/out/cluster_viz.png', dpi=300, bbox_inches='tight')
    print("Network visualization saved to data/out/cluster_viz.png")
    
    # Also create a smaller subset for better readability
    print("\nCreating smaller subset visualization...")
    
    # Take top 5 artists for a cleaner view
    top_5_artists = top_artists.head(5)
    small_edges = edges_df[edges_df['artist'].isin(top_5_artists.index)]
    
    G_small = nx.Graph()
    for _, row in small_edges.iterrows():
        G_small.add_edge(row['artist'], row['track'])
    
    plt.figure(figsize=(12, 10))
    pos_small = nx.spring_layout(G_small, k=2, iterations=50)
    
    artist_nodes_small = [node for node in G_small.nodes() if node in top_5_artists.index]
    track_nodes_small = [node for node in G_small.nodes() if node not in top_5_artists.index]
    
    nx.draw_networkx_nodes(G_small, pos_small, nodelist=artist_nodes_small, 
                          node_color='red', node_size=200, alpha=0.8)
    nx.draw_networkx_nodes(G_small, pos_small, nodelist=track_nodes_small, 
                          node_color='lightblue', node_size=30, alpha=0.6)
    nx.draw_networkx_edges(G_small, pos_small, alpha=0.4, width=0.8)
    
    # Add labels for artists
    artist_labels_small = {node: node for node in artist_nodes_small}
    nx.draw_networkx_labels(G_small, pos_small, artist_labels_small, font_size=10, font_weight='bold')
    
    plt.title('Spotify Artist-Track Network (Top 5 Artists)', fontsize=14, fontweight='bold')
    plt.axis('off')
    plt.tight_layout()
    
    plt.savefig('data/out/cluster_viz_small.png', dpi=300, bbox_inches='tight')
    print("Small network visualization saved to data/out/cluster_viz_small.png")

if __name__ == "__main__":
    create_network_visualization()
