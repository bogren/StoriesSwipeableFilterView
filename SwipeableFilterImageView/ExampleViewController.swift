import UIKit

class ExampleViewController: UIViewController {

    private let filterView = StoriesSwipeableImageView()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(filterView)

        filterView.setImage(with: UIImage(named: "wow")!)
        filterView.filters = [
            Filter.emptyFilter(),
            Filter(ciFilter: CIFilter(name: "CIPhotoEffectNoir")!),
            Filter(ciFilter: CIFilter(name: "CIPhotoEffectChrome")!),
            Filter(ciFilter: CIFilter(name: "CIPhotoEffectInstant")!),
            Filter(ciFilter: CIFilter(name: "CIPhotoEffectFade")!)
        ]

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(saveToCameraRoll))
        tapGestureRecognizer.numberOfTapsRequired = 2
        filterView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        filterView.frame = view.bounds
    }

    // MARK: - Persist Image

    @objc
    private func saveToCameraRoll() {
        if let image = filterView.renderedUIImage() {
            UIImageWriteToSavedPhotosAlbum(image,
                                           self,
                                           #selector(image(_ :didFinishSavingWithError: contextInfo:)),
                                           nil)
        }
    }

    @objc
    private func image(_ image: UIImage,
                       didFinishSavingWithError error: Error?,
                       contextInfo: UnsafeRawPointer) {
        if error == nil {
            let alert = UIAlertController(title: "Saved",
                                          message: "Image saved successfully",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))

            present(alert, animated: true)
        }
    }

}


