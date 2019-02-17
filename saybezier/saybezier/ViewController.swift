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

    var gestureRecognizers:[UIGestureRecognizer] = []

    enum PathState {

        case noPath, startPoint, endPath

        func description () -> String {
            switch self {
            case .noPath:
                return "no path"
            case .startPoint:
                return "start point"
            case .endPath:
                return "end path"
            }
        }
    }

    let spotRadius:CGFloat = 25.0

    var paths:[UIBezierPath] = []
    var pathState:PathState = .noPath

    let backgroundNode:SKSpriteNode
    var currentSpotNode:SKShapeNode?

    var scene:SKScene
    var skView:SKView {

        return self.view as! SKView

    }

    let log:OSLog

    required init?(coder aDecoder: NSCoder) {

        self.scene = SKScene()
        self.log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "game")

        let backgroundFileName = "background.png"
        let backgroundTexture = SKTexture(imageNamed: backgroundFileName)
        
        self.backgroundNode = SKSpriteNode(
            texture: backgroundTexture
        )

        super.init(coder: aDecoder)

    }

    override func viewDidLoad() {

        super.viewDidLoad()
        self.view = SKView()

        let singlePressRecognizer = TouchDownGestureRecognizer(target: self, action: #selector(self.handleSinglePress(_:)))
        singlePressRecognizer.numberOfTapsRequired = 1
        self.gestureRecognizers.append(singlePressRecognizer)
        self.view.addGestureRecognizer(singlePressRecognizer)

        let singlePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.gestureRecognizers.append(singlePanRecognizer)
        self.view.addGestureRecognizer(singlePanRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.gestureRecognizers.append(doubleTapRecognizer)
        self.view.addGestureRecognizer(doubleTapRecognizer)

    }

    override func viewWillAppear(_ animated: Bool) {

        os_log("view size: %f x %f", log:self.log, type:.debug, self.skView.frame.size.width, self.skView.frame.size.height)

        self.scene = SKScene(size: self.skView.frame.size)
        self.scene.scaleMode = .fill

        self.skView.showsFPS = true
        self.skView.showsNodeCount = true
        self.skView.ignoresSiblingOrder = true

        os_log("found scene with size: %f x %f", log:self.log, type:.debug, scene.size.width, scene.size.height)
        self.backgroundNode.size = self.scene.size
        self.backgroundNode.position = CGPoint(
            x: self.scene.size.width / 2,
            y: self.scene.size.height / 2
        )

        self.scene.addChild(backgroundNode)
        self.skView.presentScene(scene)

    }

    @objc func handleSinglePress(_ sender: UIGestureRecognizer) {

        let locationInView = sender.location(in: self.view)
        let locationInScene = convertToPointInScene(from: locationInView)

        switch self.pathState {
        case .noPath:

            os_log("starting path at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

            let spot = UIBezierPath(arcCenter: locationInScene, radius: spotRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
            self.currentSpotNode = makeSpotNode(spot: spot)

            if let spotNode = self.currentSpotNode {

                self.backgroundNode.addChild(spotNode)

            }

            break

        case .startPoint:

            break

        case .endPath:

            break

        }

    }

    @objc func handleDoubleTap(_ sender: UIGestureRecognizer) {

        if self.pathState == .noPath {

            os_log("clearing scene", log:self.log, type:.debug)
            os_log("------------------------", log:self.log, type:.debug)
            self.backgroundNode.removeAllChildren()
            self.pathState = .noPath
            os_log("state: %s", log:self.log, type:.debug, self.pathState.description())

        }

    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {

        let state = sender.state
        
        switch state {
        case .began:
            self.handlePanBegan(sender: sender)
        case .changed:
            self.handlePanChanged(sender: sender)
        default:
            os_log("doing nothing", log:self.log, type:.debug)
        }

    }

    func handlePanBegan(sender: UIGestureRecognizer) {

        let locationInView = sender.location(in: self.view)
        let locationInScene = convertToPointInScene(from: locationInView)

        switch self.pathState {
        case .noPath:

            os_log("starting path at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

            let spot = UIBezierPath(arcCenter: locationInScene, radius: spotRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
            self.currentSpotNode = makeSpotNode(spot: spot)

            if let spotNode = self.currentSpotNode {

                self.backgroundNode.addChild(spotNode)

            }

            break

        case .startPoint:

            break

        case .endPath:

            break

        }

    }

    func handlePanChanged(sender: UIGestureRecognizer) {

        let locationInView = sender.location(in: self.view)
        let locationInScene = convertToPointInScene(from: locationInView)

        switch self.pathState {
        case .noPath:

            var currentPoint = CGPoint(x: 0, y: 0)
            if let spotNode = self.currentSpotNode {

                currentPoint.x = spotNode.position.x + spotRadius
                currentPoint.y = spotNode.position.y

            }

            let spotNodePosition = CGPoint(x: locationInScene.x - spotRadius, y: locationInScene.y)

            os_log("moving path start from (scene) x: %f, y: %f to x: %f, y: %f", log:self.log, type:.debug, currentPoint.x, currentPoint.y, spotNodePosition.x, spotNodePosition.y)

            self.currentSpotNode?.position = spotNodePosition

            break

        case .startPoint:

            break

        case .endPath:

            break

        }

    }

    func handleTouchesEnded(_ touches: Set<UITouch>) {

        for touch in touches {

            let locationInScene = touch.location(in: self.scene)

            switch self.pathState {
            case .noPath:

                os_log("dropping start path at (scene) x: %f, y: %f (view) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

                let path:UIBezierPath = UIBezierPath()
                path.move(to: locationInScene)
                self.paths.append(path)
                let pathNode = makePathNode(path: path)
                self.backgroundNode.addChild(pathNode)

                self.pathState = .startPoint
                break

            case .startPoint:

                os_log("adding point at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

                let path = self.paths[self.paths.count - 1]
                path.addLine(to: locationInScene)
                let pathNode = makePathNode(path: path)

                let spot:UIBezierPath = UIBezierPath(arcCenter: locationInScene, radius: 25, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
                let shapeNode = makeSpotNode(spot: spot)

                self.backgroundNode.addChild(shapeNode)
                self.backgroundNode.addChild(pathNode)

                self.pathState = .endPath
                break

            case .endPath:

                let path = self.paths[self.paths.count - 1]
                path.close()

                self.pathState = .noPath
                break

            }

            os_log("state: %s", log:self.log, type:.debug, self.pathState.description())

        }

    }

    func makeSpotNode (spot:UIBezierPath) -> SKShapeNode {

        os_log("making spot at (scene) x: %f, y: %f", log:self.log, type:.debug, spot.cgPath.currentPoint.x, spot.cgPath.currentPoint.y)

        let shapeNode = SKShapeNode(path: spot.cgPath)

        shapeNode.strokeColor = UIColor.yellow
        shapeNode.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 0.2)
        shapeNode.zPosition = self.backgroundNode.zPosition + 1

        return shapeNode

    }

    func makePathNode (path:UIBezierPath) -> SKShapeNode  {

        let pathNode = SKShapeNode(path: path.cgPath)
        pathNode.strokeColor = UIColor.yellow
        pathNode.zPosition = self.backgroundNode.zPosition + 1

        return pathNode

    }

    func convertToPointInScene(from pointInView:CGPoint) -> CGPoint {

        let height = self.view.frame.height
        let pointInScene = CGPoint(
            x: pointInView.x,
            y: height - pointInView.y
        )
        os_log("converting from point in view x: %f, y: %f to point in scene x: %f, y: %f", log:self.log, type:.debug, pointInView.x, pointInView.y, pointInScene.x, pointInScene.y)

        return pointInScene
    }
}

