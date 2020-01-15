import UIKit

extension CGRect {

    init(rect: CGRect, contentScale: CGFloat) {
        self.init(x: rect.origin.x * contentScale,
                  y: rect.origin.y * contentScale,
                  width: rect.size.width * contentScale,
                  height: rect.size.height * contentScale)
    }

}
