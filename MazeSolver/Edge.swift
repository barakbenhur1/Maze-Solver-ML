
public enum EdgeType {
  case directed, undirected
}

public struct Edge<T: Hashable> {
  public var source: Vertex<T>
  public var destination: Vertex<T>
  public let weight: Double?
}

extension Edge: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(destination)
        hasher.combine(weight)
    }
    
    static public func ==(lhs: Edge<T>, rhs: Edge<T>) -> Bool {
        return lhs.source == rhs.source &&
            lhs.destination == rhs.destination &&
            lhs.weight == rhs.weight
    }
}
