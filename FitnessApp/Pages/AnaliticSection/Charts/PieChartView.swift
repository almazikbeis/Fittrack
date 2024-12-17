//
//  PieChartView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//


import SwiftUI
import Charts

struct PieChartView: View {
    let data: [Double]
    let colors: [Color]
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Chart {
                ForEach(Array(data.enumerated()), id: \.0) { index, value in
                    SectorMark(
                        angle: .value("Доля", value),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(colors[index % colors.count])
                }
            }
            .chartLegend(position: .bottom)
        }
    }
}
