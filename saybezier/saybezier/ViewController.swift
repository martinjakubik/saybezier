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

    enum TapState {

        case touchUp, firstTouchDown, firstTouchUp, secondTouchDown

    }

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

    enum DotSize {

        case small, big

    }

    var tapState:TapState = .touchUp
    var firstTouchTime:Date = Date()
    let doubleTapInterval:TimeInterval = TimeInterval(floatLiteral: 0.8)
    
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

    }

    override func viewWillAppear(_ animated: Bool) {

        os_log("view size: %f x %f", log:self.log, type:.debug, self.skView.frame.size.width, self.skView.frame.size.height)

        self.scene = SKScene(size: self.skView.frame.size)
        self.scene.scaleMode = .fill

        self.skView.showsFPS = true
        self.skView.showsNodeCount = true
        self.skView.ignoresSiblingOrder = true

        os_log("found scene with size: %f x %f at anchor point x: %f, y: %f", log:self.log, type:.debug, scene.size.width, scene.size.height, scene.anchorPoint.x, scene.anchorPoint.y)
        self.backgroundNode.size = self.scene.size
        self.backgroundNode.position = CGPoint(
            x: self.scene.size.width / 2,
            y: self.scene.size.height / 2
        )

        self.scene.addChild(backgroundNode)
        self.skView.presentScene(scene)

        makeRuler()

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if (touches.count == 1) {

            switch (self.tapState) {
            case .touchUp:

                self.tapState = .firstTouchDown
                self.firstTouchTime = Date()

                // starts timer and calls handleSingleTouchDown after double-tap timer expires
                if let touch = touches.first {

                    let locationInScene = touch.location(in: self.scene)
                    handleSingleTouchDown(locationInScene: locationInScene)

                }
                break

            case .firstTouchDown:

                // can't happen
                break

            case .firstTouchUp:

                let now = Date()
                if (now <= self.firstTouchTime + doubleTapInterval) {

                    self.tapState = .secondTouchDown

                }
                break

            case .secondTouchDown:

                // can't happen
                break

            }

        }

    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        if (touches.count == 1) {

            if let touch = touches.first {

                let locationInScene = touch.location(in: self.scene)
                handleSingleTouchMoved(locationInScene: locationInScene)

            }

        }

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        if (touches.count == 1) {

            if let touch = touches.first {

                let locationInScene = touch.location(in: self.scene)
                handleSingleTouchUp(locationInScene: locationInScene)

            }

        }

    }

    func handleSingleTouchDown(locationInScene: CGPoint) {

        switch self.pathState {
        case .noPath:

            os_log("single touch down - starting path at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

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

    func handleDoubleTap(locationInScene: CGPoint) {

        if self.pathState == .noPath {

            os_log("double tap - clearing scene", log:self.log, type:.debug)
            os_log("------------------------", log:self.log, type:.debug)
            self.backgroundNode.removeAllChildren()
            self.pathState = .noPath
            os_log("state: %s", log:self.log, type:.debug, self.pathState.description())

        }

    }
    
    func handleSingleTouchMoved(locationInScene: CGPoint) {

        switch self.pathState {
        case .noPath:

            var currentPoint = CGPoint(x: 0, y: 0)
            if let spotNode = self.currentSpotNode {

                currentPoint.x = spotNode.position.x + spotRadius
                currentPoint.y = spotNode.position.y

            }

            let spotNodePosition = CGPoint(x: locationInScene.x - spotRadius, y: locationInScene.y)

            os_log("pan changed - moving path start from (scene) x: %f, y: %f to x: %f, y: %f", log:self.log, type:.debug, currentPoint.x, currentPoint.y, spotNodePosition.x, spotNodePosition.y)

            self.currentSpotNode?.position = spotNodePosition

            break

        case .startPoint:

            break

        case .endPath:

            break

        }

    }

    func handleSingleTouchUp(locationInScene: CGPoint) {

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

    func makeRuler() {

        let sceneWidth = Int(self.scene.size.width)
        let sceneHeight = Int(self.scene.size.height)
        let margin = CGFloat(40)

        for x in 0 ... sceneWidth {

            if (x % 50 == 0) {

                let dot = makeDotNode(at: CGPoint(x: CGFloat(x), y: margin), dotSize: .big)
                self.scene.addChild(dot)

            } else if (x % 10 == 0) {

                let dot = makeDotNode(at: CGPoint(x: CGFloat(x), y: margin), dotSize: .small)
                self.scene.addChild(dot)

            }

        }

        for y in 0 ... sceneHeight {

            if (y % 50 == 0) {

                let dot = makeDotNode(at: CGPoint(x: margin, y: CGFloat(y)), dotSize: .big)
                self.scene.addChild(dot)

            } else if (y % 10 == 0) {

                let dot = makeDotNode(at: CGPoint(x: margin, y: CGFloat(y)), dotSize: .small)
                self.scene.addChild(dot)

            }

        }

    }

    func makeDotNode(at position:CGPoint, dotSize:DotSize) -> SKShapeNode {

        var radius = CGFloat(2)
        let strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        var fillColor = UIColor.white
        var zPosition = self.scene.zPosition + 2
        
        switch dotSize {
        case .small:
            break
        case .big:
            radius = 10
            fillColor = UIColor.green
            zPosition = self.scene.zPosition + 1
            break
        }
        
        let dot = SKShapeNode(circleOfRadius: radius)
        dot.position = position
        dot.strokeColor = strokeColor
        dot.fillColor = fillColor
        dot.zPosition = zPosition
        return dot

    }

}

