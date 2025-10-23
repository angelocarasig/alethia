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
    
    // loading state views
    private let loadingContainer: UIView
    private let progressView: UIProgressView
    private let loadingLabel: UILabel
    
    // error state views
    private let errorContainer: UIView
    private let errorLabel: UILabel
    private let retryButton: UIButton
    
    // current url for retry
    private var currentURL: URL?
    
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
        
        // loading views
        loadingContainer = UIView()
        loadingContainer.backgroundColor = .systemBackground
        loadingContainer.isHidden = true
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        loadingLabel = UILabel()
        loadingLabel.text = "Loading..."
        loadingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // error views
        errorContainer = UIView()
        errorContainer.backgroundColor = .systemBackground
        errorContainer.isHidden = true
        
        errorLabel = UILabel()
        errorLabel.text = "Failed to load image"
        errorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        errorLabel.textColor = .secondaryLabel
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 2
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        retryButton = UIButton(type: .system)
        retryButton.setTitle("Tap to retry", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        
        scrollView.delegate = self
        contentView.addSubview(scrollView)
        scrollView.addSubnode(imageNode)
        
        setupLoadingViews()
        setupErrorViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLoadingViews() {
        contentView.addSubview(loadingContainer)
        loadingContainer.addSubview(progressView)
        loadingContainer.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: loadingContainer.centerYAnchor, constant: -20),
            progressView.widthAnchor.constraint(equalToConstant: 200),
            
            loadingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor)
        ])
    }
    
    private func setupErrorViews() {
        contentView.addSubview(errorContainer)
        errorContainer.addSubview(errorLabel)
        errorContainer.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: errorContainer.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorContainer.centerYAnchor, constant: -20),
            errorLabel.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor, constant: -20),
            
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: errorContainer.centerXAnchor)
        ])
        
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
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
    
    @objc private func handleRetry() {
        guard let url = currentURL else { return }
        loadImage(from: url)
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
        loadingContainer.frame = contentView.bounds
        errorContainer.frame = contentView.bounds
        
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
    
    private func showLoading() {
        loadingContainer.isHidden = false
        errorContainer.isHidden = true
        scrollView.isHidden = true
        progressView.progress = 0
    }
    
    private func showError() {
        loadingContainer.isHidden = true
        errorContainer.isHidden = false
        scrollView.isHidden = true
    }
    
    private func showImage() {
        loadingContainer.isHidden = true
        errorContainer.isHidden = true
        scrollView.isHidden = false
    }
    
    private func loadImage(from url: URL) {
        showLoading()
        
        KingfisherManager.shared.retrieveImage(
            with: url,
            options: [.transition(.fade(0.2))],
            progressBlock: { [weak self] receivedSize, totalSize in
                guard let self = self, totalSize > 0 else { return }
                
                let progress = Float(receivedSize) / Float(totalSize)
                Task { @MainActor in
                    self.progressView.setProgress(progress, animated: true)
                }
            }
        ) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let imageResult):
                    let image = imageResult.image
                    let size = image.size
                    let calculatedAspectRatio = size.height / size.width
                    
                    self.aspectRatio = calculatedAspectRatio
                    self.imageNode.image = image
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                    
                    self.showImage()
                    
                    // trigger self-sizing update if needed
                    if let collectionView = self.superview as? UICollectionView,
                       collectionView.indexPath(for: self) != nil {
                        UIView.performWithoutAnimation {
                            collectionView.collectionViewLayout.invalidateLayout()
                        }
                    }
                    
                case .failure(let error):
                    print("failed to load image: \(error)")
                    self.showError()
                }
            }
        }
    }
    
    func configure(with urlString: String, dimension: CGFloat, dimensionType: CellDimensionType, imageSize: CGSize?) {
        guard let url = URL(string: urlString) else { return }
        
        self.currentURL = url
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
        
        // load image with progress tracking
        loadImage(from: url)
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
        imageNode.image = nil
        aspectRatio = 1.0
        cellDimension = 0
        dimensionType = .width
        scrollView.setZoomScale(1.0, animated: false)
        onZoomStateChanged = nil
        currentURL = nil
        progressView.progress = 0
        showLoading()
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
