//
//  ChancesView.swift
//  Die Roller
//
//  Created by Sam Gauck on 7/1/20.
//  Copyright © 2020 Sam Gauck. All rights reserved.
//

import Foundation
import SwiftUI
import DiceKit

struct PieChartView: View { //helpful reference: https://blog.nextzy.me/create-a-simple-pie-chart-with-swiftui-e39d75b4a740
    let dice: Dice
    let currentRoll: Roll

    var arr: [(Roll, Chance)] {
        return dice.probabilities.chances.sorted(by: { first, second in
            first.key < second.key
        })
    }

    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            ZStack {
                ForEach(self.arr, id: \.0) { (roll, chance) in
                    PieChartWedge(geo: geo, roll: roll, percent: chance.value, offset: self.dice.chance(of: self.arr[0].0..<roll).value, isHighlighted: roll == self.currentRoll)
                }
            }
        }
    }
}

struct PieChartWedge: View {
    let geo: GeometryProxy
    let roll: Roll
    let percent: Double
    let offset: Double
    let isHighlighted: Bool

    var startAngle: Angle {
        let offsetPercent = offset * 360
        return Angle(degrees: offsetPercent - 90)
    }

    var endAngle: Angle {
        let valuePercent = (percent + offset) * 360
        return Angle(degrees: valuePercent - 90)
    }

    var radius: CGFloat {
        min(geo.size.width, geo.size.height) / 2
    }

    var center: CGPoint {
        let r = radius
        return CGPoint(x: r, y: r)
    }

    var path: Path {
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        return path
    }

    var labelPosition: CGPoint {
        let angle = (startAngle + endAngle) / 2
        let distance = radius * 0.7
        return CGPoint(x: CGFloat(cos(angle.radians))*distance + radius, y: CGFloat(sin(angle.radians))*distance + radius)
    }

    var body: some View {
        ZStack {
            path.fill(isHighlighted ? Color.green : Color.red, stroke: Color.primary).opacity(isHighlighted ? 1 : offset/2 + 1/2)
            if isHighlighted {
                Text("\(roll)").bold().position(labelPosition)
            } else {
                Text("\(roll)").position(labelPosition)
            }
        }
    }
}

struct PieChartView_Previews: PreviewProvider {
    static var previews: some View {
        PieChartView(dice: Dice(dice: [.d4, .d4], withModifier: 0), currentRoll: 5)
    }
}
