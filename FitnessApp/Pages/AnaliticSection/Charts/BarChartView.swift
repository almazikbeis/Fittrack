//
//  BarChartView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//


import SwiftUI
import Charts

struct BarChartView: View {
    let data: [Int]
    let color: Color
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Chart {
                ForEach(Array(data.enumerated()), id: \.0) { index, value in
                    BarMark(
                        x: .value("День", index + 1),
                        y: .value("Значение", value)
                    )
                    .foregroundStyle(color)
                }
            }
        }
    }
}
