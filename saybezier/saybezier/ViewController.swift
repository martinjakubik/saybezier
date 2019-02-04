//
//  ViewController.swift
//  saybezier
//
//  Created by Marcin Jakubik on 30/01/2019.
//  Copyright © 2019 martin jakubik. All rights reserved.
//

import UIKit
import SpriteKit

import os.log

class ViewController: UIViewController {

    enum PathState {
        case noPath
        case startPoint
        case endPath
    }
    
    var paths:[UIBezierPath] = []
    var pathState:PathState = .noPath

    var scene:SKScene
    var skView:SKView {

        return self.view as! SKView

    }

    let log:OSLog

    required init?(coder aDecoder: NSCoder) {

        self.scene = SKScene()
        self.log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "game")
        super.init(coder: aDecoder)

    }

    override func viewDidLoad() {

        super.viewDidLoad()
        self.view = SKView()

    }

    override func viewWillAppear(_ animated: Bool) {

        os_log("view size: %f x %f", log:self.log, type:.debug, self.skView.frame.size.width, self.skView.frame.size.height)

        self.scene = SKScene(size: self.skView.frame.size)

        self.skView.showsFPS = true
        self.skView.showsNodeCount = true
        self.skView.ignoresSiblingOrder = true

        self.go()

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "game")
        super.touchesEnded(touches, with: event)
        
        for touch in touches {

            let location = touch.location(in: self.scene)

            switch self.pathState {
            case .noPath:

                os_log("starting path at x: %f, y: %f", log:log, type:.debug, location.x, location.y)

                let path:UIBezierPath = UIBezierPath()
                path.move(to: location)
                self.paths.append(path)
                let pathNode = makePathNode(path: path)

                let spot:UIBezierPath = UIBezierPath(arcCenter: location, radius: 25, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
                let shapeNode = makeSpotNode(spot: spot)

                self.scene.addChild(shapeNode)
                self.scene.addChild(pathNode)

                self.pathState = .startPoint
                break

            case .startPoint:

                os_log("adding point at x: %f, y: %f", log:log, type:.debug, location.x, location.y)

                let path = self.paths[self.paths.count - 1]
                path.addLine(to: location)
                let pathNode = makePathNode(path: path)

                let spot:UIBezierPath = UIBezierPath(arcCenter: location, radius: 25, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
                let shapeNode = makeSpotNode(spot: spot)

                self.scene.addChild(shapeNode)
                self.scene.addChild(pathNode)

                self.pathState = .endPath
                break

            case .endPath:

                let path = self.paths[self.paths.count - 1]
                path.close()
                path.stroke()

                self.pathState = .noPath
                break

            }

        }

    }

    func makePathNode (path:UIBezierPath) -> SKShapeNode  {

        let pathNode = SKShapeNode(path: path.cgPath)
        pathNode.strokeColor = UIColor.yellow
        pathNode.zPosition = self.scene.zPosition + 1

        return pathNode

    }

    func makeSpotNode (spot:UIBezierPath) -> SKShapeNode {

        let shapeNode = SKShapeNode(path: spot.cgPath)
        shapeNode.strokeColor = UIColor.yellow
        shapeNode.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 0.2)
        shapeNode.zPosition = self.scene.zPosition + 1

        return shapeNode

    }

    func go () {
        
        let backgroundFileName = "background.png"
        let backgroundTexture = SKTexture(imageNamed: backgroundFileName)

        os_log("found scene with size: %f x %f", log:self.log, type:.debug, scene.size.width, scene.size.height)
        let backgroundNode = SKSpriteNode(
            texture: backgroundTexture,
            size: self.scene.size
        )
        backgroundNode.position = CGPoint(
            x: self.scene.size.width / 2,
            y: self.scene.size.height / 2
        )
        self.scene.addChild(backgroundNode)
        self.skView.presentScene(scene)
        

    }

}

