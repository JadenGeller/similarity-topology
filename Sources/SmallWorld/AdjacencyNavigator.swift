/// A protocol for navigating through vertices based on their adjacency.
public protocol AdjacencyNavigator<VertexID> {
    /// The type of vertex being navigated.
    associatedtype VertexID
    
    /// A sequence of vertices considered adjacent to a reference vertex.
    associatedtype Neighborhood: Sequence where Neighborhood.Element == VertexID

    /// Retrieves a sequence of items adjacent to the specified item.
    ///
    /// - Parameter vertex: The vertex around which to find adjacent items.
    /// - Returns: A sequence of items adjacent to the query item.
    func neighborhood(around vertex: VertexID) -> Neighborhood
}
