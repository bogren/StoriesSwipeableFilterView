import UIKit

class ExampleViewController: UIViewController {

    let filterView: StoriesSwipeableImageView = {
        return StoriesSwipeableImageView()
    }()

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

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        filterView.frame = view.bounds
    }

}


