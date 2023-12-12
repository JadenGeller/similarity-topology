/// A type that provides a way to measure the similarity between two items.
///
/// - Note: It is recommended that the similarity measure exhibits stability, where small changes
/// in an item do not result in large changes in similarity scores, and monotonicity, where the similarity
/// score decreases as items become less similar.
public protocol SimilarityMetric<Vector> {
    /// The type of items being compared for similarity.
    associatedtype Vector

    /// The type representing the similarity score between items.
    /// Must be comparable to allow for ordering of similarity scores.
    associatedtype Similarity: Comparable

    /// Computes the similarity score between two items.
    ///
    /// - Parameters:
    ///   - someItem: An item to compare.
    ///   - otherItem: Another item to compare.
    /// - Returns: A `Similarity` representing how similar the two items are.
    ///   A greater score indicates greater similarity.
    func similarity(between vector: Vector, _ other: Vector) -> Similarity
}
