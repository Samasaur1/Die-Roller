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

struct GraphView: View {
    let dice: Dice

    var arr: [(Roll, Chance)] {
        if dice.dice.isEmpty { return [(dice.modifier, Chance.one)] } // circumvents https://github.com/Samasaur1/DiceKit/issues/75
        return dice.probabilities.dict.sorted(by: { first, second in
            first.key < second.key
        })
    }

    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            VStack {
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
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(self.arr, id: \.0) { (roll, chance) in
                VStack {
                    VStack(spacing: 0) {
                        Rectangle().stroke(Color.primary).frame(width: 30, height: CGFloat(1-chance.value) * geo.size.height * 3/4, alignment: .center)
                        Rectangle().fill(Color.red, stroke: Color.primary).frame(width: 30, height: CGFloat(chance.value) * geo.size.height * 3/4, alignment: .center)
                    }
                    Text("\(roll)")
                }
            }
        }
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
        GraphView(dice: Dice(.d6, .d6, withModifier: 2))
    }
}
