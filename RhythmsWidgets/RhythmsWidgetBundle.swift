//
//  RhythmsWidgetBundle.swift
//  RhythmsWidgets
//
//  Created by Cam Frederick on 12/27/25.
//

import WidgetKit
import SwiftUI

@main
struct RhythmsWidgetBundle: WidgetBundle {
    var body: some Widget {
        RhythmsProgressWidget()
        RhythmsTodayWidget()
        RhythmsDetailWidget()
    }
}
