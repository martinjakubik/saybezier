//
//  TouchDownGestureRecognizer.swift
//  saybezier
//
//  Created by Marcin Jakubik on 17/02/2019.
//  Copyright © 2019 martin jakubik. All rights reserved.
//

import UIKit

class TouchDownGestureRecognizer : UITapGestureRecognizer {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {

        if (self.state == .possible) {

            self.state = .recognized

        }

    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {

        self.state = .failed

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {

        self.state = .failed

    }

}
