//
//  GraphView.swift
//  Die Roller
//
//  Created by Sam Gauck on 6/30/20.
//  Copyright © 2020 Sam Gauck. All rights reserved.
//

import Foundation
import SwiftUI
@testable import DiceKit
#warning("I really shouldn't be doing a testable import, but I need to access `Chances.dict`")

struct GraphView: View {
    let dice: Dice
    let currentRoll: Roll

    var arr: [(Roll, Chance)] {
        if dice.dice.isEmpty { return [(dice.modifier, Chance.one)] } // circumvents https://github.com/Samasaur1/DiceKit/issues/75
        return dice.probabilities.dict.sorted(by: { first, second in
            first.key < second.key
        })
    }

    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            VStack {
                if self.arr.count > 1 {
                    Spacer()
                    Text("\(self.currentRoll)").font(.title)
                }
                Spacer()
                if CGFloat(self.arr.count) * 30 > geo.size.width {
                    ScrollView(.horizontal) {
                        HStack {
                            Spacer(minLength: 30)
                            self.graph(geo: geo)
                            Spacer(minLength: 30)
                        }
                    }
                } else {
                    self.graph(geo: geo)
                }
                Spacer()
            }
        }
    }

    func graph(geo: GeometryProxy) -> some View {
        let denom = self.arr[0].1.d
        let greatest = self.arr.max { $0.1.value < $1.1.value }!
        return HStack(alignment: .bottom, spacing: 0) {
            ForEach(self.arr, id: \.0) { (roll, chance) in
                VStack {
                    Text("\(chance.n * denom / chance.d)").foregroundColor(Color.secondary)
                    Rectangle().fill(roll == self.currentRoll ? Color.green : Color.red, stroke: Color.primary).frame(width: 30, height: self.height(chance: chance, geo: geo, greatest: greatest.1), alignment: .center)
                    if roll == self.currentRoll {
                        Text("\(roll)").bold()
                    } else {
                        Text("\(roll)")
                    }
                }
            }
            // For testing purposes
//            VStack {
//                Rectangle().stroke(Color.primary).frame(width: 30, height: self.height(chance: .one, geo: geo, greatest: .one), alignment: .center)
//                Text("1")
//            }
        }
    }

    func height(chance: Chance, geo: GeometryProxy, greatest: Chance) -> CGFloat {
        if greatest.n < greatest.d {
            return CGFloat(chance.value) * (geo.size.height * 3/4) * 3/4 / CGFloat(greatest.value)
        }
        return CGFloat(chance.value) * (geo.size.height * 3/4)
    }
}

extension Shape {
    /// fills and strokes a shape
    public func fill<S:ShapeStyle, S2: ShapeStyle>(_ fillContent: S, stroke: S2) -> some View {
        ZStack {
            self.fill(fillContent)
            self.stroke(stroke)
        }
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GraphView(dice: Dice(.d6, withModifier: 2), currentRoll: 5).previewLayout(.fixed(width: 568, height: 320))

            GraphView(dice: Dice(.d6, .d6, withModifier: 2), currentRoll: 5).previewLayout(.fixed(width: 568, height: 320))

            GraphView(dice: Dice(.d6, .d6, .d6, withModifier: 2), currentRoll: 5).previewLayout(.fixed(width: 568, height: 320))
        }
    }
}
