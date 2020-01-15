import UIKit

final class StoriesSwipeableImageView: StoriesImageView {

    var filters: [Filter]? {
        didSet {
            updateScrollViewContentSize()
            updateCurrentSelected(notify: true)
        }
    }

    var isRefreshingAutomaticallyWhenScrolling: Bool = true

    var selectedFilter: Filter? {
        didSet {
            if selectedFilter != oldValue {
                setNeedsLayout()
            }
        }
    }

    private let scrollView: UIScrollView = UIScrollView()

    private let preprocessingFilter: Filter? = nil

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    private func commonInit() {
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.backgroundColor = .clear

        addSubview(scrollView)
    }

    // MARK: - Life Cycle

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.frame = bounds

        updateScrollViewContentSize()
    }

    // MARK: - Private

    private func updateScrollViewContentSize() {
        let filterCount = filters?.count ?? 0
        scrollView.contentSize = CGSize(width: filterCount * Int(frame.size.width) * 3,
                                        height: Int(frame.size.height))

        if let selectedFilter = selectedFilter {
            scroll(to: selectedFilter, animated: false)
        }
    }

    private func scroll(to filter: Filter, animated: Bool) {
        if let index = filters?.firstIndex(where: { $0 === filter }) {
            let contentOffset = CGPoint(x: scrollView.contentSize.width / 3 + scrollView.frame.size.width * CGFloat(index), y: 0)
            scrollView.setContentOffset(contentOffset, animated: animated)
            updateCurrentSelected(notify: false)
        } else {
            fatalError("Filter is not available in filters collection")
        }
    }

    private func updateCurrentSelected(notify: Bool) {
        if frame.size.width == 0 {
            return
        }
        
        let filterCount = filters?.count ?? 0
        let selectedIndex = Int(scrollView.contentOffset.x + scrollView.frame.size.width / 2) / Int(scrollView.frame.size.width) % filterCount
        var newFilterGroup: Filter?

        if selectedIndex >= 0 && selectedIndex < filterCount {
            newFilterGroup = filters?[selectedIndex]
        } else {
            fatalError("Invalid contentOffset")
        }

        if selectedFilter != newFilterGroup {
            selectedFilter = newFilterGroup

            if notify {
                // Notify delegate?
            }
        }
    }

    // MARK: - Override StoriesImageView

    override func renderedCIImage(in rect: CGRect) -> CIImage? {
        guard var image = super.renderedCIImage(in: rect) else {
            print("Failed to render image")
            return nil
        }

        let timeinterval: CFTimeInterval = 0

        if let preprocessingFilter = self.preprocessingFilter {
            image = preprocessingFilter.imageByProcessingImage(image, at: timeinterval)!
        }

        let extent = image.extent
        let contentSize = scrollView.bounds.size

        if contentSize.width == 0 {
            return image
        }

        let filtersCount = filters?.count ?? 0

        if filtersCount == 0 {
            return image
        }

        let ratio = scrollView.contentOffset.x / contentSize.width

        var index = Int(ratio)
        let upIndex = Int(ceil(ratio))
        let remaningRatio = ratio - CGFloat(index)
        var xImage = extent.size.width * -remaningRatio

        var outputImage: CIImage? = CIImage(color: CIColor(red: 0, green: 0, blue: 0))

        while index <= upIndex {
            let currentIndex = index % filtersCount
            let filter = filters?[currentIndex]
            var filteredImage = filter?.imageByProcessingImage(image, at: timeinterval)
            filteredImage = filteredImage?.cropped(to:
                CGRect(x: extent.origin.x + xImage,
                       y: extent.origin.y,
                       width: extent.size.width,
                       height: extent.size.height)
            )
            outputImage = filteredImage?.composited(over: outputImage!)
            xImage += extent.size.width
            index += 1
        }

        outputImage = outputImage?.cropped(to: extent)

        return outputImage
    }
}

// MARK: - UIScrollViewDelegate

extension StoriesSwipeableImageView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.size.width
        let contentOffsetX = scrollView.contentOffset.x
        let contentSizeWidth = scrollView.contentSize.width
        let normalWidth = CGFloat(filters?.count ?? 0) * width

        if width > 0 && contentSizeWidth > 0 {
            if contentOffsetX <= 0 {
                scrollView.contentOffset = CGPoint(x: contentOffsetX + normalWidth, y: scrollView.contentOffset.y)
            } else if contentOffsetX + width >= contentSizeWidth {
                scrollView.contentOffset = CGPoint(x: contentOffsetX - normalWidth, y: scrollView.contentOffset.y)
            }
        }

        if isRefreshingAutomaticallyWhenScrolling {
            setNeedsDisplay()
        }
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        updateCurrentSelected(notify: true)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentSelected(notify: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentSelected(notify: true)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentSelected(notify: true)
        }
    }

}
