import UIKit
import MetalKit

class StoriesImageView: UIView {

    private var metalView: MTKView?

    private var ciImage: CIImage?
    private var preferredCIImageTransform: CGAffineTransform?

    private let device = MTLCreateSystemDefaultDevice()
    private var commandQueue: MTLCommandQueue?
    private var context: CIContext?

    override func layoutSubviews() {
        super.layoutSubviews()

        metalView?.frame = bounds
    }

    override func setNeedsDisplay() {
        super.setNeedsDisplay()

        metalView?.setNeedsDisplay()
    }

    // MARK: - Public Setter

    public func setImage(with image: UIImage) {
        preferredCIImageTransform = preferredCIImageTransform(from: image)

        if let cgImage = image.cgImage {
            ciImage = CIImage(cgImage: cgImage)
            loadContextIfNeeded()
        }

        setNeedsDisplay()
    }

    // MARK: - Export Image

    /// Return the image fitted to 1080x1920.
    func renderedUIImage() -> UIImage? {
        return renderedUIImage(in: CGRect(origin: .zero, size: CGSize(width: 1080, height: 1920)))
    }

    /// Returns CIImage in fitted to main screen bounds.
    func renderedCIIImage() -> CIImage? {
        return renderedCIImage(in: CGRect(rect: bounds, contentScale: UIScreen.main.scale))
    }

    func renderedUIImage(in rect: CGRect) -> UIImage? {
        if let image = renderedCIImage(in: rect), let context = context {
            if let imageRef = context.createCGImage(image, from: image.extent) {
                return UIImage(cgImage: imageRef)
            }
        }

        return nil
    }

    func renderedCIImage(in rect: CGRect) -> CIImage? {
        if var image = ciImage, let transform = preferredCIImageTransform {
            image = image.transformed(by: transform)

            return scaleAndResize(image, for: rect)
        }

        return nil
    }

    // MARK: - Private

    private func cleanupContext() {
        metalView?.removeFromSuperview()
        metalView?.releaseDrawables()
        metalView = nil
    }

    private func loadContextIfNeeded() {
        setContext()
    }

    private func setContext() {
        let mView = MTKView(frame: bounds, device: device)
        mView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mView.framebufferOnly = false
        mView.enableSetNeedsDisplay = true
        mView.contentScaleFactor = contentScaleFactor
        mView.delegate = self

        metalView = mView
        commandQueue = device?.makeCommandQueue()
        context = CIContext(mtlDevice: device!)

        insertSubview(metalView!, at: 0)
    }

    private func scaleAndResize(_ image: CIImage, for rect: CGRect) -> CIImage {
        let imageSize = image.extent.size

        let horizontalScale = rect.size.width / imageSize.width
        let verticalScale = rect.size.height / imageSize.height

        let scale = min(horizontalScale, verticalScale)
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    private func preferredCIImageTransform(from image: UIImage) -> CGAffineTransform {
        if image.imageOrientation == .up {
            return .identity
        }

        var transform: CGAffineTransform = .identity

        switch image.imageOrientation {
        case .down,
             .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)

        case .left,
             .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)

        case .right,
             .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: .pi / -2)
        case .up,
             .upMirrored:
            break
        @unknown default:
            fatalError("Unknown image orientation")
        }

        switch image.imageOrientation {
        case .upMirrored,
             .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored,
             .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up,
             .down,
             .left,
             .right:
            break
        @unknown default:
            fatalError("Unknown image orientation")
        }

        return transform
    }
}

// MARK: - MTKViewDelegate

extension StoriesImageView: MTKViewDelegate {

    func draw(in view: MTKView) {
        autoreleasepool {
            let rect = CGRect(rect: view.bounds, contentScale: UIScreen.main.scale)

            if let image = renderedCIImage(in: rect) {

                let commandBuffer = commandQueue?.makeCommandBuffer()
                guard let drawable = view.currentDrawable else {
                    return
                }

                // Used to vertically align image
                let heightDifference = (view.drawableSize.height - image.extent.size.height) / 2
                let destination = CIRenderDestination(width: Int(view.drawableSize.width),
                                                      height: Int(view.drawableSize.height - heightDifference),
                                                      pixelFormat: view.colorPixelFormat,
                                                      commandBuffer: commandBuffer,
                                                      mtlTextureProvider: { () -> MTLTexture in
                                                        return drawable.texture
                })
                // The previously used context.render() didn't seem to respect the scaling/translation of the image
                _ = try? context?.startTask(toRender: image, to: destination)

                commandBuffer?.present(drawable)
                commandBuffer?.commit()
            }
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Do nothing..
    }
}
