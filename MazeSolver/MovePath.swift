//
//  MovePath.swift
//  Defence Grid Creator
//
//  Created by Interactech on 24/06/2021.
//

import UIKit
import BbhGMl

public enum Direction: Encodable & Decodable {
    
    enum CodingKeys: String, CodingKey {
        case dir
    }
    
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
        case unknownValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .up
        case 1:
            self = .down
        case 2:
            self = .left
        case 3:
            self = .right
        case 4:
            self = .upLeft
        case 5:
            self = .upRight
        case 6:
            self = .downLeft
        case 7:
            self = .downRight
        default:
            throw CodingError.unknownValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .up:
            try container.encode(0, forKey: .rawValue)
        case .down:
            try container.encode(1, forKey: .rawValue)
        case .left:
            try container.encode(2, forKey: .rawValue)
        case .right:
            try container.encode(3, forKey: .rawValue)
        case .upLeft:
            try container.encode(4, forKey: .rawValue)
        case .upRight:
            try container.encode(5, forKey: .rawValue)
        case .downLeft:
            try container.encode(6, forKey: .rawValue)
        case .downRight:
            try container.encode(7, forKey: .rawValue)
        case .stay:
            try container.encode(-1, forKey: .rawValue)
        }
    }
    
    public func printDescription() {
        print(self)
    }
    
    case up, down, left, right, upLeft, upRight, downLeft, downRight, stay
}

final class MovePath: DNA & Hashable & Decodable {
    
    private var maxNumberOfSteps: Int!
    
    private var index: Int = 0
    
    var start: CGPoint!
    
    var current: CGPoint!

    var directions: [Direction]!
    
    var allDirections: [Direction]!
    
    init() {
        directions = []
        allDirections = []
        start = .zero
        current = .zero
        maxNumberOfSteps = 0
        index = 0
    }
    
    required init(copy: MovePath) {
        index = 0
        directions = [Direction](copy.directions)
        current = CGPoint(x: copy.current.x, y: copy.current.y)
        start = CGPoint(x: copy.start.x, y: copy.start.y)
        allDirections = [Direction](copy.allDirections)
        maxNumberOfSteps = allDirections.count
    }
    
    init(maxNumberOfSteps: Int) {
        self.maxNumberOfSteps = maxNumberOfSteps
        let path = MovePath.random(length: maxNumberOfSteps, extra: nil)
        self.directions = path.directions
        self.current = path.current
        self.start = path.start
        self.allDirections = path.allDirections
        self.maxNumberOfSteps = path.allDirections.count
        self.index = 0
    }
    
    func cleanBetweenGens() {
        index = 0
    }
    
    func getNextStep() -> Direction {
        let dir = allDirections[index]
        dir.printDescription()
        
        index += 1
        
        index = min(index, maxNumberOfSteps)
        
        index %= maxNumberOfSteps
        
        return dir
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }

    func length() -> Int {
        return allDirections.count
    }
    
    func calcFitness(val: MovePath?, best: CGFloat) -> (val: CGFloat, count: CGFloat) {
        return (1 / (distance(from: current, to: val!.current) * (CGFloat(index) + 1)) * best, CGFloat(allDirections.count))
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }
    
    func mutate(rate: CGFloat) -> MovePath {
        for i in 0..<allDirections.count {
            let r = CGFloat.random(in: 0...1)
            
            if r < rate {
                allDirections[i] = MovePath.random(length: 1, extra: nil).allDirections.first!
            }
        }
        
        return self
    }
    
    func find(target: MovePath, count: CGFloat) -> Bool {
        return current == target.current
    }
    
    func elementsEqual(_ other: MovePath) -> Bool {
        return self == other
    }
    
    static func random(length: Int, extra: Any?) -> MovePath {
        let selections: [Direction] = [.up, .down, .left, .right, .upLeft, .upRight, .downLeft, .downRight]
        var directions: [Direction] = [Direction]()
        
        for _ in 0..<length {
            directions.append(selections[Int.random(in: 0..<selections.count)])
        }
        
        let movePath =  MovePath()
        movePath.directions.append(contentsOf: directions)
        movePath.allDirections.append(contentsOf: directions)
        movePath.start = extra != nil ? (extra as! [CGPoint]).first : .zero
        movePath.current = extra != nil ? (extra as! [CGPoint]).first : .zero
        movePath.maxNumberOfSteps = length
        movePath.index = 0
        
        return movePath
    }
    
    subscript(offset: Int) -> MovePath {
        get {
            let movePath = MovePath(copy: self)
            movePath.allDirections = [allDirections[offset]]
            return movePath
        }
        set(newValue) {
            allDirections[offset] = newValue.allDirections[offset]
        }
    }
    
    static func +=(lhs: inout MovePath, rhs: MovePath) {
        lhs.current =  CGPoint(x: rhs.current.x, y: rhs.current.y)
        lhs.allDirections.append(contentsOf: rhs.allDirections)
        lhs.directions = [Direction](lhs.allDirections)
        lhs.start = CGPoint(x: rhs.start.x, y: rhs.start.y)
    }
    
//    static func += (lhs: inout MovePath, rhs: Chromosome) {
//        lhs.directions.append(rhs as! Direction)
//    }

//    static func emptyChromosome() -> Chromosome {
//        return Direction.stay
//    }
//
    
    static func empty() -> MovePath {
        return MovePath()
    }
    
    static func == (lhs: MovePath, rhs: MovePath) -> Bool {
        guard lhs.allDirections.count == rhs.allDirections.count else { return false }
        for i in 0..<lhs.allDirections.count {
            if lhs.allDirections[i] != rhs.allDirections[i] {
                return false
            }
        }
        return true
    }
}
