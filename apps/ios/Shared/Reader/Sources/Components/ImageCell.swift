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
        
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            // zoom out
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            // zoom in to 2x at tap point
            let location = gesture.location(in: imageNode.view)
            let rect = zoomRect(for: 2.0, center: location)
            scrollView.zoom(to: rect, animated: true)
        }
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
            // width is fixed to dimension, height calculated from aspect ratio
            let width = cellDimension
            let height = width * aspectRatio
            imageFrame = CGRect(x: 0, y: 0, width: width, height: height)
            
        case .height:
            // height is fixed to dimension, but width must fit within cell bounds
            let height = cellDimension
            let calculatedWidth = height / aspectRatio
            let maxWidth = contentView.bounds.width
            
            // if calculated width exceeds cell width, scale down to fit
            if calculatedWidth > maxWidth {
                // scale down: fit width to maxWidth, recalculate height
                let width = maxWidth
                let scaledHeight = width * aspectRatio
                imageFrame = CGRect(x: 0, y: 0, width: width, height: scaledHeight)
            } else {
                // fits within bounds, use calculated dimensions
                imageFrame = CGRect(x: 0, y: 0, width: calculatedWidth, height: height)
            }
            
        case .aspectFit:
            // scale to fit within cell bounds while maintaining aspect ratio
            let containerWidth = contentView.bounds.width
            let containerHeight = contentView.bounds.height
            
            // calculate dimensions if we scale to fit width
            let widthScaledHeight = containerWidth * aspectRatio
            
            // calculate dimensions if we scale to fit height
            let heightScaledWidth = containerHeight / aspectRatio
            
            // use whichever is the limiting factor
            if widthScaledHeight <= containerHeight {
                // width is limiting factor
                imageFrame = CGRect(x: 0, y: 0, width: containerWidth, height: widthScaledHeight)
            } else {
                // height is limiting factor
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
        
        // load image
        imageNode.setURL(url, resetToDefault: true)
        
        // if size not available, fetch and update
        if imageSize == nil {
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
                        
                        // use preferredLayoutAttributesFitting to self-size
                        if let collectionView = self.superview as? UICollectionView,
                           collectionView.indexPath(for: self) != nil {
                            
                            // trigger self-sizing update
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
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = layoutAttributes.frame.size
        
        // calculate proper size based on aspect ratio and dimension type
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
    }
}

// MARK: - UIScrollViewDelegate

extension ImageCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageNode.view
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageIfNeeded()
        
        // notify when zoom state changes
        let isZoomed = scrollView.zoomScale > 1.0
        onZoomStateChanged?(isZoomed)
    }
}
