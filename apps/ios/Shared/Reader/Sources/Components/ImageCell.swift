//
//  ImageCell.swift
//  Reader
//
//  Created by Angelo Carasig on 21/10/2025.
//

import UIKit
import AsyncDisplayKit
import Kingfisher

/// dimension type for cell configuration
enum CellDimensionType {
    case width
    case height
    case aspectFit
}

/// texture-based cell for displaying manga page images with zoom support
final class ImageCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ImageCell"
    
    private let scrollView: UIScrollView
    private let imageNode: ASNetworkImageNode
    private var aspectRatio: CGFloat = 1.0
    private var cellDimension: CGFloat = 0
    private var dimensionType: CellDimensionType = .width
    
    // loading state
    private let loadingContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        return view
    }()
    
    private let progressRing: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.text = "0%"
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white.withAlphaComponent(0.15)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        config.image = UIImage(systemName: "arrow.clockwise", withConfiguration: imageConfig)
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.title = "Retry"
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .semibold)
            return outgoing
        }
        
        button.configuration = config
        button.isHidden = true
        return button
    }()
    
    private var currentURLString: String?
    
    // zoom state callback
    var onZoomStateChanged: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        
        imageNode = ASNetworkImageNode()
        imageNode.contentMode = .scaleAspectFit
        imageNode.backgroundColor = .clear
        
        super.init(frame: frame)
        
        scrollView.delegate = self
        contentView.addSubview(scrollView)
        scrollView.addSubnode(imageNode)
        
        setupLoadingViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLoadingViews() {
        contentView.addSubview(loadingContainerView)
        loadingContainerView.addSubview(progressRing)
        loadingContainerView.addSubview(percentageLabel)
        loadingContainerView.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            loadingContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            loadingContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            loadingContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            loadingContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            progressRing.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            progressRing.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor),
            progressRing.widthAnchor.constraint(equalToConstant: 80),
            progressRing.heightAnchor.constraint(equalToConstant: 80),
            
            percentageLabel.centerXAnchor.constraint(equalTo: progressRing.centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: progressRing.centerYAnchor),
            
            retryButton.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor)
        ])
        
        retryButton.addTarget(self, action: #selector(retryLoadingImage), for: .touchUpInside)
    }
    
    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let location = gesture.location(in: imageNode.view)
            let rect = zoomRect(for: 2.0, center: location)
            scrollView.zoom(to: rect, animated: true)
        }
    }
    
    @objc private func retryLoadingImage() {
        guard let urlString = currentURLString else { return }
        
        // hide retry button, show progress
        UIView.animate(withDuration: 0.2) {
            self.retryButton.isHidden = true
            self.progressRing.isHidden = false
            self.percentageLabel.isHidden = false
        }
        
        // reload image
        loadImage(urlString: urlString)
    }
    
    private func zoomRect(for scale: CGFloat, center: CGPoint) -> CGRect {
        let width = scrollView.bounds.width / scale
        let height = scrollView.bounds.height / scale
        let x = center.x - (width / 2.0)
        let y = center.y - (height / 2.0)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = contentView.bounds
        
        let imageFrame: CGRect
        
        switch dimensionType {
        case .width:
            let width = cellDimension
            let height = width * aspectRatio
            imageFrame = CGRect(x: 0, y: 0, width: width, height: height)
            
        case .height:
            let height = cellDimension
            let calculatedWidth = height / aspectRatio
            let maxWidth = contentView.bounds.width
            
            if calculatedWidth > maxWidth {
                let width = maxWidth
                let scaledHeight = width * aspectRatio
                imageFrame = CGRect(x: 0, y: 0, width: width, height: scaledHeight)
            } else {
                imageFrame = CGRect(x: 0, y: 0, width: calculatedWidth, height: height)
            }
            
        case .aspectFit:
            let containerWidth = contentView.bounds.width
            let containerHeight = contentView.bounds.height
            
            let widthScaledHeight = containerWidth * aspectRatio
            let heightScaledWidth = containerHeight / aspectRatio
            
            if widthScaledHeight <= containerHeight {
                imageFrame = CGRect(x: 0, y: 0, width: containerWidth, height: widthScaledHeight)
            } else {
                imageFrame = CGRect(x: 0, y: 0, width: heightScaledWidth, height: containerHeight)
            }
        }
        
        imageNode.frame = imageFrame
        scrollView.contentSize = imageFrame.size
        
        centerImageIfNeeded()
    }
    
    private func centerImageIfNeeded() {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageNode.frame.size
        
        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    func configure(with urlString: String, dimension: CGFloat, dimensionType: CellDimensionType, imageSize: CGSize?) {
        guard let url = URL(string: urlString) else { return }
        
        self.currentURLString = urlString
        self.cellDimension = dimension
        self.dimensionType = dimensionType
        
        // reset zoom when configuring new image
        scrollView.setZoomScale(1.0, animated: false)
        
        // set aspect ratio if available
        if let imageSize = imageSize {
            aspectRatio = imageSize.height / imageSize.width
        } else {
            aspectRatio = 1.0
        }
        
        // trigger immediate layout
        setNeedsLayout()
        layoutIfNeeded()
        
        // show loading state
        showLoadingState()
        
        // load image
        loadImage(urlString: urlString)
        
        // if size not available, fetch and update
        if imageSize == nil {
            fetchImageSize(url: url)
        }
    }
    
    private func loadImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        imageNode.setURL(url, resetToDefault: true)
        
        // track progress
        KingfisherManager.shared.retrieveImage(
            with: url,
            options: [.onlyLoadFirstFrame],
            progressBlock: { [weak self] receivedSize, totalSize in
                guard let self = self else { return }
                let progress = Float(receivedSize) / Float(totalSize)
                
                DispatchQueue.main.async {
                    self.updateProgress(progress)
                }
            },
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.hideLoadingState()
                    case .failure:
                        self.showRetryState()
                    }
                }
            }
        )
    }
    
    private func fetchImageSize(url: URL) {
        KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let imageResult):
                let image = imageResult.image
                let size = image.size
                let calculatedAspectRatio = size.height / size.width
                
                Task { @MainActor in
                    self.aspectRatio = calculatedAspectRatio
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                    
                    if let collectionView = self.superview as? UICollectionView,
                       collectionView.indexPath(for: self) != nil {
                        
                        UIView.performWithoutAnimation {
                            collectionView.collectionViewLayout.invalidateLayout()
                        }
                    }
                }
                
            case .failure(let error):
                print("failed to load image for size calculation: \(error)")
            }
        }
    }
    
    private func showLoadingState() {
        loadingContainerView.isHidden = false
        progressRing.isHidden = false
        percentageLabel.isHidden = false
        retryButton.isHidden = true
        progressRing.setProgress(0)
        percentageLabel.text = "0%"
    }
    
    private func hideLoadingState() {
        UIView.animate(withDuration: 0.3) {
            self.loadingContainerView.alpha = 0
        } completion: { _ in
            self.loadingContainerView.isHidden = true
            self.loadingContainerView.alpha = 1
        }
    }
    
    private func showRetryState() {
        progressRing.isHidden = true
        percentageLabel.isHidden = true
        retryButton.isHidden = false
    }
    
    private func updateProgress(_ progress: Float) {
        let percentage = Int(progress * 100)
        progressRing.setProgress(progress)
        percentageLabel.text = "\(percentage)%"
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = layoutAttributes.frame.size
        
        let fittingSize: CGSize
        
        switch dimensionType {
        case .width:
            let width = cellDimension > 0 ? cellDimension : targetSize.width
            let height = width * aspectRatio
            fittingSize = CGSize(width: width, height: height)
            
        case .height:
            let height = cellDimension > 0 ? cellDimension : targetSize.height
            let width = height / aspectRatio
            fittingSize = CGSize(width: width, height: height)
            
        case .aspectFit:
            fittingSize = targetSize
        }
        
        layoutAttributes.frame.size = fittingSize
        return layoutAttributes
    }
    
    override var intrinsicContentSize: CGSize {
        switch dimensionType {
        case .width:
            let width = cellDimension
            let height = width * aspectRatio
            return CGSize(width: width, height: height)
            
        case .height:
            let height = cellDimension
            let width = height / aspectRatio
            return CGSize(width: width, height: height)
            
        case .aspectFit:
            return contentView.bounds.size
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageNode.url = nil
        aspectRatio = 1.0
        cellDimension = 0
        dimensionType = .width
        scrollView.setZoomScale(1.0, animated: false)
        onZoomStateChanged = nil
        currentURLString = nil
        
        // reset loading state
        loadingContainerView.isHidden = true
        loadingContainerView.alpha = 1
        progressRing.setProgress(0)
        percentageLabel.text = "0%"
        retryButton.isHidden = true
    }
}

// MARK: - UIScrollViewDelegate

extension ImageCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageNode.view
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageIfNeeded()
        
        let isZoomed = scrollView.zoomScale > 1.0
        onZoomStateChanged?(isZoomed)
    }
}

// MARK: - Circular Progress View

private final class CircularProgressView: UIView {
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    private var progress: Float = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        // track layer (background circle)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
        trackLayer.lineWidth = 3
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)
        
        // progress layer (animated circle)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.lineWidth = 3
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - 3) / 2
        
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
    
    func setProgress(_ progress: Float) {
        self.progress = progress
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        progressLayer.strokeEnd = CGFloat(progress)
        CATransaction.commit()
    }
}
