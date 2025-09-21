//
//  ShareSheet.swift
//  PerroScan
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let onDismiss: (() -> Void)?
    
    init(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        activityViewController.excludedActivityTypes = excludedActivityTypes
        
        // Force the preview by setting the popover source (important for iPad/larger screens)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: 200, y: 200, width: 0, height: 0)
        }
        
        // Set completion handler
        activityViewController.completionWithItemsHandler = { _, completed, _, error in
            if let error = error {
                print("Share failed with error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.onDismiss?()
            }
        }
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Custom activity item source to ensure proper preview
class ImageActivityItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let breedName: String
    let confidence: Float
    
    init(image: UIImage, breedName: String, confidence: Float) {
        self.image = image
        self.breedName = breedName
        self.confidence = confidence
        super.init()
    }
    
    // This is the placeholder - what appears in the preview
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    // This is the actual item being shared
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    // Subject line for email/messages
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "My dog breed analysis - \(breedName)"
    }
    
    // Thumbnail for the preview
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return image.resized(to: size)
    }
    
    // Link metadata for rich previews
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.image"
    }
}

// Extension to resize images
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

