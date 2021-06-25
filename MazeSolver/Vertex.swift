public struct Vertex<T: Hashable> {
  var data: T
}

extension Vertex: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
    static public func ==(lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.data == rhs.data
    }
}

extension Vertex: CustomStringConvertible {
  public var description: String {
    return "\(data)"
  }
}
