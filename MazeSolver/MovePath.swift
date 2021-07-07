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
    
    func getOpposite() -> Direction {
        switch self {
        case .up:
            return .down
        case .down:
            return .up
        case .left:
            return .right
        case .right:
            return .left
        case .upLeft:
            return .downRight
        case .upRight:
            return .downLeft
        case .downLeft:
            return .upRight
        case .downRight:
            return .upLeft
        default:
            return .stay
        }
    }
    
    public func printDescription() {
        print(self)
    }
    
    case up, down, left, right, upLeft, upRight, downLeft, downRight, stay
}

fileprivate let semaphore = DispatchSemaphore(value: 1)

final class MovePath: DNA & Hashable & Decodable {

    var extra: Any?
    
    private var maxNumberOfSteps: Int!
   
    private var index: Int = 0
    
    public var isCompletedTask: ((_ val: MovePath) -> (Bool))?
    
    var step: Int {
        return index
    }
    
    var start: CGPoint!
    
    private var current: CGPoint!
    
//    private var isWin = false
    
    private static let selections: [Direction] = [.up, .down, .left, .right, .upLeft, .upRight, .downLeft, .downRight]
    
    var assignCurrent: CGPoint! = .zero {
        didSet {
            DispatchQueue(label: "Current").sync(flags: .barrier) {
                current = assignCurrent
                
                _ = isCompletedTask?(self) ?? false
            }
        }
    }

//    var directions: [Direction]!
    
    var allDirections: [Direction]!
    
    private enum Key: CodingKey {
        case start, path, current, index, maxSteps, extra
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        start = try container.decode(CGPoint.self, forKey: .start)
        allDirections = try container.decode([Direction].self, forKey: .path)
        current = try container.decode(CGPoint.self, forKey: .current)
        index = try container.decode(Int.self, forKey: .index)
        maxNumberOfSteps = try container.decode(Int.self, forKey: .maxSteps)
        extra = try container.decode([CGPoint].self, forKey: .extra)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(start, forKey: .start)
        try container.encode(allDirections, forKey: .path)
        try container.encode(start, forKey: .current)
        try container.encode(0, forKey: .index)
        try container.encode(allDirections.count, forKey: .maxSteps)
        try container.encode((extra as! [CGPoint]), forKey: .extra)
    }
    
    init() {
//        directions = []
        allDirections = []
        start = .zero
        current = .zero
        maxNumberOfSteps = 0
        extra = nil
        index = 0
    }
    
    init(maxNumberOfSteps: Int) {
        self.maxNumberOfSteps = maxNumberOfSteps
        let path = MovePath.random(length: maxNumberOfSteps, extra: nil)
//        self.directions = path.directions
        self.current = path.current
        self.start = path.start
        self.allDirections = path.allDirections
        self.extra = path.extra
//        self.maxNumberOfSteps = path.allDirections.count
        self.index = 0
    }
    
    required init(copy: MovePath) {
        index = copy.index
//        directions = [Direction](copy.directions)
        current = CGPoint(x: copy.current.x, y: copy.current.y)
        start = CGPoint(x: copy.start.x, y: copy.start.y)
        allDirections = [Direction](copy.allDirections)
        extra = copy.extra
        maxNumberOfSteps = allDirections.count
    }
    
    func cleanBetweenGens() {
        index = 0
        current = start
    }
    
    func getNextStep() -> Direction {
        guard index < maxNumberOfSteps else { return .stay }
        semaphore.wait()
        let dir = allDirections[index]
        
        index += 1
        
        semaphore.signal()
        
        return dir
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }

    func length() -> Int {
        return allDirections.count
    }
    
    func calcFitness(val: MovePath?, best: CGFloat) -> (val: CGFloat, extraDimension: CGFloat) {
//        let multi: CGFloat = isWin ? 5 : 1
        let dist = distance(from: current, to: val!.current)
        return (min(1, pow(1 / (dist + 1) , 4)) * 0.84, CGFloat(index))
    }
    
    func distanceTo(target: MovePath) -> CGFloat {
        return distance(from: current, to: target.current)
    }
    
    func equalTo(byEndGoal other: MovePath) -> Bool {
        return current.equalTo(other.current)
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
        return current == target.current //&& Int(count) == maxNumberOfSteps
    }
    
    func elementsEqual(_ other: MovePath) -> Bool {
        return self == other
    }
    
    /* Function to linearly interpolate between a0 and a1
     * Weight w should be in the range [0.0, 1.0]
     */
    private static func interpolate(a0: CGFloat, a1: CGFloat, w: CGFloat) -> CGFloat {
        /* // You may want clamping by inserting:
         * if (0.0 > w) return a0;
         * if (1.0 < w) return a1;
         */
        return (a1 - a0) * w + a0;
        /* // Use this cubic interpolation [[Smoothstep]] instead, for a smooth appearance:
         * return (a1 - a0) * (3.0 - w * 2.0) * w * w + a0;
         *
         * // Use [[Smootherstep]] for an even smoother result with a second derivative equal to zero on boundaries:
         * return (a1 - a0) * ((w * (w * 6.0 - 15.0) + 10.0) * w * w * w) + a0;
         */
    }

    struct vector2 {
        let x: CGFloat!
        let y: CGFloat!
    }

    /* Create random direction vector
     */
    private static func randomGradient(ix: CGFloat, iy: CGFloat) -> vector2 {
        // Random float. No precomputed gradients mean this works for any number of grid coordinates
        
        let first: CGFloat = 2920
        
        let r1: Float = 21942
        let r2: Float = 171324
        let r3: Float = 8912
        let r4: Float = 23157
        let r5: Float = 217832
        let r6: Float = 9758
       
        let second: CGFloat = CGFloat(sin(Float(ix) * r1 + Float(iy) * r2 + r3))
        
        let third: CGFloat = CGFloat(cos(Float(ix) * r4 * Float(iy) * r5 + r6))
        
        let random: CGFloat = first * second  * third
       
        return vector2(x: cos(random), y: sin(random))
    }

    // Computes the dot product of the distance and gradient vectors.
    private static func dotGridGradient(ix: CGFloat, iy: CGFloat, x: CGFloat, y: CGFloat) -> CGFloat {
        // Get gradient from integer coordinates
        let gradient = randomGradient(ix: ix, iy: iy);

        // Compute the distance vector
        let dx = x - CGFloat(ix)
        let dy = y - CGFloat(iy)

        // Compute the dot-product
        return (dx*gradient.x + dy*gradient.y);
    }

    // Compute Perlin noise at coordinates x, y
    private static func perlin(x: CGFloat, y: CGFloat) -> CGFloat {
        // Determine grid cell coordinates
        let x0 = x
        let x1 = x0 + 1
        let y0 = y
        let y1 = y0 + 1

        // Determine interpolation weights
        // Could also use higher order polynomial/s-curve here
        let sx = x - CGFloat(x0)
        let sy = y - CGFloat(y0)

        // Interpolate between grid point gradients
        var n0: CGFloat!
        var n1: CGFloat!
        var ix0: CGFloat!
        var ix1: CGFloat!
        var value: CGFloat!

        n0 = dotGridGradient(ix: x0, iy: y0, x: x, y: y);
        n1 = dotGridGradient(ix: x1, iy: y0, x: x, y: y);
        ix0 = interpolate(a0: n0, a1: n1, w: sx);

        n0 = dotGridGradient(ix: x0, iy: y1, x: x, y: y);
        n1 = dotGridGradient(ix: x1, iy: y1, x: x, y: y);
        ix1 = interpolate(a0: n0, a1: n1, w: sx);

        value = interpolate(a0: ix0, a1: ix1, w: sy);
        return value;
    }
    
    static func random(length: Int, extra: Any? = nil) -> MovePath {
//        var directions: [Direction] = [Direction]()
//
//        let point = ((extra as? [CGPoint])?.first ?? .zero)
//        let x = point.x > 0 ? point.x : 1
//        let y = point.y > 0 ? point.y : 1
//        var current: CGPoint = CGPoint(x: x, y: y)
//
//        for _ in 0..<length {
//            let index = MovePath.perlin(x: current.x, y: current.y)
//            let dir = selections[Int(index)]
//            switch dir {
//            case .up:
//                current = CGPoint(x: current.x, y: current.y - 1)
//            case .down:
//                current = CGPoint(x: current.x, y: current.y + 1)
//            case .left:
//                current = CGPoint(x: current.x - 1, y: current.y)
//            case .right:
//                current = CGPoint(x: current.x + 1, y: current.y)
//            case .upLeft:
//                current = CGPoint(x: current.x - 1, y: current.y - 1)
//            case .upRight:
//                current = CGPoint(x: current.x - 1, y: current.y + 1)
//            case .downLeft:
//                current = CGPoint(x: current.x + 1, y: current.y - 1)
//            case .downRight:
//                current = CGPoint(x: current.x + 1, y: current.y + 1)
//            case .stay:
//                break
//            }
//            directions.append(dir)
//        }
        
        var directions: [Direction] = [Direction]()
        
        var gravity: CGFloat = 0.4

        for _ in 0..<length {
            let index = CGFloat.random(in: 0...1) < gravity ? [1, 6, 7].randomElement() : Int.random(in: 0..<selections.count)
            var dir = selections[index!]
            
            if !directions.isEmpty {
                while dir == directions[directions.count - 1].getOpposite() {
                    dir = selections[Int.random(in: 0..<selections.count)]
                }
            }
            
            directions.append(dir)
            
            gravity -= (3.2 / CGFloat(length))
        }
        
        let movePath =  MovePath()
        //        movePath.directions.append(contentsOf: directions)
        movePath.allDirections.append(contentsOf: directions)
        movePath.start = extra != nil ? (extra as! [CGPoint]).first : .zero
        movePath.current = extra != nil ? (extra as! [CGPoint]).first : .zero
        movePath.maxNumberOfSteps = length
        movePath.extra = extra
        movePath.index = 0
        
        return movePath
    }
    
    subscript(offset: Int) -> MovePath {
        get {
            guard offset < allDirections.count else { return MovePath.empty() }
            let movePath = MovePath(copy: self)
            let dir = allDirections[offset]
            movePath.allDirections = dir == .stay ? [] : [dir]
            return movePath
        }
        set(newValue) {
            guard offset < allDirections.count else { return }
            allDirections[offset] = newValue.allDirections[offset]
        }
    }
    
    static func +=(lhs: inout MovePath, rhs: MovePath) {
        lhs.current =  CGPoint(x: rhs.current.x, y: rhs.current.y)
        lhs.allDirections.append(contentsOf: rhs.allDirections)
        lhs.extra = rhs.extra
        lhs.start = CGPoint(x: rhs.start.x, y: rhs.start.y)
        lhs.index = rhs.index
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
        return lhs.current.equalTo(rhs.current) && lhs.allDirections.elementsEqual(rhs.allDirections)
    }
    
    static func != (lhs: MovePath, rhs: MovePath) -> Bool {
        return !(lhs == rhs)
    }
}
