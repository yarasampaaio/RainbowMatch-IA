import Foundation

struct Location: Hashable {
    let x: Int
    let y: Int
    
    init(_ cgPoint: CGPoint) {
        self.x = Int(cgPoint.x)
        self.y = Int(cgPoint.y)
    }
    
    func toCGPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}
