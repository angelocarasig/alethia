//
//  VerticalImageNode.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import AsyncDisplayKit
import UIKit
import Kingfisher

final class VerticalImageNode: ASCellNode {
    // MARK: - Properties
    
    let page: Page
    var savedOffset: CGFloat?
    weak var delegate: VerticalReaderController?
    
    // UI Components
    private let containerNode = ASDisplayNode()
    private let imageNode = ASImageNode()
    private let loadingNode = ASDisplayNode()
    
    // State tracking
    private var aspectRatio: CGFloat?
    private var isLoading = true
    private var imageSize: CGSize?
    
    // MARK: - Initialization
    
    init(page: Page) {
        self.page = page
        
        super.init()
        
        // Configure self
        backgroundColor = .black
        automaticallyManagesSubnodes = true
        
        // Configure container node
        containerNode.backgroundColor = .black
        
        // Configure image node
        imageNode.contentMode = .scaleAspectFit // Changed to scaleAspectFit to prevent cropping
        imageNode.backgroundColor = .black
        imageNode.clipsToBounds = true
        imageNode.shouldAnimateSizeChanges = false // Important for smooth transitions
        
        // Configure loading indicator
        loadingNode.backgroundColor = .clear
        loadingNode.setViewBlock {
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .white
            activityIndicator.startAnimating()
            return activityIndicator
        }
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        // Load the image
        loadImage()
    }
    
    // MARK: - Layout
    
//    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
//        // If we have an image with an aspect ratio, use it to determine height
//        if let aspectRatio = aspectRatio {
//            // Calculate proper height based on aspect ratio
//            let width = constrainedSize.max.width
//            let height = width * aspectRatio
//            
//            // Explicitly set image node size based on aspect ratio
//            imageNode.style.preferredSize = CGSize(width: width, height: height)
//            
//            // Create a ratio layout spec based on the image's aspect ratio
//            let imageRatioSpec = ASRatioLayoutSpec(ratio: aspectRatio, child: imageNode)
//            
//            // Position loading indicator in the center of the container
//            let loadingCenterSpec = ASCenterLayoutSpec(
//                centeringOptions: .XY,
//                sizingOptions: .minimumXY,
//                child: loadingNode
//            )
//            
//            // Create an overlay with the image and loading indicator
//            return ASOverlayLayoutSpec(
//                child: imageRatioSpec,
//                overlay: loadingCenterSpec
//            )
//        } else {
//            // When no image is loaded yet, create a placeholder with loading indicator
//            containerNode.style.preferredSize = constrainedSize.max
//            
//            // Center loading indicator
//            let loadingCenterSpec = ASCenterLayoutSpec(
//                centeringOptions: .XY,
//                sizingOptions: .minimumXY,
//                child: loadingNode
//            )
//            
//            return ASOverlayLayoutSpec(
//                child: containerNode,
//                overlay: loadingCenterSpec
//            )
//        }
//    }
    
    // MARK: - Image Loading
    
    private func loadImage() {
        guard let url = URL(string: page.contentUrl) else {
            isLoading = false
            loadingNode.isHidden = true
            return
        }
        
        // Create a modifier for adding the Referer header
        let modifier = AnyModifier { request in
            var mutableRequest = request
            mutableRequest.setValue(self.page.contentReferer, forHTTPHeaderField: "Referer")
            return mutableRequest
        }
        
        // Set up Kingfisher options
        let options: KingfisherOptionsInfo = [
            .requestModifier(modifier),
            .transition(.fade(0.2)),
            .backgroundDecode,
            .retryStrategy(DelayRetryStrategy(maxRetryCount: 3)) // Add retry for better reliability
        ]
        
        // Load the image using Kingfisher
        KingfisherManager.shared.retrieveImage(
            with: url,
            options: options
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Stop loading indicator
                self.isLoading = false
                (self.loadingNode.view as? UIActivityIndicatorView)?.stopAnimating()
                self.loadingNode.alpha = 0
                
                // Process the result
                switch result {
                case .success(let imageResult):
                    let image = imageResult.image
                    
                    // Calculate aspect ratio for layout
                    let aspectRatio = image.size.height / image.size.width
                    self.aspectRatio = aspectRatio
                    self.imageSize = image.size
                    
                    // Set image
                    self.imageNode.image = image
                    
                    // Fade in image
                    self.imageNode.alpha = 0
                    UIView.animate(withDuration: 0.3) {
                        self.imageNode.alpha = 1.0
                    }
                    
                    // Calculate the size of the node based on the image aspect ratio
                    let screenWidth = UIScreen.main.bounds.width
                    let calculatedHeight = screenWidth * aspectRatio
                    
                    // Update node size and layout
                    self.style.preferredSize = CGSize(width: screenWidth, height: calculatedHeight)
                    
                    // Trigger a layout pass to apply the new size
                    self.setNeedsLayout()
                    self.transitionLayout(withAnimation: true, shouldMeasureAsync: false)
                    
                case .failure(let error):
                    print("Error loading image: \(error.localizedDescription)")
                    
                    // Show error state (could add a retry button)
                    self.loadingNode.isHidden = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        //        delegate?.toggleControls?()
    }
    
    // MARK: - Lifecycle
    
    override func didEnterPreloadState() {
        super.didEnterPreloadState()
        
        // Ensure image loading started
        if imageNode.image == nil && !isLoading {
            isLoading = true
            (loadingNode.view as? UIActivityIndicatorView)?.startAnimating()
            loadingNode.alpha = 1.0
            loadImage()
        }
    }
    
    override func didExitDisplayState() {
        super.didExitDisplayState()
        
        // Cancel any ongoing image download to save resources
        if isLoading {
            KingfisherManager.shared.downloader.cancel(url: URL(string: page.contentUrl)!)
        }
    }
    
    // This method is crucial for layout transitions when image loads
//    override func animateLayoutTransition(_ context: ASContextTransitioning) {
//        // Update image node frame to final dimensions
//        imageNode.frame = context.finalFrame(for: imageNode)
//        
//        // Complete the transition
//        context.completeTransition(true)
//        
//        // Notify delegate about layout changes if needed
//        if let delegate = delegate {
//            DispatchQueue.main.async {
////                delegate.updateLayoutIfNeeded?()
//            }
//        }
//        
//        // Handle offset preservation if needed
//        if let manager = owningNode as? ASCollectionNode,
//           let layout = manager.collectionViewLayout as? VerticalLayout,
//           let indexPath = indexPath {
//            
//            let yPosition = manager.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame.origin.y ?? 0
//            layout.isInsertingCellsToTop = yPosition < manager.contentOffset.y
//            
//            if let savedOffset = savedOffset {
//                let requestedOffset = imageNode.frame.height * savedOffset
//                manager.contentOffset.y += requestedOffset
//                self.savedOffset = nil
//            }
//        }
//    }
}


extension VerticalImageNode {
    // ... existing properties ...
    
    // Add a method to calculate correct size based on image dimensions
    private func calculateSize(for image: UIImage, containerWidth: CGFloat) -> CGSize {
        let imageRatio = image.size.height / image.size.width
        let height = containerWidth * imageRatio
        return CGSize(width: containerWidth, height: height)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // If we have an image with a correct aspect ratio
        if let aspectRatio = aspectRatio, imageNode.image != nil {
            // Create a spec with the proper ratio
            let ratioSpec = ASRatioLayoutSpec(ratio: aspectRatio, child: imageNode)
            
            // Create a wrapper to ensure the node fills its parent width
            let wrapper = ASWrapperLayoutSpec(layoutElement: ratioSpec)
            wrapper.style.width = ASDimension(unit: .fraction, value: 1.0)
            
            // Position loading indicator in the center
            let loadingCenterSpec = ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: loadingNode
            )
            
            // Create an overlay with the ratio spec and loading indicator
            return ASOverlayLayoutSpec(
                child: wrapper,
                overlay: loadingCenterSpec
            )
        } else {
            // Create a placeholder with loading indicator when no image
            containerNode.style.preferredSize = constrainedSize.max
            
            // Center loading indicator
            let loadingCenterSpec = ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: loadingNode
            )
            
            return ASOverlayLayoutSpec(
                child: containerNode,
                overlay: loadingCenterSpec
            )
        }
    }
    
    // Override to properly handle layout transitions when image loads
    override func animateLayoutTransition(_ context: ASContextTransitioning) {
        // Update frames to final dimensions
        imageNode.frame = context.finalFrame(for: imageNode)
        containerNode.frame = context.finalFrame(for: containerNode)
        
        // Complete the transition
        context.completeTransition(true)
        
        // Check if we need to adjust scroll position for resumption
        if let savedOffset = savedOffset,
            let collectionNode = owningNode as? ASCollectionNode,
           let indexPath = indexPath {
            // Get the layout
            let layout = collectionNode.collectionViewLayout as? VerticalLayout
            
            // Calculate offset based on the saved position
            let newOffset = imageNode.frame.height * savedOffset
            
            // Apply offset adjustment
            UIView.performWithoutAnimation {
                collectionNode.contentOffset.y += newOffset
            }
            
            // Clear saved offset
            self.savedOffset = nil
            
            // Notify delegate
            delegate?.clearResumption()
        }
    }
    
    // In the image loading completion handler, update as follows:
    private func onImageLoaded(_ image: UIImage) {
        // Calculate the aspect ratio
        aspectRatio = image.size.height / image.size.width
        
        // Set image
        imageNode.image = image
        
        // Calculate new size
        let screenWidth = UIScreen.main.bounds.width
        let newSize = calculateSize(for: image, containerWidth: screenWidth)
        
        // Update layout with transition
        setNeedsLayout()
//        transitionLayout(with: .init(min: .zero, max: size), animated: true, shouldMeasureAsync: false)
        
        // Fade in the image
        UIView.animate(withDuration: 0.3) {
            self.imageNode.alpha = 1.0
            self.loadingNode.alpha = 0
        }
    }
}
