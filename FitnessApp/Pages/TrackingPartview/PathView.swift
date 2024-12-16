//
//  PathView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//


import SwiftUI
import CoreLocation

struct PathView: Shape {
    var route: [CLLocationCoordinate2D]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Проверяем, есть ли маршрут
        guard !route.isEmpty else { return path }
        
        // Преобразуем координаты маршрута в точки внутри `CGRect`
        let points = route.map { coordinate -> CGPoint in
            CGPoint(x: CGFloat(coordinate.latitude), y: CGFloat(coordinate.longitude))
        }
        
        // Добавляем линии между точками
        path.addLines(points)
        return path
    }
}
