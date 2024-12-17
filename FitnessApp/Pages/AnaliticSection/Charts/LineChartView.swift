//
//  LineChartView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//


import SwiftUI
import Charts

struct LineChartView: View {
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
                    LineMark(
                        x: .value("День", index + 1),
                        y: .value("Значение", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .aligned, position: .leading)
            }
        }
    }
}
