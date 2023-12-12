# Similarity Topology

## Introduction

`similarity-topology` provides algorithms that maintain indexes for efficient nearest neighbor searches of high dimensional data.

## HNSW Index

The Hierarchical Navigable Small World (HNSW) index constructs a multi-layer graph that resembles a skip-list. Search begins at the top layer---which has the fewest elements---and greedily traverses that layer of the graph for the element with greatest similarity to the search query. The search the continues on the layer beneath, repeating this algorithm until the bottom layer is searched.

It's important to note that HNSW indexes do not support deletion! If you need to remove elements, you must rebuild the entire index from scratch!

### Modules

- **HNSWAlgorithm**: An implementation of the HNSW algorithm, generic on the paricular `GraphManager` storage.
- **HNSWDurable**: An implementation of a HNSW `GraphManager` that uses LMDB for storage.

For those interested in the theoretical underpinnings of the HNSW algorithm, the [original research paper](https://arxiv.org/abs/1603.09320) is an excellent resource.

## Installation

To add `similarity-topology` to your project, include it in your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/similarity-topology.git", from: <#version#>)
]
```
