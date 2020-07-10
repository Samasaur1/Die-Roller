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
import Combine

struct ContentView: View {
    @State var sidebar = false
    @State var dice: [Die] = []
    @State var modifiers: [Int] = []
    @State var presentingRoll = false
    @State var rollResult: Roll = 0
    @State var addingCustomDie = false
    @State var customDieSidesStr: String = ""
    var customDieSides: Int? {
        Int(customDieSidesStr)
    }
    @State var addingModifier = false
    @State var modifierStr: String = ""
    var modifier: Int? {
        Int(modifierStr)
    }
    @State var writingDieString = false
    @State var dieString = ""
    var diceObj: Dice {
        Dice(dice: self.dice, withModifier: self.modifiers.reduce(0, +))
    }
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GeometryReader { (geo: GeometryProxy) in
                    HStack(spacing: 0) {
                        if self.sidebar {
                            VStack {
                                List {
                                    ForEach([4, 6, 8, 10, 12, 20, 100], id: \.self) { sides in
                                        HStack {
                                            Text("d\(sides)")
                                            Spacer()
                                            Button(action: {
                                                self.add(sides)
                                                self.addingCustomDie = false
                                                self.addingModifier = false
                                            }) {
                                                Image(systemName: "plus")
                                            }
                                        }.gesture(self.dragDieGesture(sides: sides))
                                    }
                                    HStack {
                                        Text("Custom Die")
                                        Spacer()
                                        Button(action: {
                                            self.addingCustomDie = true
                                            self.addingModifier = false
                                        }) {
                                            Image(systemName: "plus")
                                        }
                                    }
                                    HStack {
                                        Text("Modifier")
                                        Spacer()
                                        Button(action: {
                                            self.addingModifier = true
                                            self.addingCustomDie = false
                                        }) {
                                            Image(systemName: "plus")
                                        }
                                    }
                                }
                            }.frame(width: geo.size.width / 4, height: nil, alignment: .leading).transition(.asymmetric(insertion: .slide, removal: .move(edge: .leading)))
                        }
                        Divider()
                        ZStack {
                            SceneView(scene: DieScene(), width: geo.size.width, height: geo.size.height, dice: self.$dice, modifiers: self.$modifiers, dragDiePublisher: self.dragDiePublisher)
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        self.sidebar.toggle()
                                    }
                                }) {
                                    Image(systemName: "chevron.\(self.sidebar ? "left" : "right")")
                                        .padding(.vertical, nil)
                                        .padding(.trailing, 7.5)
                                        .padding(.leading, self.sidebar ? 5 : 2)
                                        .background(Color.gray)
                                }.highPriorityGesture(self.sidebarDragGesture)
                                Spacer()
                            }
                            if self.addingCustomDie {
                                self.addingCustomDieView
                            }
                            if self.addingModifier {
                                self.addingModifierView
                            }
                        }
                    }
                }
                Divider()
                HStack {
                    Button(action: {
                        self.writingDieString = true
                        self.addingCustomDie = false
                        self.addingModifier = false
                        self.presentingRoll = false
                    }) {
                        Text(diceObj.debugDescription)
                    }.foregroundColor(.primary)
                        .popover(isPresented: $writingDieString) {
                            self.writingDieStringView
                    }
                    Spacer()
                    Button(action: {
                        self.roll()
                    }) {
                        Text("Roll!")
                    }.popover(isPresented: $presentingRoll) {
                            self.rollPresentationView
                    }
                    Button(action: {
                        self.dice = []
                        self.modifiers = []
                    }) {
                        Text("Clear").foregroundColor(.red)
                    }
                }.padding()
            }
            if drag.ing {
                GeometryReader { _ in
                    Circle().fill(Color.green).frame(width: 10, height: 10, alignment: .center).position(self.drag.location)
                }
            }
        }
    }

    @State private var drag: Drag = Drag()
    private let dragDiePublisher = PassthroughSubject<(Die, CGPoint?), Never>()

    internal struct Drag {
        internal init(ing: Bool, location: CGPoint, sides: Int) {
            self.ing = ing
            self.location = location
            self.sides = sides
        }

        var ing: Bool
        var location: CGPoint
        var sides: Int

        internal init() {
            self.ing = false
            self.location = .zero
            self.sides = 1
        }
    }

    private var diceStringError: (exists: Bool, error: String?) {
        do {
            let _ = try Dice(self.dieString)
            return (false, nil)
        } catch let e as DiceKit.Error {
            return (true, e.localizedDescription)
        } catch {
            return (true, error.localizedDescription)
        }
    }

    func dragDieGesture(sides: Int) -> some Gesture {
        return DragGesture(coordinateSpace: .global)
            .onChanged { val in
                self.drag.ing = true
                self.drag.location = val.location
                self.drag.sides = sides
            }.onEnded { val in
                self.drag.ing = false
                print("sending publisher (\(sides), \(val.location))")
                let d = try! Die(sides: sides)
                self.dice.append(d)
                self.dragDiePublisher.send((d, val.location))
            }
    }

    private var sidebarDragGesture: some Gesture {
        let minWidth: CGFloat = 75
        return DragGesture()
            .onChanged { val in
                withAnimation {
                    if val.translation.width > minWidth {
                        self.sidebar = true
                    } else if val.translation.width < -minWidth {
                        self.sidebar = false
                    }
                }
        }
    }

    private var addingCustomDieView: some View {
        ZStack {
            Color.primary.colorInvert().onTapGesture {
                UIApplication.shared.endEditing()
            }
            VStack {
                HStack {
                    Button(action: {
                        self.addingCustomDie = false
                    }) {
                        Text("Cancel").foregroundColor(.red)
                    }
                    Spacer()
                    Button(action: {
                        self.add(self.customDieSides!)
                        self.addingCustomDie = false
                        self.customDieSidesStr = ""
                    }) {
                        Text("Add!")
                    }.disabled(self.customDieSides ?? 0 <= 0)
                }.padding()
                Spacer()
                TextField("Number of Sides", text: self.$customDieSidesStr).keyboardType(.numberPad)
                    .padding()
                Stepper(onIncrement: {
                    if self.customDieSides != nil {
                        self.customDieSidesStr = "\(self.customDieSides! + 1)"
                    }
                }, onDecrement: {
                    if self.customDieSides != nil {
                        self.customDieSidesStr = "\(self.customDieSides! - 1)"
                    }
                }) {
                    Text("Stepper")
                }.padding()
                Spacer()
            }
        }
    }
    private var addingModifierView: some View {
        ZStack {
            Color.primary.colorInvert().onTapGesture {
                UIApplication.shared.endEditing()
            }
            VStack {
                HStack {
                    Button(action: {
                        self.addingModifier = false
                    }) {
                        Text("Cancel").foregroundColor(.red)
                    }
                    Spacer()
                    Button(action: {
                        self.modifiers.append(self.modifier!)
                        self.addingModifier = false
                        self.modifierStr = ""
                    }) {
                        Text("Add!")
                    }.disabled(self.modifier == nil)
                }.padding()
                Spacer()
                TextField("Modifier", text: self.$modifierStr).keyboardType(.numbersAndPunctuation)
                    .padding()
                Stepper(onIncrement: {
                    if self.modifier != nil {
                        self.modifierStr = "\(self.modifier! + 1)"
                    }
                }, onDecrement: {
                    if self.modifier != nil {
                        self.modifierStr = "\(self.modifier! - 1)"
                    }
                }) {
                    Text("Stepper")
                }.padding()
                Spacer()
            }
        }
    }
    private var rollPresentationView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    self.presentingRoll = false
                }) {
                    Text("Close").foregroundColor(.red)
                }
                Spacer()
                HStack {
                    Text("Dice Rolled: ").bold()
                    Text(diceObj.debugDescription)
                }
                Spacer()
                Button(action: {
                    self.roll()
                }) {
                    Text("Reroll!")
                }
            }.padding()
            Divider()
            TabView {
                GraphView(dice: diceObj, currentRoll: self.rollResult).tabItem {
                    Image(systemName: "chart.bar")
                    Text("Probabilities")
                }.tag(1)
//                ChancesView(dice: diceObj, currentRoll: self.rollResult).tabItem {
//                    Image(systemName: "slider.horizontal.3")
//                    Text("Chances")
//                }.tag(2)
            }
        }
    }
    private var writingDieStringView: some View {
        ZStack {
            Color.primary.colorInvert().onTapGesture {
                UIApplication.shared.endEditing()
            }
            VStack {
                HStack {
                    Button(action: {
                        self.writingDieString = false
                    }) {
                        Text("Close").foregroundColor(.red)
                    }
                    Spacer()
                    Button(action: {
                        let dice = try! Dice(self.dieString)
                        self.dice = []
                        for (die, count) in dice.dice {
                            for _ in 0..<count {
                                self.dice.append(die)
                            }
                        }
                        self.modifiers = dice.modifier == 0 ? [] : [dice.modifier]
                        self.writingDieString = false
                        self.dieString = ""
                    }) {
                        Text("Save!")
                    }.disabled((try? Dice(self.dieString)) == nil)
                }.padding()
                Spacer()
                TextField("3d8 + 5", text: self.$dieString)
                    .padding()
                if self.diceStringError.exists {
                    Text(self.diceStringError.error!).foregroundColor(.red).animation(.default)
                }
                Spacer()
                Spacer()
                Spacer()
            }
        }

    }

    func add(_ sides: Int) -> Void {
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
        self.customDieSidesStr = "1"
        self.dragDiePublisher.send((die, nil))
    }

    func roll() {
        rollResult = Dice(dice: self.dice, withModifier: self.modifiers.reduce(0, +)).roll()
        presentingRoll = true
        self.addingCustomDie = false
        self.addingModifier = false
        self.writingDieString = false
    }
}

struct SceneView: UIViewRepresentable {
    let scene: DieScene
    private let pub: AnyCancellable

    init(scene: DieScene, width: CGFloat, height: CGFloat, dice: Binding<[Die]>, modifiers: Binding<[Int]>, dragDiePublisher: PassthroughSubject<(Die, CGPoint?), Never>) {
        self.scene = scene
        scene.size = .init(width: width, height: height)
        scene.anchorPoint = .init(x: 0.5, y: 0.5)
        scene.scaleMode = .fill
        scene.dice = dice
        scene.modifiers = modifiers
        pub = dragDiePublisher.sink { (die, point) in
            print("sinking publisher")
            scene.add(die, at: point)
        }
        print("regenerating SceneView")
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
    var modifiers: Binding<[Int]>! = nil
    private var diceNodes: [(Die, SKShapeNode)] = [] {
        willSet {
            print(diceNodes)
            print(newValue)
        }
    }
    private var modifierNodes: [(Int, SKLabelNode)] = []

    private var selected: SKNode? = nil

    override func didMove(to view: SKView) {


    }

    override func update(_ currentTime: TimeInterval) {
//        if dice.wrappedValue.count > diceNodes.count {
//            add(die: dice.wrappedValue.last!)
//        } else if dice.wrappedValue.count < diceNodes.count {
//            if dice.wrappedValue.isEmpty {
//                diceNodes.forEach { (_, node) in
//                    node.removeFromParent()
//                    node.removeAllChildren()
//                }
//                diceNodes = []
//            }
//            if let idx = Array(zip(dice.wrappedValue, diceNodes)).firstIndex(where: { $0.0 != $0.1.0 }) {
//                diceNodes[idx].1.removeFromParent()
//                diceNodes[idx].1.removeAllChildren()
//                diceNodes.remove(at: idx)
//            }
//        }
//        for i in 0..<diceNodes.count {
//            if dice.wrappedValue[i] == diceNodes[i].0 { continue }
//            let pos = diceNodes[i].1.position
//            diceNodes[i].1.removeFromParent()
//            diceNodes[i].1.removeAllChildren()
//            let n = dieNode(for: dice.wrappedValue[i].sides)
//            addChild(n)
//            n.position = pos
//            diceNodes[i] = (dice.wrappedValue[i], n)
//        }
//
//        if modifiers.wrappedValue.count > modifierNodes.count {
//            add(modifier: modifiers.wrappedValue.last!)
//        } else if modifiers.wrappedValue.count < modifierNodes.count {
//            if modifiers.wrappedValue.isEmpty {
//                modifierNodes.forEach { (_, node) in
//                    node.removeFromParent()
//                    node.removeAllChildren()
//                }
//                modifierNodes = []
//            }
//            if let idx = Array(zip(modifiers.wrappedValue, modifierNodes)).firstIndex(where: { $0.0 != $0.1.0 }) {
//                modifierNodes[idx].1.removeFromParent()
//                modifierNodes[idx].1.removeAllChildren()
//                modifierNodes.remove(at: idx)
//            }
//        }
//        for i in 0..<modifierNodes.count {
//            if modifiers.wrappedValue[i] == modifierNodes[i].0 { continue }
//            let pos = modifierNodes[i].1.position
//            modifierNodes[i].1.removeFromParent()
//            modifierNodes[i].1.removeAllChildren()
//            let n = modifierNode(for: modifiers.wrappedValue[i])
//            addChild(n)
//            n.position = pos
//            modifierNodes[i] = (modifiers.wrappedValue[i], n)
//        }
//
//        for (i, (_, node)) in diceNodes.enumerated() {
//            if (-self.frame.height / 2) > (node.position.y + node.frame.height/2) {
//                if node == selected { continue }
//                node.removeFromParent()
//                dice.wrappedValue.remove(at: i)
//                diceNodes.remove(at: i)
//            }
//        }
//
//        for (i, (_, node)) in modifierNodes.enumerated() {
//            if (-self.frame.height / 2) > (node.position.y + node.frame.height/2) {
//                if node == selected { continue }
//                node.removeFromParent()
//                modifiers.wrappedValue.remove(at: i)
//                modifierNodes.remove(at: i)
//            }
//        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected = self.nodes(at: touches.first!.location(in: self)).first(where: { $0.name == "draggable" })
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected?.run(.move(to: touches.first!.location(in: self), duration: 0))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        selected = nil
    }

    private lazy var points: [Int: (points: [CGPoint], labelOffsetMultiplier: CGFloat)] = [
        4: (nGon(sides: 3, sideLength: 70), 3/2),
        6: (nGon(sides: 4, sideLength: 59.25), 1),
        8: (nGon(sides: 3, sideLength: 70), 3/2),
        10: ([
            .init(x: 0, y: -36),
            .init(x: -30, y: -36 + 15),
            .init(x: 0, y: 36),
            .init(x: 30, y: -36 + 15),
            .init(x: 0, y: -36)
        ], 3/2),
        12: (nGon(sides: 5, sideLength: 45), 6/5),
        20: (nGon(sides: 3, sideLength: 70), 3/2)
    ]

    private func dieNode(for sides: Int) -> SKShapeNode {
        let n: SKShapeNode
        if let config = points[sides] {
            var points = config.points
            n = SKShapeNode(points: &points, count: points.count)
            n.position = .zero
            n.name = "draggable"
            let label = SKLabelNode(text: "\(sides)")
            label.setScale(0.8)
            label.position = .init(x: 0, y: -label.frame.height/2 * config.labelOffsetMultiplier)
            label.fontName = "HelveticaNeue-Bold"

            n.addChild(label)
        } else {
            n = SKShapeNode(circleOfRadius: 32.5)
            n.position = .zero
            n.name = "draggable"
            let label = SKLabelNode(text: "\(sides)")
            label.setScale(0.8)
            label.position = .init(x: 0, y: -label.frame.height/2)
            label.fontName = "HelveticaNeue-Bold"

            n.addChild(label)
        }
        return n
    }

    func add(die: Die) {
        let n = dieNode(for: die.sides)
        addChild(n)
        diceNodes.append((die, n))
    }

    private func modifierNode(for modifier: Int) -> SKLabelNode {
        let n = SKLabelNode(text: "\(modifier)")
        n.position = .zero
        n.name = "draggable"
        n.fontName = "HelveticaNeue-Bold"
        n.setScale(1.2)
        return n
    }

    func add(modifier: Int) {
        let n = modifierNode(for: modifier)
        addChild(n)
        modifierNodes.append((modifier, n))
    }

    func add(_ die: Die, at point: CGPoint?) {
////        let n = dieNode(for: die.sides)
////        addChild(n)
////        n.position = point
////        diceNodes.append((die, n))
////        print("adding \(die) at \(point)")
//        dump(diceNodes)
//        diceNodes.last(where: { d, n in d == die })?.1.position = point
//        print("trying to move")
        let n = dieNode(for: die.sides)
        n.position = point ?? .zero
        addChild(n)
        diceNodes.append((die, n))
        print("adding \(die) at \(point)")
        print(dice.wrappedValue)
        print(diceNodes.map { $0.0 })
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


extension CGPoint {
    static func +(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
