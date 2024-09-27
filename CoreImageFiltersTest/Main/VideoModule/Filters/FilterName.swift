//
//  FilterName.swift
//  FiltersTest
//
//  Created by Yuliya on 20/09/2024.
//

import UIKit

enum FilterName: String, CaseIterable {
//    case clones = "Clones"
    case vhs  = "VHS"
//    case vhs2 = "VHS-2"
//    case crt = "CRT"
//    case film = "FILM"
    
    case curve = "Curve"
    case colorMatrix = "Color matrix"
    
    case colorCorrection = "Color Correction"
}

struct CurvePoints {
    let point0: CGPoint
    let point1: CGPoint
    let point2: CGPoint
    let point3: CGPoint
    let point4: CGPoint
    
    init(photoshopPoint0: CGPoint,
         photoshopPoint1: CGPoint,
         photoshopPoint2: CGPoint,
         photoshopPoint3: CGPoint,
         photoshopPoint4: CGPoint) {
        self.point0 = CGPoint(x: photoshopPoint0.x / 255, y: photoshopPoint0.y / 255)
        self.point1 = CGPoint(x: photoshopPoint1.x / 255, y: photoshopPoint1.y / 255)
        self.point2 = CGPoint(x: photoshopPoint2.x / 255, y: photoshopPoint2.y / 255)
        self.point3 = CGPoint(x: photoshopPoint3.x / 255, y: photoshopPoint3.y / 255)
        self.point4 = CGPoint(x: photoshopPoint4.x / 255, y: photoshopPoint4.y / 255)
    }
}

struct ColorMatrixVectors {
    let rVector: CIVector
    let gVector: CIVector
    let bVector: CIVector
    let aVector: CIVector
    let biasVector: CIVector
    
    init(inputRVector: CIVector, 
         inputGVector: CIVector,
         inputBVector: CIVector,
         inputAVector: CIVector,
         inputBiasVector: CIVector) {
        self.rVector = inputRVector
        self.gVector = inputGVector
        self.bVector = inputBVector
        self.aVector = inputAVector
        self.biasVector = inputBiasVector
    }
}
