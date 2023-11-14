import GameplayKit

struct DeterministicRandomNumberGenerator: RandomNumberGenerator {
    private let randomSource: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        randomSource = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let upperBits = UInt64(UInt32(bitPattern: Int32(randomSource.nextInt()))) << 32
        let lowerBits = UInt64(UInt32(bitPattern: Int32(randomSource.nextInt())))
        return upperBits | lowerBits
    }
}
