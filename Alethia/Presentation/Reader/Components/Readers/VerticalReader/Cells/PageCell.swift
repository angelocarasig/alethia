//
//  PageCell.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/5/2025.
//

import UIKit
import Kingfisher
import AsyncDisplayKit

class PageCell: UICollectionViewCell {
    // MARK: - Properties
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var bottomBorder: UIView?
    private var page: Page?
    private var orientation: Orientation = .Infinite
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .black
        
        // Add container view with proper sizing
        containerView.backgroundColor = .black
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Configure image view to maintain aspect ratio
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .black
        imageView.clipsToBounds = true
        
        containerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Initial constraints for Infinite scrolling (default)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            // Make width match container width exactly (fills horizontally)
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
        
        // Configure loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        containerView.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with page: Page, orientation: Orientation) {
        loadingIndicator.startAnimating()
        self.page = page
        self.orientation = orientation
        
        // Configure cell appearance based on orientation
        configureForOrientation()
        
        if let imageURL = URL(string: page.url) {
            // Use Kingfisher to load and cache the image
            imageView.kf.setImage(
                with: imageURL,
                placeholder: nil,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage,
                    .backgroundDecode,
                    .processingQueue(.dispatch(.global(qos: .userInitiated)))
                ],
                completionHandler: { [weak self] result in
                    self?.loadingIndicator.stopAnimating()
                    
                    // Adjust image view constraints based on actual image dimensions
                    if case .success(let imageResult) = result {
                        let image = imageResult.image
                        
                        DispatchQueue.main.async {
                            // Set the correct content mode based on image dimensions
                            if image.size.width > 0 && image.size.height > 0 {
                                let aspectRatio = image.size.height / image.size.width
                                
                                // For very tall images, use scaleAspectFit to show the full image
                                // For images closer to square, use scaleAspectFill for better appearance
                                // Apply content mode based on orientation
                                switch self?.orientation {
                                case .Vertical:
                                    // In true pagination mode, always fit entire image on screen
                                    self?.imageView.contentMode = .scaleAspectFit
                                    
                                case .LeftToRight, .RightToLeft:
                                    // Will be implemented later
                                    self?.imageView.contentMode = .scaleAspectFit
                                    
                                case .Infinite, nil:
                                    // For Infinite scrolling, use original behavior
                                    if aspectRatio > 2.0 {
                                        self?.imageView.contentMode = .scaleAspectFit
                                    } else {
                                        self?.imageView.contentMode = .scaleAspectFill
                                    }
                                }
                            }
                            
                            // Force layout to update with correct dimensions
                            self?.layoutIfNeeded()
                            self?.setNeedsLayout()
                        }
                    }
                }
            )
        } else {
            loadingIndicator.stopAnimating()
            imageView.image = nil
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        // Return the original layout attributes to use cell sizing from collection view
        return layoutAttributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        loadingIndicator.startAnimating()
        
        // Remove any orientation-specific UI elements
        bottomBorder?.removeFromSuperview()
        bottomBorder = nil
    }
    
    // MARK: - Orientation Configuration
    private func configureForOrientation() {
        // Clean up any existing orientation UI
        bottomBorder?.removeFromSuperview()
        bottomBorder = nil
        
        // Remove any custom transforms
        imageView.transform = .identity
        
        // Configure based on the current orientation
        switch orientation {
        case .Vertical:
            // For Vertical pagination mode, make sure we center the image properly in the screen
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Set image content mode for pagination
                self.imageView.contentMode = .scaleAspectFit
                
                // Remove any old constraints and set center Y constraint
                for constraint in self.imageView.constraints {
                    if constraint.firstAttribute == .top || constraint.firstAttribute == .bottom {
                        self.imageView.removeConstraint(constraint)
                    }
                }
                
                // Center the image Vertically
                NSLayoutConstraint.activate([
                    self.imageView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor)
                ])
                
                // Add extra padding to center the image in the screen
                // This helps ensure the image is precisely centered within a page
                let screenHeight = UIScreen.main.bounds.height
                let cellHeight = self.bounds.height
                
                // Calculate how much extra spacing we need to center in screen
                let screenCenterY = screenHeight / 2
                let cellCenterY = cellHeight / 2
                
                // Adjust position only if needed
                if abs(screenCenterY - cellCenterY) > 10 {
                    // Center the image to the screen rather than the cell
                    let offsetY = screenCenterY - cellCenterY
                    self.containerView.transform = CGAffineTransform(translationX: 0, y: offsetY)
                }
            }
            
        case .LeftToRight, .RightToLeft:
            // Will be implemented later
            imageView.contentMode = .scaleAspectFit
            containerView.transform = .identity
            
        case .Infinite:
            // Revert to original Infinite scrolling layout
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Reset transform
                self.containerView.transform = .identity
                
                // Set content mode in Infinite mode
                self.imageView.contentMode = .scaleAspectFill
                
                // Ensure top and bottom constraints are active
                if self.imageView.constraints.first(where: { $0.firstAttribute == .top }) == nil {
                    NSLayoutConstraint.activate([
                        self.imageView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
                        self.imageView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor)
                    ])
                }
            }
        }
    }
}
