//
//  NumberLabel.swift
//  AlarmAwake
//
//  Created by Nichole on 4/18/18.
//  Copyright © 2018 mac. All rights reserved.
//

import Foundation
import UIKit

class NumberLabel: UILabel {
    func wrongSolution() {
        let origShadowColor = self.shadowColor
        self.textColor = UIColor(red: 0.7098, green: 0, blue: 0, alpha: 1.0)
        self.shadowColor = UIColor.black
        let shakeTime = 0.5
        self.shake(count: 7, for: shakeTime, withTranslation: 18)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2*shakeTime) {
            self.shadowColor = origShadowColor
            self.textColor = UIColor.black
        }
    }
}
