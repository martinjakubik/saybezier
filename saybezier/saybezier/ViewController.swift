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

    enum TapState {

        case touchUp, firstTouchDown, firstTouchUp, secondTouchDown

        func description() -> String {
            switch (self) {
            case .touchUp:
                return "touchUp"
            case .firstTouchDown:
                return "firstTouchDown"
            case .firstTouchUp:
                return "firstTouchUp"
            case .secondTouchDown:
                return "secondTouchDown"
            }
        }

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

    var paths:[BezPath] = []
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

        os_log("touches began, touch count: %d, tap state: %@", log:self.log, type:.debug, touches.count, self.tapState.description())
        
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

        os_log("touches ended, tap state: %@", log:self.log, type:.debug, self.tapState.description())

        switch self.tapState {
        case .firstTouchDown:

            self.tapState = .touchUp

            if (touches.count == 1) {

                if let touch = touches.first {

                    let locationInScene = touch.location(in: self.scene)
                    handleSingleTouchUp(locationInScene: locationInScene)

                }

            }

        case .secondTouchDown:

            self.tapState = .touchUp

        default:

            self.tapState = .touchUp

        }

    }

    func handleSingleTouchDown(locationInScene: CGPoint) {

        switch self.pathState {
        case .noPath:

            os_log("single touch down - starting path at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

            let spot = UIBezierPath(arcCenter: locationInScene, radius: spotRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
            let spotNode = makeSpotNode(spot: spot)
            self.scene.addChild(spotNode)
            self.currentSpotNode = spotNode

            break

        case .startPoint:

            break

        case .endPath:

            for path in self.paths {

                if (locationInScene.x - path.startPoint.x < spotRadius && locationInScene.y - path.startPoint.y < spotRadius) {

                    os_log("single touch down - starting anchor at x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)
                    
                    let spot:UIBezierPath = UIBezierPath(arcCenter: locationInScene, radius: spotRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
                    let spotNode = makeAnchorNode(spot: spot)

                    self.scene.addChild(spotNode)

                    break

                }

            }

            break

        }

    }

    func handleDoubleTap(locationInScene: CGPoint) {

        if self.pathState == .noPath {

            os_log("double tap - clearing scene", log:self.log, type:.debug)
            os_log("------------------------", log:self.log, type:.debug)
            self.scene.removeAllChildren()
            self.pathState = .noPath
            os_log("state: %s", log:self.log, type:.debug, self.pathState.description())

        }

    }
    
    func handleSingleTouchMoved(locationInScene: CGPoint) {

        switch self.pathState {
        case .noPath:

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

            os_log("dropping start path at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

            let path:BezPath = BezPath(startAt: locationInScene)
            self.paths.append(path)
            let pathNode = makePathNode(path: path)
            self.scene.addChild(pathNode)

            self.pathState = .startPoint
            break

        case .startPoint:

            os_log("adding point at (scene) x: %f, y: %f", log:self.log, type:.debug, locationInScene.x, locationInScene.y)

            let path = self.paths[self.paths.count - 1]
            path.addLine(to: locationInScene)
            let pathNode = makePathNode(path: path)

            let spot:UIBezierPath = UIBezierPath(arcCenter: locationInScene, radius: spotRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
            let spotNode = makeSpotNode(spot: spot)

            self.scene.addChild(spotNode)
            self.scene.addChild(pathNode)

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

        let spotNode = SKShapeNode(path: spot.cgPath)

        spotNode.strokeColor = UIColor.yellow
        spotNode.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 0.2)
        spotNode.zPosition = self.backgroundNode.zPosition + 1

        return spotNode

    }

    func makeAnchorNode (spot:UIBezierPath) -> SKShapeNode {

        os_log("making anchor at (scene) x: %f, y: %f", log:self.log, type:.debug, spot.cgPath.currentPoint.x, spot.cgPath.currentPoint.y)

        let anchorNode = SKShapeNode(path: spot.cgPath)

        anchorNode.strokeColor = UIColor.red
        anchorNode.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.2)
        anchorNode.zPosition = self.backgroundNode.zPosition + 2

        return anchorNode

    }
    
    func makePathNode (path:BezPath) -> SKShapeNode  {

        let uiBezierPath = path.uiBezierPath
        let pathNode = SKShapeNode(path: uiBezierPath.cgPath)
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

            let ratio = CGFloat(x) / CGFloat(sceneWidth)

            if (x % 50 == 0) {

                let dot = makeDotNode(at: CGPoint(x: CGFloat(x), y: margin), dotSize: .big, order: ratio)
                self.scene.addChild(dot)

            } else if (x % 10 == 0) {

                let dot = makeDotNode(at: CGPoint(x: CGFloat(x), y: margin), dotSize: .small, order: ratio)
                self.scene.addChild(dot)

            }

        }

        for y in 0 ... sceneHeight {

            let ratio = CGFloat(y) / CGFloat(sceneHeight)

            if (y % 50 == 0) {

                let dot = makeDotNode(at: CGPoint(x: margin, y: CGFloat(y)), dotSize: .big, order: ratio)
                self.scene.addChild(dot)

            } else if (y % 10 == 0) {

                let dot = makeDotNode(at: CGPoint(x: margin, y: CGFloat(y)), dotSize: .small, order: ratio)
                self.scene.addChild(dot)

            }

        }

    }

    func makeDotNode(at position:CGPoint, dotSize:DotSize, order:CGFloat) -> SKShapeNode {

        var radius = CGFloat(2)
        let intensity = CGFloat(order)
        let strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        var fillColor = UIColor(red: intensity, green: 1.0, blue: 1.0, alpha: 1.0)
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

