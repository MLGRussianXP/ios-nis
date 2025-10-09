//
//  ContentView.swift
//  MathGame
//  Created by brfsu on 21.02.2022.
//
import SwiftUI

private func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T { min(max(value, lower), upper) }

struct ContentView: View {
    @State private var correctAnswer = 0
    @State private var choiceArray: [Int] = []
    @State private var firstNumber = 0
    @State private var secondNumber = 0
    @State private var difficulty = 100
    @State private var score = 0
    @State private var isPlaying = false
    @State private var answersCount = 4
    @State private var currentOperator: MathOperator = .add

    var body: some View {
        Group {
            if isPlaying {
                gameView
            } else {
                setupView
            }
        }
        .animation(.default, value: isPlaying)
        .onAppear {
            if choiceArray.isEmpty { generateQuestionAndAnswers() }
        }
    }

    private var setupView: some View {
        VStack(spacing: 24) {
            Text("math game")
                .font(.largeTitle).bold()

            VStack(alignment: .leading, spacing: 12) {
                Text("answers count: \(answersCount)")
                    .font(.headline)
                Slider(value: Binding(
                    get: { Double(answersCount) },
                    set: { answersCount = Int(clamp($0, 2, 9)) }
                ), in: 2...9, step: 1)

                Text("difficulty: \(difficulty)")
                    .font(.headline)
                Slider(value: Binding(
                    get: { Double(difficulty) },
                    set: { difficulty = Int(clamp($0, 10, 1000)) }
                ), in: 10...1000, step: 10)
            }
            .padding(.horizontal)

            Button {
                score = 0
                isPlaying = true
                generateQuestionAndAnswers()
            } label: {
                Text("start")
                    .font(.title2).bold()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    private var gameView: some View {
        VStack(spacing: 24) {
            Text(questionText())
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(2)

            answersGrid

            Text("score: \(score)")
                .font(.headline)
                .bold()

            Button("end game") {
                isPlaying = false
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private var answersGrid: some View {
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 12), count: gridColumnCount(for: answersCount))
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(choiceArray.indices, id: \.self) { index in
                Button {
                    answerIsCorrect(answer: choiceArray[index])
                    generateQuestionAndAnswers()
                } label: {
                    GameAnswerButton(number: choiceArray[index])
                }
            }
        }
    }

    private func gridColumnCount(for count: Int) -> Int {
        if count <= 3 { return count }
        if count <= 6 { return 3 }
        if count <= 8 { return 4 }
        return 3
    }

    private func questionText() -> String {
        switch currentOperator {
        case .add: return "\(firstNumber) + \(secondNumber)"
        case .subtract: return "\(firstNumber) - \(secondNumber)"
        case .multiply: return "\(firstNumber) × \(secondNumber)"
        case .divide: return "\(firstNumber) ÷ \(secondNumber)"
        case .sqrt: return "√\(firstNumber)"
        }
    }

    private func answerIsCorrect(answer: Int) {
        let isCorrect = answer == correctAnswer
        if isCorrect { score += 1 } else { score -= 1 }
    }

    private func generateQuestionAndAnswers() {
        currentOperator = MathOperator.allCases.randomElement()!
        let operands = generateOperands(for: currentOperator, difficulty: difficulty)
        firstNumber = operands.0
        secondNumber = operands.1
        correctAnswer = currentOperator.evaluate(firstNumber, secondNumber)

        var answers: Set<Int> = [correctAnswer]
        while answers.count < max(2, min(answersCount, 9)) {
            let noise = Int.random(in: -difficulty...difficulty)
            let candidate = correctAnswer + noise
            if candidate >= -difficulty && candidate <= difficulty * 2 && candidate != correctAnswer {
                answers.insert(candidate)
            }
        }
        choiceArray = Array(answers).shuffled()
    }
}

private enum MathOperator: CaseIterable {
    case add
    case subtract
    case multiply
    case divide
    case sqrt

    func evaluate(_ a: Int, _ b: Int) -> Int {
        switch self {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        case .divide: return a / max(b, 1)
        case .sqrt: return Int(Double(a).squareRoot())
        }
    }
}

private func generateOperands(for op: MathOperator, difficulty: Int) -> (Int, Int) {
    switch op {
    case .add:
        let a = Int.random(in: 0...(difficulty/2))
        let b = Int.random(in: 0...(difficulty/2))
        return (a, b)
    case .subtract:
        let a = Int.random(in: 0...difficulty)
        let b = Int.random(in: 0...a)
        return (a, b)
    case .multiply:
        let maxFactor = max(2, Int(Double(difficulty).squareRoot()))
        let a = Int.random(in: 0...maxFactor)
        let b = Int.random(in: 0...maxFactor)
        return (a, b)
    case .divide:
        let maxQ = max(1, difficulty/3)
        let q = Int.random(in: 1...max(1, maxQ))
        let b = Int.random(in: 1...max(1, difficulty/5))
        let a = q * b
        return (a, b)
    case .sqrt:
        let r = Int.random(in: 0...max(1, Int(Double(difficulty).squareRoot())))
        let a = r * r
        return (a, 0)
    }
}

struct GameAnswerButton: View {
    let number: Int
    var body: some View {
        Text("\(number)")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
