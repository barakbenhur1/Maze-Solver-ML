import UIKit

public struct Stack<T: Hashable> {
  fileprivate var array: [T] = []
  
  public init() {}
  
  public mutating func push(_ element: T) {
    array.append(element)
  }
    
    public mutating func pop() -> T? {
        return array.popLast()
    }
    
    public mutating func queuePop() -> T? {
        return array.isEmpty ? nil : array.removeFirst()
    }
    
    public func peekFirst() -> T? {
        return array.isEmpty ? nil : array[0]
    }
    
    public mutating func filter() {
        var set = [T]()
        for item in array {
            if !set.contains(item) {
                set.append(item)
            }
            else {
                break
            }
        }
        
        array = Array(set)
    }

    
    subscript(i: Int) -> T {
        return array[i]
    }
    
    public func peek() -> T? {
        return array.last
    }
    
    public func isEmpty() -> Bool {
        return array.isEmpty
    }
    
    public func count() -> Int {
        return array.count 
    }
    
    public func contains(item: T) -> Bool {
        return array.contains(item)
    }
}

extension Stack: CustomStringConvertible {
  public var description: String {
    let topDivider = "---Stack---\n"
    let bottomDivider = "\n-----------\n"
    
    let stackElements = array.map { "\($0)" }.reversed().joined(separator: "\n")
    return topDivider + stackElements + bottomDivider
  }
}
