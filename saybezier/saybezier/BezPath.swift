//
//  BezPath.swift
//  
//
//  Created by Marcin Jakubik on 27/02/2019.
//

import UIKit

class BezPath {

    let uiBezierPath:UIBezierPath
    var startPoint:CGPoint
    var endPoint:CGPoint

    init(startAt point:CGPoint) {

        self.uiBezierPath = UIBezierPath()
        self.startPoint = point
        self.endPoint = point

        self.uiBezierPath.move(to: point)

    }

    func addLine(to point:CGPoint) {

        self.uiBezierPath.addLine(to: point)

    }

    func close() {

        self.uiBezierPath.close()

    }

}
