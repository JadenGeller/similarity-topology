import SwiftUI
import SmallWorld
import GameplayKit

struct GraphView: View {
    let positions: [Int: CGPoint]
    let edges: [Int: Set<Int>]

    var body: some View {
        Canvas { context, size in
            // Draw edges
            for (point, connectedPoints) in edges {
                if let startPoint = positions[point] {
                    for connectedPoint in connectedPoints {
                        if let endPoint = positions[connectedPoint] {
                            var path = Path()
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                            context.stroke(path, with: .color(.black), lineWidth: 1)
                        }
                    }
                }
            }
            
            // Draw points
            for (id, position) in positions {
                context.fill(
                    Circle().path(in: CGRect(x: position.x - 5, y: position.y - 5, width: 10, height: 10)),
                    with: .color(.blue)
                )
                context.draw(Text("\(id)").bold().foregroundColor(.red), in: CGRect(x: position.x, y: position.y, width: 12, height: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//struct LayerVisualizerView: View {
//    var layer: InMemoryHierarchicalGraphStorage<Int>.Layer
//
//    var body: some View {
//        Canvas { canvas in
//            for node in layer.neighborhood {
//                canvas.draw
//            }
//        }
//    }
//}

struct VisualizerView: View {
    @State var graph = RandomGraph()
    @State var angle: Angle = .zero
    
    var body: some View {
        VStack {
            HStack {
                Button("Add Data") {
                    graph.insertRandomData(count: 1)
                }
                Slider(value: $angle.degrees, in: 0...89)
                    .frame(width: 100)
            }
            .padding()
            ScrollView {
                VStack {
                    ForEach(graph.graphStorage.layers, id: \.level) { layer in
                        GraphView(
                            positions: Dictionary(uniqueKeysWithValues: layer.neighborhood.keys.map { ($0, graph.vectorStorage[$0]!) }),
                            edges: layer.neighborhood
                        )
                        .rotation3DEffect(angle, axis: (1, 0, 0), perspective: 0)
                        .frame(width: 600, height: 600, alignment: .top)
                        .frame(width: 600, height: 600 * cos(angle.radians))
                        Divider()
                    }
                }
            }
        }
    }
}

@main
struct VisualizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            VisualizerView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}


// MARK: Utils


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


struct RandomGraph {
    let metric = CartesianDistanceMetric()
    let graphStorage: InMemoryHierarchicalGraphStorage<Int> = .init()
    var vectorStorage: [Int: CGPoint] = [:]
    var idAllocator = (0...).makeIterator()

    var hnsw: HierarchicalNavigableSmallWorld<InMemoryHierarchicalGraphStorage<Int>, CartesianDistanceMetric> {
        .init(
            graph: graphStorage,
            metric: metric,
            load: { vectorStorage[$0]! },
            config: .init(
                levelGenerationScale: 0.5,
                constructionSearchSize: 1000,
                maxNeighborsPerLayer: 4,
                maxNeighborsLayer0: 8,
                crowdToDensify: true
            )
        )
    }
    
    var hnswRNG = DeterministicRandomNumberGenerator(seed: 0)
    mutating func insertRandomData(count: Int) {
        for _ in 0..<count {
            let vector = randomData()
            let id = idAllocator.next()!
            vectorStorage[id] = vector
            hnsw.insert(vector, as: id, using: &hnswRNG)
        }
    }
    
    var sampleRNG = DeterministicRandomNumberGenerator(seed: 1)
    mutating func randomData() -> CGPoint {
        CGPoint(
            x: .random(in: (0)...(600), using: &sampleRNG),
            y: .random(in: (0)...(600), using: &sampleRNG)
        )
    }
    
    func findExact(around query: CGPoint) -> [(key: Int, value: CGPoint)] {
        Array(vectorStorage.sorted(by: { metric.similarity(between: query, $0.value) > metric.similarity(between: query, $1.value) }).prefix(10))
    }
}

struct CartesianDistanceMetric: SimilarityMetric {
    func similarity(between someItem: CGPoint, _ otherItem: CGPoint) -> Double {
        let dx = someItem.x - otherItem.x
        let dy = someItem.y - otherItem.y
        return -(dx * dx + dy * dy).squareRoot() // Negative because we want a smaller distance to be a higher priority
    }
}
