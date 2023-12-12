import RealModule

public struct Config {
    public var insertionLevelGenerationLogScale: Double
    public var constructionSearchCapacity: Int
    public var maxNeighborhoodSizeCreate: Int
    public var maxNeighborhoodSizeLevelN: Int
    public var maxNeighborhoodSizeLevel0: Int
    public var considerExtendedNeighbors: Bool
    public enum NeighborhoodPreference {
        case preferDensity
        case preferEfficiency
    }
    public var neighborhoodPreference: NeighborhoodPreference

    public init(
        insertionLevelGenerationLogScale: Double,
        constructionSearchCapacity: Int,
        maxNeighborhoodSizeCreate: Int,
        maxNeighborhoodSizeLevelN: Int,
        maxNeighborhoodSizeLevel0: Int,
        considerExtendedNeighbors: Bool,
        neighborhoodPreference: NeighborhoodPreference
    ) {
        self.insertionLevelGenerationLogScale = insertionLevelGenerationLogScale
        self.constructionSearchCapacity = constructionSearchCapacity
        self.maxNeighborhoodSizeCreate = maxNeighborhoodSizeCreate
        self.maxNeighborhoodSizeLevelN = maxNeighborhoodSizeLevelN
        self.maxNeighborhoodSizeLevel0 = maxNeighborhoodSizeLevel0
        self.considerExtendedNeighbors = considerExtendedNeighbors
        self.neighborhoodPreference = neighborhoodPreference
    }
}

extension Config {
    // https://github.com/rust-cv/hnsw/blob/master/implementation.md
    public static func unstableDefault(typicalNeighborhoodSize: Int = 48) -> Self {
        .init(
            insertionLevelGenerationLogScale: 1 / .log(Double(typicalNeighborhoodSize)),
            constructionSearchCapacity: 100,
            maxNeighborhoodSizeCreate: typicalNeighborhoodSize,
            maxNeighborhoodSizeLevelN: typicalNeighborhoodSize,
            maxNeighborhoodSizeLevel0: 2 * typicalNeighborhoodSize,
            considerExtendedNeighbors: false,
            neighborhoodPreference: .preferDensity
        )
    }
}
