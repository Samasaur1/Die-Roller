//
//  ContentView.swift
//  Die Roller
//
//  Created by Sam Gauck on 6/29/20.
//  Copyright © 2020 Sam Gauck. All rights reserved.
//

import SwiftUI
import DiceKit
import SpriteKit

struct ContentView: View {
    @State var sidebar = false
    @State var dice: [Die] = []
    @State var presentingRoll = false
    @State var rollResult: Roll = 0
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { (geo: GeometryProxy) in
                HStack {
                    if self.sidebar {
                        VStack {
                            List {
                                ForEach([4, 6, 8, 10, 12, 20, 100], id: \.self) { sides in
                                    HStack {
                                        Text("d\(sides)")
                                        Spacer()
                                        Button(action: self.add(sides)) {
                                            Image(systemName: "plus")
                                        }
                                    }
                                }
                                HStack {
                                    Text("Custom Die")
                                }
                            }
                        }.frame(width: geo.size.width / 4, height: nil, alignment: .leading).transition(.asymmetric(insertion: .slide, removal: .move(edge: .leading)))
                    }
                    ZStack {
                        SceneView(scene: DieScene(), width: geo.size.width, height: geo.size.height, dice: self.$dice)
                        //                        Spacer()
                        HStack {
                            Button(action: {
                                withAnimation {
                                    self.sidebar.toggle()
                                }
                            }) {
                                self.sidebar ? Image(systemName: "chevron.left") : Image(systemName: "chevron.right")
                            }.padding(.vertical, nil)
                                .padding(.trailing, 7.5)
                                .padding(.leading, self.sidebar ? 5 : 2)
                                .background(Color.gray)
                            Spacer()
                        }
                    }
                }
            }
            Divider()
            HStack {
                Text(Dice(dice: dice).debugDescription)
                Spacer()
                Button(action: {
                    self.roll()
                }) {
                    Text("Roll!")
                }
                Button(action: {
                    self.dice = []
                }) {
                    Text("Clear").foregroundColor(.red)
                }
            }.padding()
                .popover(isPresented: $presentingRoll) {
                    VStack {
                        HStack {
                            Button(action: {
                                self.presentingRoll = false
                            }) {
                                Text("Close").foregroundColor(.red)
                            }
                            Spacer()
                            Button(action: {
                                self.roll()
                            }) {
                                Text("Reroll!")
                            }
                        }.padding()
                        Spacer()
                        Text("Roll result was \(self.rollResult)")
                        Spacer()
                    }
                }
        }
    }

    func add(_ sides: Int) -> () -> Void {
        return {
            let die: Die
            switch sides {
            case 4: die = .d4
            case 6: die = .d6
            case 8: die = .d8
            case 10: die = .d10
            case 12: die = .d12
            case 20: die = .d20
            case 100: die = .d100
            default:
                die = try! Die(sides: sides)
            }

            self.dice.append(die)
        }
    }

    func roll() {
        rollResult = Dice(dice: self.dice).roll()
        presentingRoll = true
    }
}

struct SceneView: UIViewRepresentable {
    let scene: DieScene

    init(scene: DieScene, width: CGFloat, height: CGFloat, dice: Binding<[Die]>) {
        self.scene = scene
        scene.size = .init(width: width, height: height)
        scene.anchorPoint = .init(x: 0.5, y: 0.5)
        scene.scaleMode = .fill
        scene.dice = dice
    }

    func makeUIView(context: Context) -> SKView {
        // Let SwiftUI handle the sizing
        let view = SKView(frame: .zero)
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        //        uiView.presentScene(scene)
    }
}

class DieScene: SKScene {
    var dice: Binding<[Die]>! = nil
    private var diceNodes: [(Die, SKShapeNode)] = []

    private var selected: SKNode? = nil

    override func didMove(to view: SKView) {


    }

    override func update(_ currentTime: TimeInterval) {
        if dice.wrappedValue.count > diceNodes.count {
            add(die: dice.wrappedValue.last!)
        } else if dice.wrappedValue.count < diceNodes.count {
            if dice.wrappedValue.isEmpty {
                diceNodes.forEach { (die, node) in
                    node.removeFromParent()
                    node.removeAllChildren()
                }
                diceNodes = []
            }
            if let idx = Array(zip(dice.wrappedValue, diceNodes)).firstIndex(where: { $0.0 != $0.1.0 }) {
                diceNodes[idx].1.removeFromParent()
                diceNodes[idx].1.removeAllChildren()
                diceNodes.remove(at: idx)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected = self.nodes(at: touches.first!.location(in: self)).first(where: { $0.name?.starts(with: "d") ?? false })
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected?.run(.move(to: touches.first!.location(in: self), duration: 0))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected = nil
    }

    private lazy var points: [Int: [CGPoint]] = [
        4: nGon(sides: 3, sideLength: 79.45),
        6: nGon(sides: 4, sideLength: 59.25),
        8: nGon(sides: 3, sideLength: 69.45),
        10: [
            .init(x: 0, y: -67.25/2),
            .init(x: -51.00/2, y: -67.25/2 + 9.05),
            .init(x: 0, y: 67.25/2),
            .init(x: 51.00/2, y: -67.25/2 + 9.05),
            .init(x: 0, y: -67.25/2)
        ],
        12: nGon(sides: 5, sideLength: 31.70),
        20: nGon(sides: 3, sideLength: 44.65)
    ]

    func add(die: Die) {
        let n: SKShapeNode
        if var points = points[die.sides] {
            n = SKShapeNode(points: &points, count: points.count)
        } else {
            n = SKShapeNode(circleOfRadius: 30)
        }
        n.position = .zero
        n.name = die.debugDescription
        let label = SKLabelNode(text: "\(die.sides)")
        label.position = .init(x: 0, y: -label.frame.height/2)
        label.setScale(n.frame.width/88)
        label.fontName = "HelveticaNeue-Bold"

        n.addChild(label)
        addChild(n)
        diceNodes.append((die, n))
    }
}

func nGon(sides n: Int, sideLength l: Double) -> [CGPoint] {
    let alpha = Double.pi * 2 / Double(n)

    var points: [CGPoint] = [CGPoint.zero]
    for i in 1..<n {
        let x = points[i-1].x + CGFloat(l * cos(Double(i - 1) * alpha))
        let y = points[i-1].y + CGFloat(l * sin(Double(i - 1) * alpha))
        points.append(CGPoint(x: x, y: y))
    }
    points.append(CGPoint.zero)

    //    return SKShapeNode(points: &points, count: points.count) //-> (0, 0) is the first vertex
    let hShift: CGFloat = -CGFloat(l/2)
    let vShift: CGFloat = -points[Int(ceil(Double(n)/2))].y / 2
    for i in 0..<points.count {
        points[i].x += hShift
        points[i].y += vShift
    }

    return points
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().previewLayout(.fixed(width: 568, height: 320))
    }
}
