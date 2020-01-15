import UIKit

final class Filter: NSObject {

    var isEnabled: Bool = true
    var overlayImage: CIImage?
    var ciFilter: CIFilter?

    // MARK: - Init
    
    init(ciFilter: CIFilter?) {
        self.ciFilter = ciFilter

        super.init()
    }

    /// Inits an empty filter
    static func emptyFilter() -> Filter {
        return Filter(ciFilter: nil)
    }

    // MARK: - Public

    func imageByProcessingImage(_ image: CIImage, at time: CFTimeInterval) -> CIImage? {
        if !isEnabled {
            return image
        }

        var image = image

        if let overlayImage = overlayImage {
            image = overlayImage.composited(over: image)
        }

        guard let ciFilter = ciFilter else {
            return image
        }

        ciFilter.setValue(image, forKey: kCIInputImageKey)
        return ciFilter.value(forKey: kCIOutputImageKey) as? CIImage
    }
}
