import SwiftUI
import HNSW
import HNSWExtras

struct GraphView: View {
    let points: [(Int, CGPoint)]
    let edges: [(CGPoint, CGPoint)]

    var body: some View {
        Canvas { context, size in
            for (startPoint, endPoint) in edges {
                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)
                context.stroke(path, with: .color(.black), lineWidth: 1)
            }
            
            for (id, point) in points {
                context.fill(
                    Circle().path(in: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)),
                    with: .color(.blue)
                )
                context.draw(Text("\(id)").bold().foregroundColor(.red), in: CGRect(x: point.x, y: point.y, width: 20, height: 20))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension DeterministicSampleVectorIndex {
    func points(for level: Int) -> [(Int, CGPoint)] {
        base.graph.keys(on: level).map { id in
            (id, base.vectors[id])
        }
    }
    func edges(for level: Int) -> [(CGPoint, CGPoint)] {
        base.graph.keys(on: level).flatMap { id in
            base.graph.neighborhood(on: level, around: id).map { neighbor in
                return (base.vectors[id], base.vectors[neighbor])
            }
        }
    }
}

struct VisualizerView: View {
    @State var index = DeterministicSampleVectorIndex(typicalNeighborhoodSize: 6)
    @State var angle: Angle = .zero
    @State var updateCount = 0 // since index isn't observable!
    
    var body: some View {
        VStack {
            HStack {
                Button("Add Data") {
                    index.insertRandom(range: 0...500)
                    updateCount += 1
                }
                Slider(value: $angle.degrees, in: 0...89)
                    .frame(width: 100)
            }
            .padding()
            ScrollView {
                VStack {
                    let graph = index.base.graph
                    ForEach(Array(sequence(state: graph.entry?.level, next: graph.descend)), id: \.self) { level in
                        let _ = updateCount // to force an update
                        Text("Level \(String(level))")
                        GraphView(
                            points: index.points(for: level),
                            edges: index.edges(for: level)
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
