//
//  ViewController.swift
//  Defence Grid Creator
//
//  Created by Interactech on 14/05/1021.
//

import UIKit
import SpriteKit
import BbhGMl

class ViewController: UIViewController {
    
    private var isSmart = false
    
    private let numberOfPlayers = 50
    
    private var numOfBlocks = 0
    
    private let minNumOfBlocks = 90
    
    private let minNumSpoonedOfBlocks = 30...70
    
    private var blocksRange = 10...70
    
    private let numOfX = 12
    
    private var yStartIndex = 3
    
    private var blocks: [CGPoint : Block?]!
    
    private var board: Board!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white.withAlphaComponent(0.8)
        
        isSmart = true
        
        let widthRemoval: CGFloat = 2
        let sizeX = (view.frame.width / CGFloat(numOfX)) - widthRemoval
        let sizeY = (view.frame.width / CGFloat(numOfX))
        
        let label = scoreLabel(size: sizeY)
        
        yStartIndex = Int((label.frame.maxY) / sizeY) + 1
        
        label.numberOfLines = 2
        
        view.addSubview(label)
        
        numOfBlocks = Int.random(in: minNumSpoonedOfBlocks)
        var leftBlocks = Int.random(in: blocksRange)
        
        let totalBlocks = numOfBlocks + leftBlocks
        
        if totalBlocks < minNumOfBlocks {
            let addNumOfBlocks = Int.random(in: 0...minNumOfBlocks - totalBlocks)
            numOfBlocks += addNumOfBlocks
            leftBlocks = minNumOfBlocks - addNumOfBlocks
        }
        
        var leftBlocksCount: Int = 0 {
            didSet {
                let total = (numOfBlocks + leftBlocks)
                let precent: CGFloat = (CGFloat(leftBlocksCount) / CGFloat(total))
                UIView.animate(withDuration: 0.2) {
                    label.backgroundColor = precent > 0.75 ? UIColor.green.withAlphaComponent(0.3) : (precent > 0.5 ? UIColor.orange.withAlphaComponent(0.3) : (precent > 0.25 ? UIColor.systemYellow.withAlphaComponent(0.3) : UIColor.red.withAlphaComponent(0.3)))
                    label.layoutIfNeeded()
                }
            }
        }
        
        leftBlocksCount = leftBlocks
        
        label.text = "\(leftBlocksCount) Out Of \(numOfBlocks + leftBlocks) Blocks Left"
        
        blocks = [CGPoint : Block]()
        
        let size2D = CGSize(width: sizeX, height: sizeY)
        let numOfY = Int((view.frame.height - 10) / CGFloat(sizeY))
        
        let point = CGPoint(x: numOfX, y: numOfY)
        let start = CGPoint(x: 0, y: yStartIndex)
        var startPoints: [CGPoint] = [start]
        
        while startPoints.count < numberOfPlayers {
            var point: CGPoint = .zero
            
            if !isSmart {
                let randX = Int.random(in: 0...numOfX / 2)
                let randY = Int.random(in: yStartIndex...numOfY / 3)
                point = CGPoint(x: randX , y: randY)
                guard !startPoints.contains(point) else { continue }
            }
            
            startPoints.append(point)
        }
        
        let winPoint = CGPoint(x: point.x - 1, y: point.y - 1)
        let padding = CGFloat(numOfX) *  widthRemoval / 2
        let squareSizeRemoval: CGFloat = 0.9
        
        let container = UIView(frame: CGRect(origin: CGPoint(x: padding + start.x * size2D.width, y: start.y * size2D.height), size: CGSize(width: size2D.width * (winPoint.x - start.x + 1), height: size2D.height * (winPoint.y - start.y + 1))))
        
        container.layer.borderWidth = squareSizeRemoval
        container.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.8).cgColor
        
        for i in 0...Int(winPoint.x) {
            for j in 0...Int(winPoint.y) {
                let origin = CGPoint(x: CGFloat(i) * size2D.width, y: CGFloat(j) * size2D.height)
                let frame = CGRect(origin: origin, size: CGSize(width: size2D.width, height: size2D.height))
                let square: UIView = UIView(frame: frame)
                square.backgroundColor = .init(hexString: "#6082B6", alpha: 0.34)
                square.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.8).cgColor
                square.layer.borderWidth = squareSizeRemoval
                
                container.addSubview(square)
                square.clipsToBounds = true
            }
            view.addSubview(container)
            container.layer.cornerRadius = 8
            container.clipsToBounds = true
        }
        
        var numOfSkips = 0
        while blocks.count < numOfBlocks {
            let randomX = Int.random(in: 0...numOfX - 1)
            let randomY = Int.random(in: yStartIndex...numOfY - 1)
            
            let key = CGPoint(x: randomX, y: randomY)
            var skip = false
            for startPoint in startPoints {
                guard !key.equalTo(startPoint), blocks[key] == nil, !key.equalTo(winPoint) else {
                    skip = true
                    break
                }
            }
            guard !skip else { continue }
            var blocksTemp = blocks
            blocksTemp![key] = Block(name: "block", state: .solid)
            let list = Board(blocks: blocksTemp!, view: view, size: point, sizeOfItem: size2D, numberOfPlayers: numberOfPlayers, gameParams: (startPoints, winPoint), padding: CGFloat(numOfX) *  widthRemoval / 2).getGraph(from: startPoints.first!)
            
            let stack = CharacterEntity(identifierNum: 0, type: .player, start: startPoints.first!, win: winPoint, padding: padding, playerSpeed: 0.38).depthFirstSearch(from: Vertex(data: startPoints.first!), to: Vertex(data: winPoint), graph: list)
            
            if stack.isEmpty() {
                numOfSkips += 1
                if numOfSkips > 80 {
                    numOfSkips = 0
                    numOfBlocks -= 1
                }
                skip = true
            }
            guard !skip else { continue }
            blocks[key] = Block(name: "block", state: .solid)
        }
        
        board = Board(smartPlay: isSmart ,blocks: blocks, view: view, size: point, sizeOfItem: size2D, numberOfPlayers: numberOfPlayers, gameParams: (startPoints, winPoint), padding: CGFloat(numOfX) *  widthRemoval / 2)
        
        board.winEffect = { [self] frame in
            let block = Block(state: .empty)
            block.frame = frame
            smokeEffect(block: block, effectType: .win)
        }
        
        board.winEffect?(CGRect(x: CGFloat(numOfX) *  widthRemoval / 2 + CGFloat(winPoint.x * CGFloat(sizeX)), y: CGFloat(winPoint.y * CGFloat(sizeY)), width: CGFloat(sizeX), height: CGFloat(sizeY)))
        
        board.start()
        
        if board.smartPlay {
            label.text = "Gen: \(0)\n\(label.text!)"
            let button = UIButton(frame: CGRect(origin: label.frame.origin, size: CGSize(width: label.frame.width / 3, height: label.frame.height / 2)))
            
            button.setTitle("Save / Load", for: .normal)
            button.backgroundColor = UIColor.cyan.withAlphaComponent(0.4)
            button.setTitleColor(.darkText, for: .normal)
            button.setTitleColor(.lightText, for: .selected)
            
            button.addTarget(self, action: #selector(showSaveLoad), for: .touchUpInside)
            
            button.layer.cornerRadius = label.layer.cornerRadius
            
            view.addSubview(button)
            
            let sw = UISwitch(frame: CGRect(origin: CGPoint(x: label.frame.origin.x + label.frame.width -  label.frame.width / 7, y: label.frame.origin.y), size: CGSize(width: label.frame.width / 7, height: label.frame.height / 2)))
           
            let l = UILabel(frame: CGRect(origin: CGPoint(x: label.frame.origin.x + label.frame.width - label.frame.width / 2.22, y: label.frame.origin.y - 5), size: CGSize(width: label.frame.width / 3, height: label.frame.height / 2)))
            l.text = "Restart Blocks"
            sw.isOn = true
            sw.addTarget(self, action: #selector(self.resetBlocks(sender:)), for: .valueChanged)
            sw.onTintColor = button.backgroundColor?.withAlphaComponent(0.34)
            view.addSubview(sw)
            view.addSubview(l)
        }
        
        var numOfWins = 0
        var NumOfLoases = 0
        
        var startOverStart = false
        board.startOver = { [unowned self] text in
            DispatchQueue.main.async {
                var win = text.lowercased().contains("win")
                
//                print("Gen: \(NumOfLoases + numOfWins)")
                
                if board.smartPlay {
                    label.text = "Gen: \(board.poll!.getGeneration())"
                    win = true
                }
                
                guard win || board.isGameOver(), !startOverStart else { return }
                board.stop()
                startOverStart = true
            
                board.numUnFinishedPlayers = numberOfPlayers
                board.container.alpha = 0.2
                
                win = board.smartPlay ? false : win
                
                guard win else {
                    NumOfLoases += 1
                    for player in board.players {
                        player.isFinish = true
                    }
                    //                    let total = NumOfLoases + numOfWins
//                    print("loase\n\("\(Int(100 * CGFloat(CGFloat(NumOfLoases) / CGFloat(total))))% loase rate")")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        board.container.alpha = 1
                        if !board.smartPlay {
                            label.text = "\(leftBlocks) Out Of \(numOfBlocks + leftBlocks) Blocks Left"
                        }
                        else {
                            label.text! += "\n\(leftBlocks) Out Of \(numOfBlocks + leftBlocks) Blocks Left"
                        }
                        leftBlocksCount = leftBlocks
                        startOverStart = false
                        board.restart()
                    }
                    return
                }
                DispatchQueue.main.async {
                    blocks = [CGPoint : Block]()
                    numOfBlocks = Int.random(in: blocksRange)
                    leftBlocks = Int.random(in: blocksRange)
                    
                    let totalBlocks = numOfBlocks + leftBlocks
                    
                    if totalBlocks < minNumOfBlocks {
                        let addNumOfBlocks = Int.random(in: 0...minNumOfBlocks - totalBlocks)
                        numOfBlocks += addNumOfBlocks
                        leftBlocks = minNumOfBlocks - addNumOfBlocks
                    }
                    leftBlocksCount = leftBlocks
                    
                    label.text = "\n\(leftBlocksCount) Out Of \(numOfBlocks + leftBlocks) Blocks Left"
                    var numOfSkips = 0
                    while blocks.count < numOfBlocks {
                        let randomX = Int.random(in: Int(widthRemoval / 2)...numOfX - Int(widthRemoval / 2) - 1)
                        let randomY = Int.random(in: yStartIndex...numOfY - 1)
                        
                        let key = CGPoint(x: randomX, y: randomY)
                        var skip = false
                        for startPoint in startPoints {
                            guard !key.equalTo(startPoint), blocks[key] == nil, !key.equalTo(CGPoint(x: point.x - 1, y: point.y - 1)) else {
                                skip = true
                                break
                            }
                        }
                        
                        guard !skip else { continue }
                        var blocksTemp = [CGPoint : Block?]()
                        blocksTemp = blocks
                        blocksTemp[key] = Block(name: "block", state: .solid)
                        let list = Board(blocks: blocksTemp, view: view, size: point, sizeOfItem: size2D, numberOfPlayers: numberOfPlayers, gameParams: (startPoints, winPoint), padding: CGFloat(numOfX) *  widthRemoval / 2).getGraph(from: startPoints.first!)
                        
                        let stack = CharacterEntity(identifierNum: 0, type: .player, start: startPoints.first!, win: winPoint, padding: padding, playerSpeed: 0.38).depthFirstSearch(from: Vertex(data: startPoints.first!), to: Vertex(data: winPoint), graph: list)
                        
                        if stack.isEmpty() {
                            numOfSkips += 1
                            if numOfSkips > 80 {
                                numOfSkips = 0
                                numOfBlocks -= 1
                            }
                            skip = true
                        }
                        guard !skip else { continue }
                        blocks[key] = Block(name: "block", state: .solid)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        numOfWins += 1
//                        let total = numOfWins + NumOfLoases
//                        print("win\n\("\(Int(100 * CGFloat(CGFloat(numOfWins) / CGFloat(total))))% win rate")")
                        board.container.alpha = 1
                        board.reset()
                        board.setBlocks(blocks: blocks)
                        startOverStart = false
                        board.start()
                    }
                }
            }
        }
        
        board.addBlock = { [self] p, players in
            guard !board.isGameOver() else { return }
            DispatchQueue.main.async {
                guard leftBlocksCount > 0 else {
                    board.cantAddEffect?(CGRect(x: CGFloat(numOfX) *  widthRemoval / 2 + CGFloat(Int(point.x / CGFloat(sizeX))) * CGFloat(sizeX), y: CGFloat(Int(point.y / CGFloat(sizeY))) * CGFloat(sizeY), width: CGFloat(sizeX), height: CGFloat(sizeY)))
                    return
                }
                
                var point = CGPoint(x: p.x, y: p.y)
                
                var x = point.x
                
                var y = point.y
                
                if point.x < 0 {
                    x = 0
                }
                else if point.x > winPoint.x * sizeX {
                    x = winPoint.x * sizeX
                }
                
                if point.y < CGFloat(yStartIndex)  * sizeY {
                    y = CGFloat(yStartIndex) * sizeY
                }
                else if point.y > winPoint.y  * sizeY {
                    y = winPoint.y * sizeY
                }
                
                point = CGPoint(x: x, y: y)
                
                let key = CGPoint(x: Int(point.x / CGFloat(sizeX)), y: Int(point.y / CGFloat(sizeY)))
                let block = board.getBlocks()[key]
                guard !key.equalTo(winPoint) && (block == nil || block??.state == .empty) else {
                    board.cantAddEffect?(CGRect(x: CGFloat(numOfX) *  widthRemoval / 2 + CGFloat(Int(point.x / CGFloat(sizeX))) * CGFloat(sizeX), y: CGFloat(Int(point.y / CGFloat(sizeY))) * CGFloat(sizeY), width: CGFloat(sizeX), height: CGFloat(sizeY)))
                    return
                }
                for player in players {
                    guard !player.location.equalTo(key) else {
                        board.cantAddEffect?(CGRect(x: CGFloat(numOfX) * widthRemoval / 2 + CGFloat(Int(point.x / CGFloat(sizeX))) * CGFloat(sizeX), y: CGFloat(Int(point.y / CGFloat(sizeY))) * CGFloat(sizeY), width: CGFloat(sizeX), height: CGFloat(sizeY)))
                        return
                    }
                }
                var blocks = board.getBlocks()
                blocks[key] = Block(name: "block", state: .solid)
                board.setBlocks(blocks: blocks)
                blocks[key]?!.frame = blocks[key]!!.image!.frame
                
                for player in players {
                    if player.isOnTheWay(point: key) {
                        player.calcGameState()
                    }
                    else if player.lose {
                        if player.think == nil {
                            player.think = UIImageView(image: UIImage(named: "bubble"))
                            let size = CGSize(width: player.image.frame.size.width - 15, height: player.image.frame.size.height - 15)
                            
                            let origin = (player.image.frame.origin.x > padding + player.image.frame.size.width * player.location.x) ? CGPoint(x: player.image.frame.origin.x + size.width * 0.85, y: player.image.frame.origin.y - size.height / 1.6) : CGPoint(x: player.image.frame.origin.x + size.width / 0.8 , y: player.image.frame.origin.y - size.height / 1.6)
                            player.think.frame = CGRect(origin: origin, size: size)
                            
                            player.image.superview?.addSubview(player.think)
                        }
                    }
                }
                board.addEffect?(blocks[key]!!)
                leftBlocksCount -= 1
                if board.smartPlay {
                    label.text = "Gen: \(board.poll!.getGeneration()) \n\(leftBlocksCount) Out Of \(numOfBlocks + leftBlocks) Blocks Left"
                }
                else {
                    label.text = "\(leftBlocksCount) Out Of \(numOfBlocks + leftBlocks) Blocks Left"
                }
            }
        }
        
        board.addEffect = { [self] block in
            smokeEffect(block: block)
        }
        
        board.cantAddEffect = { [self] frame in
            let block = Block(state: .empty)
            block.frame = frame
            smokeEffect(block: block, effectType: .cant)
        }
    }
    
    @objc private func resetBlocks(sender: UISwitch) {
        board.resetBlocks = sender.isOn
    }
    
    @objc private func showSaveLoad() {
        //1. Create the alert controller.
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Save / Load", message: "", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.placeholder = "Put Key..."
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "SAVE", style: .default, handler: { [weak alert] (_) in
                // Force unwrapping because we know it exists.
                let textField = alert!.textFields![0]
                let save = self.board.poll?.saveGeneration(key: textField.text!)
                
                print("Saved: \(save!)")
            }))
            
            alert.addAction(UIAlertAction(title: "LOAD", style: .default, handler: { [self, weak alert] (_) in
                // Force unwrapping because we know it exists.
                let textField = alert!.textFields![0]
                let load = self.board.poll?.loadGeneration(key: textField.text!)
                
                if load! {
                    board.poll?.stop()
                    board.poll?.generationChange?(true, {
                        board.poll?.cleanIfNeeded()
                        board.poll?.continue()
                    })
                }
                
                print("Loaded: \(load!)")
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    enum EffectType {
        case add, cant, win
        
        func getTextureName() -> String {
            switch self {
            case .add:
                return "block"
            case .cant:
                return "enemy@"
//            default:
//                return "block"
            case .win:
                return "goal copy"
            }
        }
        
        func getNumParticlesToEmit() -> Int {
            switch self {
            case .add:
                return 0
            case .cant:
                return 8
//            default:
//                return 0
            case .win:
                return 0
            }
        }
    }
    
    private func smokeEffect(block: Block, effectType: EffectType = .add) {
        block.image?.alpha = 0
        DispatchQueue.main.async {
            if let fireParticles = SKEmitterNode(fileNamed: "Smoke") {
                fireParticles.particleTexture = SKTexture(imageNamed: effectType.getTextureName())
                fireParticles.numParticlesToEmit = effectType.getNumParticlesToEmit()
                fireParticles.particleScale = 0.6
                fireParticles.particleScaleRange = 0.3
                fireParticles.particleScaleSpeed = -0.2
                let skView = SKView(frame: block.frame)
                skView.backgroundColor = .clear
                let scene = SKScene(size: CGSize(width: 10, height: 10))
                scene.backgroundColor = .clear
                skView.presentScene(scene)
                skView.isUserInteractionEnabled = false
                scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                scene.addChild(fireParticles)
                scene.backgroundColor = .clear
                
                self.view.addSubview(skView)
                skView.layer.cornerRadius = 10
                skView.clipsToBounds = true
                
                skView.backgroundColor = .clear
                
                
                if effectType != .win {
                    let peDelay = SKAction.wait(forDuration: Block.timeToBuild)
                    
                    let peRemove = SKAction.removeFromParent()
                    fireParticles.run(SKAction.sequence([peDelay , peRemove]))
                    fireParticles.targetNode?.removeFromParent()
                    fireParticles.targetNode = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + Block.timeToBuild) {
                        skView.removeFromSuperview()
                        block.image?.alpha = 1
                    }
                }
                else {
                    fireParticles.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.05, duration: .infinity)]))
                }
            }
        }
    }
    
    private func scoreLabel(size: CGFloat) -> UILabel {
        let spaceY = 40
        let spaceX = 30
        let height = 80
        let width = Int(CGFloat(numOfX) * size) - (spaceX * 2)
        let label = UILabel(frame: CGRect(x: spaceX, y: spaceY, width: width, height: height))
        label.textColor = .init(hexString: "#2f2f2f")
        label.textAlignment = .center
        label.layer.cornerRadius = 14
        label.numberOfLines = 1
        label.clipsToBounds = true
        label.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        
        return label
    }
}

public class Board {
    
    private var blocks: [CGPoint : Block?]!
    
    private var originalBlocks: [CGPoint : Block?]!
    
    private var winImage: UIImageView!
    
    var players: [CharacterEntity]!
    
    private var numOfPlayers: Int!
    
    private var size: CGPoint = .zero
    
    var win: CGPoint = .zero
    
    private var sizeOfItem: CGSize = .zero
    
    var startLocations: [CGPoint] = [.zero]
    
    private var padding: CGFloat = 0
    
    private var clickAllowed = true
    
    private var stuckPlayers: [CharacterEntity]!
    
    var container: UIView!
    
    var numUnFinishedPlayers: Int!
    
    var isStop = false
    
    var startOver: ((String) -> ())?
    
    var addEffect: ((Block) -> ())?
    
    var cantAddEffect: ((CGRect) -> ())?
    
    var winEffect: ((CGRect) -> ())?
    
    var addBlock: ((CGPoint, [CharacterEntity]) -> ())?
    
    var resetBlocks = true
    
    //    var blocksUpdate: (([CGPoint : Block?]) -> ())?
    
    var tap: UITapGestureRecognizer!
    var moveBlockLeft: UISwipeGestureRecognizer!
    var moveBlockRight: UISwipeGestureRecognizer!
    var moveBlockDown: UISwipeGestureRecognizer!
    var moveBlockUp: UISwipeGestureRecognizer!
    
    private var doneDrawing: (() -> ()) = {}
    
    init(smartPlay: Bool = false, blocks: [CGPoint : Block?], view: UIView?, size: CGPoint, sizeOfItem: CGSize, numberOfPlayers: Int, gameParams: (startLocations: [CGPoint], winLocation: CGPoint), padding: CGFloat) {
        self.smartPlay = smartPlay
        if smartPlay {
            let lifeSpan: CGFloat = 8
            poll = MlPoll<MovePath>(num: numberOfPlayers, mutatingRate:  0.6 / CGFloat((gameParams.winLocation.x - gameParams.startLocations.first!.x) * (gameParams.winLocation.y - gameParams.startLocations.first!.y)), lifeSpanBundle: (lifeSpan, moveSpeed: CGFloat(playerMoveTime), true))
            let movePath = MovePath()
            let endPoint = gameParams.winLocation
            movePath.assignCurrent = endPoint
            poll?.start(target: movePath, lengthLimit: Int((gameParams.winLocation.x - gameParams.startLocations.first!.x) * (gameParams.winLocation.y - gameParams.startLocations.first!.y)) , extra: gameParams.startLocations.first as Any)
        
            poll?.stopHandele = {
                self.stop()
            }
            
            poll?.decisionHandler = { index, length, fitnessVals, extraDimension in
                let vals = [fitnessVals.queryVal, fitnessVals.otherVal]
                let maxInd = vals[0] > vals[1] ? 0 : 1
                let r = CGFloat.random(in: 0...vals[maxInd] / vals[1 - maxInd])
                return r < 0.6 ? fitnessVals.queryVal > fitnessVals.otherVal : true  // index > length / 2 /// original - but keep ml decisionHandler implementation most of time
            }
        }
        players = [CharacterEntity]()
        self.blocks = blocks
        originalBlocks = blocks
        numOfPlayers = numberOfPlayers
        numUnFinishedPlayers = numberOfPlayers
        container = view
        winImage = UIImageView(image: UIImage(named: "win"))
        view?.addSubview(winImage)
        winImage.frame = CGRect(x: padding + (size.x - 1) *  sizeOfItem.width, y: (size.y - 1) *  sizeOfItem.height, width: sizeOfItem.width, height: sizeOfItem.height)
        
        self.sizeOfItem = sizeOfItem
        
        self.size = size
        
        self.padding = padding
        
        self.startLocations = gameParams.startLocations
        self.win = gameParams.winLocation
        
        if view != nil {
            for key in blocks.keys {
                guard let block = blocks[key] as? Block else { return }
                block.image?.removeFromSuperview()
                container.addSubview(block.image ?? UIImageView())
                block.image?.frame = CGRect(x: padding + sizeOfItem.width * key.x, y: sizeOfItem.height * key.y, width: sizeOfItem.width, height: sizeOfItem.height)
            }
        }
        
        poll?.generationChange = { [self] show, done in
//            poll!.stop()
            doneDrawing = done
            startOver?("")
        }
    }
    
    deinit {
        for key in blocks.keys {
            guard let block = blocks[key] as? Block else { return }
            block.image?.removeFromSuperview()
        }
        
        winImage.removeFromSuperview()
        
        if let tap = tap {
            container.removeGestureRecognizer(tap)
        }
        
        if let moveBlock = moveBlockLeft {
            container.removeGestureRecognizer(moveBlock)
        }
        
        if let moveBlock = moveBlockRight {
            container.removeGestureRecognizer(moveBlock)
        }
        
        if let moveBlock = moveBlockUp {
            container.removeGestureRecognizer(moveBlock)
        }
        
        if let moveBlock = moveBlockDown {
            container.removeGestureRecognizer(moveBlock)
        }
    }
    
    func getBlocks() ->  [CGPoint : Block?] {
        return blocks
    }
    
    func stop() {
        isStop = true
        for player in players {
            guard player.timer != nil else { continue }
            player.timer.invalidate()
            player.timer = nil
        }
    }
    
    func isGameOver() -> Bool {
        for player in players {
            if !player.isFinish && (player.playerType == .enemy || smartPlay) {
                return false
            }
        }
        
        return true
    }
    
    @objc fileprivate func addBlockTap(gestureRecognizer: UITapGestureRecognizer) {
        
        guard clickAllowed else { return }
        
        let point = gestureRecognizer.location(in: container)
        
        guard point.x <= size.x * sizeOfItem.width, point.x >= startLocations.first!.x * sizeOfItem.width, point.y <= size.y * sizeOfItem.height, point.y >= startLocations.first!.y * sizeOfItem.height else { return }
        
        clickAllowed = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Block.timeToBuild) {
            self.clickAllowed = true
        }
        
        addBlock?(point, players)
    }
    
    @objc fileprivate func moveBlockSwipe(gestureRecognizer: UISwipeGestureRecognizer) {
        guard !didWin && !isGameOver() else { return }
        var blockImage: UIImageView? = nil
        var blockValue: Block? = nil
        var blockKey: CGPoint? = nil
        
        let point = gestureRecognizer.location(in: container)
        for tuple in blocks {
            guard let block = tuple.value, let image = block.image else { continue }
            if image.frame.contains(point) {
                blockImage = image
                blockValue = tuple.value
                blockKey = tuple.key
            }
        }
        
        guard let image = blockImage, let key = blockKey, let value = blockValue else { return }
        
        let moveOnX = image.frame.size.width
        let moveOnY = image.frame.size.height
        var newKey: CGPoint = .zero
        
        var moveTo: CGPoint = .zero
        
        switch gestureRecognizer.direction {
        case .left:
            moveTo = CGPoint(x: image.frame.origin.x - moveOnX, y: image.frame.origin.y)
            newKey.x = key.x - 1
            newKey.y = key.y
        case .right:
            moveTo = CGPoint(x: image.frame.origin.x + moveOnX, y: image.frame.origin.y)
            newKey.x = key.x + 1
            newKey.y = key.y
        case .up:
            moveTo = CGPoint(x: image.frame.origin.x, y: image.frame.origin.y - moveOnY)
            newKey.x = key.x
            newKey.y = key.y - 1
        case .down:
            moveTo = CGPoint(x: image.frame.origin.x, y: image.frame.origin.y + moveOnY)
            newKey.x = key.x
            newKey.y = key.y + 1
        default:
            break
        }
        
        guard !newKey.equalTo(win) else { return }
        
        for player in players {
            guard !newKey.equalTo(player.location) else { return }
        }
        
        for (key, value) in blocks {
            guard value?.state == .solid else { continue }
            guard !newKey.equalTo(key) else { return }
        }
        
        isCalc = true
        
        UIView.animate(withDuration: 0.04) {
            image.frame.origin = moveTo
        }
        
        DispatchQueue.main.async { [self] in
            blocks[key] = nil
            blocks[newKey] = value
            
            guard !smartPlay else { return }
            for player in players {
                guard player.lose || player.isOnTheWay(point: newKey) else { continue }
                player.calcGameState()
            }
        }
    }
    
    func setBlocks(blocks: [CGPoint : Block?]) {
        for key in self.blocks.keys {
            guard let block = self.blocks[key] as? Block else { return }
            block.image?.removeFromSuperview()
        }
        self.blocks = blocks
        
        for key in blocks.keys {
            guard let block = blocks[key] as? Block else { return }
            block.image?.frame = CGRect(x: padding + sizeOfItem.width * key.x, y: sizeOfItem.height * key.y, width: sizeOfItem.width, height: sizeOfItem.height)
            
            container.addSubview(block.image ?? UIImageView())
        }
    }
    
    private var startDelay: Double = 0.01
    private var playerMoveTime: Double = 0.14
    private var enemyMoveTime: Double = 0.48
    private var playerMoveAnimationTime: Double = 0.4
    private var isCalc: Bool = false
    private var didWin: Bool = false
    
    var poll: MlPoll<MovePath>?
    
    var smartPlay = false
    
    func start() {
        stuckPlayers = nil
        tap = UITapGestureRecognizer(target: self, action: #selector(addBlockTap(gestureRecognizer:)))
        container.addGestureRecognizer(tap)
        
        moveBlockLeft = UISwipeGestureRecognizer(target: self, action: #selector(moveBlockSwipe(gestureRecognizer:)))
        moveBlockLeft.direction = .left
        moveBlockRight = UISwipeGestureRecognizer(target: self, action: #selector(moveBlockSwipe(gestureRecognizer:)))
        moveBlockRight.direction = .right
        moveBlockUp = UISwipeGestureRecognizer(target: self, action: #selector(moveBlockSwipe(gestureRecognizer:)))
        moveBlockUp.direction = .up
        moveBlockDown = UISwipeGestureRecognizer(target: self, action: #selector(moveBlockSwipe(gestureRecognizer:)))
        moveBlockDown.direction = .down
        
        container?.addGestureRecognizer(moveBlockLeft)
        container?.addGestureRecognizer(moveBlockRight)
        container?.addGestureRecognizer(moveBlockUp)
        container?.addGestureRecognizer(moveBlockDown)
        
        clickAllowed = true
        
        if smartPlay {
            for i in 0..<startLocations.count {
                startLocations[i] = startLocations.first!
            }
        }
        
        while players.count < numOfPlayers {
            var player: CharacterEntity!
            
            let id = players.count
            if smartPlay {
                player = SmartCharacterEntity(identifier: id, agentGetter: poll!.getAgentsGetters()[id], type: CharacterEntity.PlayerType(rawValue: Int.random(in: 0...3))!, start: startLocations[id], win: win, padding: padding, playerSpeed: playerMoveTime)
            }
            else {
                player = CharacterEntity(identifierNum: id, type: players.count == 0 ? .player : .enemy, start: startLocations[id], win: win, padding: padding, playerSpeed: players.count == 0 ? playerMoveTime : enemyMoveTime)
            }
            
            container.addSubview(player.image)
            player.image.frame = CGRect(x: padding + startLocations[players.count].x * sizeOfItem.width, y: startLocations[players.count].y * sizeOfItem.height , width: sizeOfItem.width, height: sizeOfItem.height)
            
            player.isMoveAllowed = { [self] location in
                guard !location.equalTo(win) else { return true }
                for character in players {
                    guard player != character else { continue }
                    guard !location.equalTo(character.location) else {
                        return false
                    }
                }
                return true
            }
            
            player.stuck = { [weak self] stuck in
                if self?.stuckPlayers == nil {
                    self?.stuckPlayers = [CharacterEntity]()
                }
                if stuck {
                    self?.stuckPlayers.append(player)
                }
                else {
                    guard let index = self?.stuckPlayers.firstIndex(where: { (char) -> Bool in
                        return char == player
                    }) else { return }
                    self?.stuckPlayers.remove(at: index)
                }
            }
            
            player.checkForStuck = { [weak self] in
                if self?.stuckPlayers == nil {
                    self?.stuckPlayers = [CharacterEntity]()
                }
                if self?.stuckPlayers.count ?? 0 >= self?.numUnFinishedPlayers ?? 0 {
                    self?.isCalc = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8 * player.playerMoveSpeed) {
                        
                        guard self?.stuckPlayers != nil, !self!.isCalc else { return }
                        if self?.stuckPlayers.count ?? 0 >= self?.numUnFinishedPlayers ?? 0 {
                            
                            for player in self!.players {
                                guard player.isStuck || player.lose || player.isFinish else {return}
                                
                            }
                            for player in self!.players {
                                player.loase()
                            }
                        }
                    }
                }
            }
            
            player.moveInformer = { [self] location, restart in
                if location.equalTo(win) {
                    clickAllowed = clickAllowed && !isGameOver()
                }
                
                guard !isStop else { return }
                
                UIView.animate(withDuration: restart ? 0 : playerMoveAnimationTime) {
                    guard !player.isFinish else { return }
                    let image = UIImage(cgImage: player.image.image!.cgImage!, scale: 1.0, orientation: player.image.frame.origin.x > padding + sizeOfItem.width * location.x ? .upMirrored : .up)
                    player.image.image = image
                    player.image.frame = CGRect(x: padding + sizeOfItem.width * location.x, y: sizeOfItem.height * location.y , width: sizeOfItem.width , height: sizeOfItem.height)
                    
                    if player.think != nil {
                        let size = CGSize(width: player.image.frame.size.width - 15, height: player.image.frame.size.height - 15)
                        let origin = (player.image.frame.origin.x > padding + player.image.frame.size.width * player.location.x) ? CGPoint(x: player.image.frame.origin.x + size.width * 0.85, y: player.image.frame.origin.y - size.height / 1.6) : CGPoint(x: player.image.frame.origin.x + size.width / 0.8 , y: player.image.frame.origin.y - size.height / 1.6)
                        player.think.frame = CGRect(origin: origin, size: size)
                    }
                }
            }
            
            player.attachBoardInformer(boardInformer: { () -> (Board?) in
                return self
            })
            
            player.startOver = { [self] text in
                player.isFinish = true
                didWin = false
                guard player.playerType == .player || self.isGameOver() else { return }
                didWin = player.playerType == .player && !player.lose
//                if didWin {
//                    let index = players.firstIndex(where: { (playerCheck) -> Bool in
//                        return player == playerCheck
//                    })
//                    poll?.getAgents()[index!].fitnessVal! *= 10
//                }
                
                for player in self.players {
                    guard player.think != nil else { continue }
                    player.think.removeFromSuperview()
                }
                self.startOver?(text)
            }
            
            players.append(player)
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                player.start()
            }
        }
    }
    
    func restart() {
        isStop = false
        numUnFinishedPlayers = numOfPlayers
        stuckPlayers = nil
        
        if resetBlocks {
            setBlocks(blocks: originalBlocks)
        }
        
        clickAllowed = true
        
        didWin = false
        
        var i = 0
        
        for player in players {
            player.reset(start: startLocations[i])
            player.image.removeFromSuperview()
            container.addSubview(player.image)
            player.image.frame = CGRect(x: padding + startLocations[i].x * sizeOfItem.width, y: startLocations[i].y * sizeOfItem.height , width: sizeOfItem.width, height: sizeOfItem.height)
            i += 1
        }
        
        print("win num: \(SmartCharacterEntity.winNum)")
        
        SmartCharacterEntity.winNum = 0
        
        doneDrawing()
        
        for player in players {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                player.start()
            }
        }
    }
    
    func reset() {
        isStop = false
        guard self.players != nil else { return }
        for i in 0..<self.players.count {
            self.players[i].image.removeFromSuperview()
        }
        for key in self.blocks.keys {
            guard let block = self.blocks[key] as? Block else { return }
            block.image?.removeFromSuperview()
        }
        self.blocks = [CGPoint : Block?]()
        self.players = [CharacterEntity]()
    }
    
    private func getSurroundingsBlocks(location: CGPoint) ->  [CGPoint : (Block?, index: Double)] {
        var blocksAround: [CGPoint : (Block?, Double)] = [CGPoint : (Block?, Double)]()
        
        for j in Int(location.y - 1)...Int(location.y + 1) {
            for i in Int(location.x - 1)...Int(location.x + 1) {
                
                guard i >= Int(startLocations.first!.x) && i < Int(size.x), j >= Int(startLocations.first!.y) && j < Int(size.y)  else { continue }
                
                let point: CGPoint = CGPoint(x: i, y: j)
                
                guard !point.equalTo(location), (blocks[point] as? Block) == nil || (blocks[point] as? Block)!.state == .empty else { continue }
                
                let score = i != Int(location.x) && j != Int(location.y) ? sqrt(2) : 1
                
                blocksAround[point] = (blocks[point] ?? Block(state: .empty), score)
            }
        }
        
        return blocksAround
    }
    
    func getSurroundingsFor(location: CGPoint) -> [CGPoint : (block: Block?, index: Double)] {
        return getSurroundingsBlocks(location: location)
    }
    
    func getGraph(from location: CGPoint) -> AdjacencyList<CGPoint> {
        let list = AdjacencyList<CGPoint>()
        var checkPoints: [CGPoint] = [location]
        var doneCheckPoints: [CGPoint] = [CGPoint]()
        while !checkPoints.isEmpty {
            let checkPoint = checkPoints.remove(at: 0)
            doneCheckPoints.append(checkPoint)
            let playSpace = getSurroundingsFor(location: checkPoint)
            
            for tuple in playSpace {
                if (tuple.value.block == nil || tuple.value.block?.state == .empty) && !checkPoints.contains(tuple.key) && !doneCheckPoints.contains(tuple.key) {
                    checkPoints.append(tuple.key)
                    list.add(.undirected, from: Vertex(data: checkPoint), to: Vertex(data: tuple.key), weight: playSpace[tuple.key]!.index)
                }
            }
        }
        
        return list
    }
    
    func getClosestToWin(player: CharacterEntity, bestMatch: @escaping (CGPoint?) -> ()) {
        DispatchQueue.main.async { [self] in
            for i in 0..<Int(size.x) {
                for j in 0..<Int(size.y) {
                    let key = CGPoint(x: i, y: j)
                    guard !key.equalTo(win) else { continue }
                    self.blocks[key] = self.blocks[key] ?? Block(state: .empty)
                }
            }
            
            var best: CGPoint? = nil
            var bestDistance: CGFloat = distance(from: player.location, to: win)
            for i in 0..<Array(blocks.keys).count {
                let key = Array(blocks.keys)[Array(blocks.keys).count - 1 - i]
                let value = (blocks[key] as? Block)
                if value == nil || value!.state == .empty {
                    let distanceCompere = distance(from: key, to: win)
                    
                    if distanceCompere < bestDistance && !player.lookForWay(location: player.location, winLocation: key).isEmpty() {
                        bestDistance = distanceCompere
                        best = key
                    }
                }
            }
            
            bestMatch(best)
        }
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }
}

class CharacterEntity: CustomStringConvertible {
    
    fileprivate let identifier: Int!
    
    var description: String {
        return "\nlocation: \(location!)\nisFinish: \(isFinish)\nlose: \(lose)\nstack: \(stack.description)\nfinish: \(isFinish)\nstuck: \(isStuck)"
    }
    
    enum Condition {
        case move, lose, win
    }
    
    enum PlayerType: Int {
        case player, enemy, other, other2
        
        func getImage() -> UIImage {
            switch self {
            case .player:
                return UIImage(named: "player")!
            case .other:
                return UIImage(named: "enemy@")!
            case .other2:
                return UIImage(named: "enemy")!
            default:
                return UIImage(named: "enemy")!
            }
        }
    }
    
    var location: CGPoint!
    var think: UIImageView!
    fileprivate var winLocation: CGPoint!
    fileprivate var boardInformer: (() -> (Board?))?
    var playerType: PlayerType = .player
    var moveInformer: ((CGPoint, Bool) -> ())?
    var isMoveAllowed: ((CGPoint) -> (Bool))?
    var stuck: ((Bool) -> ())?
    var startOver: ((String) -> ())?
    var checkForStuck: (() -> ())?
    var image: UIImageView!
    var isFinish = false
    private static var numID = 0
    private let id: String!
    
    var playerMoveSpeed: Double = 0
    
    private var stack: Stack<Vertex<CGPoint>>!
    
    var lose = false
    
    var timer: Timer!
    
    private var xPadding: CGFloat = 0
    
    init(identifierNum: Int, type: PlayerType,start: CGPoint ,win: CGPoint, padding: CGFloat, playerSpeed: Double) {
        playerType = type
        location = start
        identifier = identifierNum
        image = UIImageView(image: type.getImage())
        winLocation = win
        xPadding = padding
        playerMoveSpeed = playerSpeed
        id = "\(CharacterEntity.numID)"
        CharacterEntity.numID += 1
        
        moveInformer?(location, true)
    }
    
    func reset(start: CGPoint) {
        image.alpha = 1
        location = start
        isFinish = false
        lose = false
        isStuck = false
        //        Character.numID = 0
        moveInformer?(location, true)
    }
    
    static func == (lh: CharacterEntity, rh: CharacterEntity) -> Bool {
        return lh.id == rh.id
    }
    
    static func != (lh: CharacterEntity, rh: CharacterEntity) -> Bool {
        return !(lh == rh)
    }
    
    func start() {
        stack = Stack<Vertex<CGPoint>>()
        calcGameState(initial: true)
        timerControl(start: true, initial: true)
    }
    
    func timerControl(start: Bool, initial: Bool = false) {
        if start {
            timer = Timer(timeInterval: playerMoveSpeed, repeats: true) { (timer) in
                self.checkWhereToGo()
            }
            if initial {
                timer.fire()
            }
            if timer != nil {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
        else if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    func attachBoardInformer(boardInformer: @escaping () -> (Board?)) {
        self.boardInformer = boardInformer
    }
    
    func isOnTheWay(point: CGPoint) -> Bool {
        guard stack != nil else { return false }
        return stack.contains(item: Vertex<CGPoint>(data: point))
    }
    
    func calcGameState(initial: Bool = false) {
        if initial {
            calcState()
        }
        else {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.timerControl(start: false)
                
                strongSelf.calcState()
                
                strongSelf.timerControl(start: true)
            }
        }
    }
    
    private func calcState() {
        DispatchQueue.main.async { [self] in
            let way = lookForWay(location: location, winLocation: winLocation)
            
            lose = way.isEmpty()
            
            isFinish = false
            
            if lose {
                if think == nil {
                    think = UIImageView(image: UIImage(named: "bubble"))
                    let size = CGSize(width: image.frame.size.width - 15, height: image.frame.size.height - 15)
                    let origin = (image.frame.origin.x > xPadding + image.frame.size.width * location.x) ? CGPoint(x: image.frame.origin.x + size.width * 0.85, y: image.frame.origin.y - size.height / 1.6) : CGPoint(x: image.frame.origin.x + size.width / 0.8 , y: image.frame.origin.y - size.height / 1.6)
                    think.frame = CGRect(origin: origin, size: size)
                    
                    image.superview?.addSubview(think)
                }
                boardInformer!()!.getClosestToWin(player: self) { (best) in
                    let bestWay = lookForWay(location: location, winLocation: best ?? location)
                    stack = bestWay
                }
                return
            }
            
            stack = way
        }
    }
    
    private var delay: Double = 0.3
    private var restartDelay: Double = 0.2
    private var stuckCounter = 0
    var isStuck = false {
        didSet {
            if oldValue != isStuck {
                stuck?(isStuck)
                checkForStuck?()
            }
        }
    }
    
    fileprivate func checkWhereToGo() {
        
        var condition: Condition = stack.isEmpty() ? .lose : .move
        if !lose || condition != .lose {
            guard let point = stack.peekFirst()?.data  else {
                return
            }
            if let isMoveAllowed = isMoveAllowed {
                let allow = isMoveAllowed(point)
                isStuck = !allow
                
                stuckCounter += isStuck ? 1 : -1
                
                if stuckCounter == 80 {
                    calcGameState()
                }
                checkForStuck?()
                guard allow else { return }
            }
            let next = stack.queuePop()?.data
            location = next ?? location
            condition = location.equalTo(winLocation) ? .win : .move
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.think != nil {
                self.think.removeFromSuperview()
                self.think = nil
            }
        }
        
        switch condition {
        case .lose:
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                loase()
                stuck?(true)
            }
        case .win:
            if timer != nil {
                timer.invalidate()
            }
            timer = nil
            moveInformer?(location, false)
            isFinish = true
            switch playerType {
            case .player:
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                    image.alpha = 0.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + restartDelay) {
                        boardInformer?()?.stop()
                        startOver?("You Win")
                        stuck?(true)
                    }
                }
            case .enemy:
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                    loase()
                    stuck?(true)
                }
            default:
                break
            }
            
        default:
            moveInformer?(location, false)
        }
    }
    
    func loase() {
        isFinish = true
        if timer != nil {
            timer.invalidate()
        }
        timer = nil
        
        self.startOver?("You Lose")
    }
    
    func lookForWay(location: CGPoint, winLocation: CGPoint) ->  Stack<Vertex<CGPoint>> {
        guard let boardInformer = boardInformer, let list = boardInformer()?.getGraph(from: location) else { return Stack<Vertex<CGPoint>>() }
        
        let result = depthFirstSearch(from: Vertex(data: location), to: Vertex(data: winLocation), graph: list)
        
        let stack = result
        
        return stack
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }
    
    func depthFirstSearch(from start: Vertex<CGPoint>, to end: Vertex<CGPoint>, graph: AdjacencyList<CGPoint>) -> Stack<Vertex<CGPoint>> { // 1
        var visited = Set<Vertex<CGPoint>>() // 2
        var stack = Stack<Vertex<CGPoint>>() // 3
        var stackTrack = Stack<Vertex<CGPoint>>() // 3
        
        stack.push(start)
        visited.insert(start)
        
        outer: while let vertex = stack.peek(), vertex != end { // 1
            
            guard let neighbors = graph.edges(from: vertex), neighbors.count > 0 else { // 2
                _ = stack.pop()
                continue
            }
            
            for edge in neighbors { // 3
                if !visited.contains(edge.destination) {
                    visited.insert(edge.destination)
                    stack.push(edge.destination)
                    if stack.count() > stackTrack.count() {
                        stackTrack = stack
                    }
                    continue outer
                }
            }
            
           _ = stack.pop()
        }
        
        return stack // 4
    }
}

class SmartCharacterEntity: CharacterEntity {
//    private let agent: Agent<MovePath>!
    
    static var winNum = 0
    
    private var agentGetter: (_ index: Int) -> (Agent<MovePath>?) = { _ in
        return nil
    }
    
    init(identifier: Int, agentGetter: @escaping (_ index: Int) -> (Agent<MovePath>?), type: PlayerType, start: CGPoint ,win: CGPoint, padding: CGFloat, playerSpeed: Double) {
        self.agentGetter = agentGetter
        super.init(identifierNum: identifier, type: type, start: start, win: win, padding: padding, playerSpeed: playerSpeed)
        self.image.alpha = 0.78
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 14)))
        label.text = "\(identifier)"
        let r = Int.random(in: 0..<8)
        label.textColor = r < 1 ? .blue : (r < 2 ? .green : (r < 3 ? .systemRed : (r < 4 ? .orange : (r < 5 ? .purple : (r < 6 ? .black : r < 7 ? .yellow : .systemIndigo)))))
        self.image.addSubview(label)
    }
    override func start() {
        self.image.alpha = 0.78
        timer = Timer(timeInterval: playerMoveSpeed, repeats: true, block: { (timer) in
            self.checkWhereToGo()
        })
        
        RunLoop.current.add(timer, forMode: .common)
    }
    
    override func checkWhereToGo() {
        guard let agent: Agent<MovePath> = agentGetter(identifier), (agent.getData()?.allDirections.count ?? 0) > 0 else { return }
        
        let dir = agent.getData()?.getNextStep()
        
        var point: CGPoint!
        
        switch dir {
        case .up:
            point = CGPoint(x: location.x, y: location.y - 1)
        case .down:
            point = CGPoint(x: location.x, y: location.y + 1)
        case .left:
            point = CGPoint(x: location.x - 1, y: location.y)
        case .right:
            point = CGPoint(x: location.x + 1, y: location.y)
        case .upLeft:
            point = CGPoint(x: location.x - 1, y: location.y - 1)
        case .downLeft:
            point = CGPoint(x: location.x - 1, y: location.y + 1)
        case .upRight:
            point = CGPoint(x: location.x + 1, y: location.y - 1)
        case .downRight:
            point = CGPoint(x: location.x + 1, y: location.y + 1)
        default:
            break
        }
        
        guard point != nil, let allowedBlocks = boardInformer?()?.getSurroundingsFor(location: location) else { return }
        
        var isAllowed = false
        
        for allowedBlock in allowedBlocks {
            if point == allowedBlock.key && allowedBlock.value.block?.state == .empty {
                isAllowed = true
                break
            }
        }
        
        guard isAllowed else { return }
        location = point
        agent.getData()?.assignCurrent = location
        agent.checkIfShouldKeep()
        
        moveInformer?(location, false)
        
        if location.equalTo(winLocation) {
//            startOver?("You Win")
            SmartCharacterEntity.winNum += 1
//            print("Agent: \(agent.toString()) Win")
        }
    }
}

public enum State {
    case empty, solid
}

class Block {
    static var timeToBuild: Double = 0.4
    
    var image: UIImageView?
    var state: State = .solid
    var frame: CGRect = .zero
    
    init(name: String? = nil, state: State) {
        if name != nil {
            self.image = UIImageView(image: UIImage(named: name!))
        }
        self.state = state
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
//            scanner.currentIndex = 1
            scanner.currentIndex = scanner.string.index(after: scanner.string.startIndex)
        }
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

/// Safe Dict Update
class ReaderWriterLock {
    private let queue = DispatchQueue(label: "com.domain.app.rwLock", attributes: .concurrent)
    
    public func concurrentlyRead<T>(_ block: (() throws -> T)) rethrows -> T {
        return try queue.sync {
            try block()
        }
    }
    
    public func exclusivelyWrite(_ block: @escaping (() -> Void)) {
        queue.async(flags: .barrier) {
            block()
        }
    }
}
