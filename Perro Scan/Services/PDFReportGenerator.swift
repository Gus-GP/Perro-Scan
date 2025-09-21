//
//  PDFReportGenerator.swift
//  PerroScan
//

import UIKit
import PDFKit
import Charts

class PDFReportGenerator {
    
    private static let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
    private static let margin: CGFloat = 40
    private static let maxContentWidth: CGFloat = 532 // pageSize.width - (margin * 2)
    private static let chartColors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed, .systemPink]
    
    static func generateDetailedReport(
        userImage: UIImage,
        sampleImage: UIImage?,
        breedName: String,
        confidence: Float,
        chartData: [ChartSlice],
        allProbabilities: [ChartSlice],
        breedDetails: DogBreed?
    ) async -> URL? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                print("📄 Starting PDF report generation for \(breedName)")
                
                if let pdfURL = self.createPDFReport(
                    userImage: userImage,
                    sampleImage: sampleImage,
                    breedName: breedName,
                    confidence: confidence,
                    chartData: chartData,
                    allProbabilities: allProbabilities,
                    breedDetails: breedDetails
                ) {
                    print("📄 PDF report generated successfully at: \(pdfURL)")
                    continuation.resume(returning: pdfURL)
                } else {
                    print("❌ Failed to generate PDF report")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private static func createPDFReport(
        userImage: UIImage,
        sampleImage: UIImage?,
        breedName: String,
        confidence: Float,
        chartData: [ChartSlice],
        allProbabilities: [ChartSlice],
        breedDetails: DogBreed?
    ) -> URL? {
        
        // Create temporary file URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let pdfURL = tempDirectory.appendingPathComponent("PerroScan_Report_\(breedName.replacingOccurrences(of: " ", with: "-"))_\(Int(Date().timeIntervalSince1970)).pdf")
        
        // Start PDF context
        UIGraphicsBeginPDFContextToFile(pdfURL.path, pageSize, nil)
        
        guard UIGraphicsGetCurrentContext() != nil else {
            UIGraphicsEndPDFContext()
            return nil
        }
        
        // Generate PDF pages
        generatePDFPages(
            userImage: userImage,
            sampleImage: sampleImage,
            breedName: breedName,
            confidence: confidence,
            chartData: chartData,
            allProbabilities: allProbabilities,
            breedDetails: breedDetails
        )
        
        // End PDF document
        UIGraphicsEndPDFContext()
        
        return pdfURL
    }
    
    private static func generatePDFPages(
        userImage: UIImage,
        sampleImage: UIImage?,
        breedName: String,
        confidence: Float,
        chartData: [ChartSlice],
        allProbabilities: [ChartSlice],
        breedDetails: DogBreed?
    ) {
        
        // PAGE 1: Header, Analysis Summary, Images, and Charts
        startNewPage()
        
        var currentY: CGFloat = margin
        currentY = drawHeader(currentY: currentY)
        currentY = drawAnalysisSummary(breedName: breedName, confidence: confidence, currentY: currentY, chartData: chartData)
        currentY = drawImagesSection(userImage: userImage, sampleImage: sampleImage, currentY: currentY)
        currentY = drawCharts(chartData: chartData, currentY: currentY)
        
        // PAGE 2: Complete breed table
        startNewPage()
        currentY = margin
        currentY = drawSectionTitle("Complete Analysis Results", currentY: currentY)
        currentY = drawStatistics(allProbabilities: allProbabilities, currentY: currentY)
        currentY = drawBreedTable(allProbabilities: allProbabilities, currentY: currentY)
        
        // PAGE 3: Breed Details (if available)
        if let breedDetails = breedDetails {
            startNewPage()
            currentY = margin
            currentY = drawBreedDetailsPage(breed: breedDetails, currentY: currentY)
        }
    }
    
    // MARK: - Helper Functions
    
    private static func getOtherLabel(confidence: Float) -> (label: String, description: String, color: UIColor) {
        if confidence > 0.4 {
            return ("Not a Dog", "Nice try but... not a dog", .gray)
        } else if confidence > 0.2 {
            return ("Unclear Result", "Try another photo", .systemRed)
        } else {
            return ("Other", "Multiple traits detected", .systemOrange)
        }
    }
    
    private static func startNewPage() {
        UIGraphicsBeginPDFPage()
        drawFooter()
    }
    
    private static func drawHeader(currentY: CGFloat) -> CGFloat {
        var y = currentY
        
        // Logo and Title
        let logoSize: CGFloat = 30
        let totalHeaderHeight: CGFloat = logoSize
        let titleText = "Perro Scan - Analysis Report"
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        
        // Calculate total width needed for logo + text
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.systemBlue
        ]
        let titleSize = (titleText as NSString).size(withAttributes: titleAttributes)
        let spacing: CGFloat = 12
        let totalWidth = logoSize + spacing + titleSize.width
        let startX = (pageSize.width - totalWidth) / 2
        
        // Draw logo
        if let logoImage = loadLogoImage() {
            let logoRect = CGRect(x: startX, y: y, width: logoSize, height: logoSize)
            logoImage.draw(in: logoRect)
        }
        
        // Draw title text next to logo
        let titleX = startX + logoSize + spacing
        let titleY = y + (logoSize - titleSize.height) / 2 // Center vertically with logo
        (titleText as NSString).draw(at: CGPoint(x: titleX, y: titleY), withAttributes: titleAttributes)
        
        y += totalHeaderHeight + 10
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        let dateText = "Generated on \(dateFormatter.string(from: Date()))"
        let dateFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let dateHeight = drawCenteredText(dateText, font: dateFont, color: .gray, y: y)
        y += dateHeight + 30
        
        return y
    }

    private static func loadLogoImage() -> UIImage? {
        // Try loading from Asset Catalog first
        if let image = UIImage(named: "Light_Logo") {
            return image
        }
        
        // Fallback to bundle resource
        if let url = Bundle.main.url(forResource: "Light_Logo", withExtension: "heic"),
           let data = try? Data(contentsOf: url),
           let image = UIImage( data: data) {
            return image
        }
        
        return nil
    }

    private static func drawAnalysisSummary(breedName: String, confidence: Float, currentY: CGFloat, chartData: [ChartSlice]) -> CGFloat {
        var y = currentY
        
        let summaryFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        // Check if "Other" is the highest result
        if let highest = chartData.max(by: { $0.value < $1.value }), highest.label == "Other" {
            let otherInfo = getOtherLabel(confidence: Float(highest.value))
            
            // Show the "Other" result prominently
            let resultText = "Primary Result: \(otherInfo.label)"
            let resultHeight = drawText(resultText, font: summaryFont, color: otherInfo.color, x: margin, y: y, maxWidth: maxContentWidth)
            y += resultHeight + 10
            
            // Show description
            let descriptionText = "\(otherInfo.description)"
            let descriptionFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            let descriptionHeight = drawText(descriptionText, font: descriptionFont, color: otherInfo.color, x: margin, y: y, maxWidth: maxContentWidth)
            y += descriptionHeight + 15
            
            // Show confidence for "Other"
            let confidenceText = "Analysis Confidence: \(Int(highest.value * 100))%"
            let confidenceFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let confidenceHeight = drawText(confidenceText, font: confidenceFont, color: .gray, x: margin, y: y, maxWidth: maxContentWidth)
            y += confidenceHeight + 20
            
            // Add recommendation box
            drawRecommendationBox(otherInfo: otherInfo, y: y)
            y += 80
            
        } else {
            // Normal breed result
            let resultText = "Primary Match: \(breedName)"
            let resultHeight = drawText(resultText, font: summaryFont, color: .black, x: margin, y: y, maxWidth: maxContentWidth)
            y += resultHeight + 10
            
            let confidenceText = confidence > 0.5 ? "Confidence: \(Int(confidence * 100))% - Strong Match" : "Confidence: \(Int(confidence * 100))%"
            let confidenceFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            let confidenceColor: UIColor = confidence > 0.5 ? .systemGreen : .systemBlue
            let confidenceHeight = drawText(confidenceText, font: confidenceFont, color: confidenceColor, x: margin, y: y, maxWidth: maxContentWidth)
            y += confidenceHeight + 30
        }
        
        return y
    }

    private static func drawRecommendationBox(otherInfo: (label: String, description: String, color: UIColor), y: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw background box
        context.setFillColor(otherInfo.color.withAlphaComponent(0.1).cgColor)
        let boxRect = CGRect(x: margin, y: y, width: maxContentWidth, height: 70)
        context.fill(boxRect)
        
        // Draw border
        context.setStrokeColor(otherInfo.color.cgColor)
        context.setLineWidth(1)
        context.stroke(boxRect)
        
        // Draw title
        let titleFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        _ = drawText("💡 Recommendation", font: titleFont, color: otherInfo.color, x: margin + 15, y: y + 10, maxWidth: maxContentWidth - 30)
        
        // Draw recommendation text
        let recommendationFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let recommendationText: String
        
        switch otherInfo.label {
        case "Not a Dog":
            recommendationText = "The image appears to be something other than a dog. Please take a photo that clearly shows a dog for accurate breed identification."
        case "Unclear Result":
            recommendationText = "The image quality may be affecting analysis. Try taking a clearer, well-lit photo of the dog from the front or side."
        default:
            recommendationText = "The dog shows characteristics of multiple breeds. This could indicate a mixed breed or unique breed combination."
        }
        
        _ = drawWrappedText(recommendationText, font: recommendationFont, color: .black, x: margin + 15, y: y + 35, maxWidth: maxContentWidth - 30, maxHeight: 30)
    }
    
    private static func drawImagesSection(userImage: UIImage, sampleImage: UIImage?, currentY: CGFloat) -> CGFloat {
        var y = currentY
        
        // Section title
        y = drawSectionTitle("Image Comparison", currentY: y)
        
        let imageSize: CGFloat = 120
        let imageY = y + 10
        
        // User image
        let userImageRect = CGRect(x: margin + 50, y: imageY, width: imageSize, height: imageSize)
        userImage.draw(in: userImageRect)
        
        let labelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        _ = drawCenteredText("Your Photo", font: labelFont, color: .gray, y: imageY + imageSize + 5, centerX: userImageRect.midX)
        
        // Sample image (if available)
        if let sampleImage = sampleImage {
            let sampleImageRect = CGRect(x: pageSize.width - margin - 50 - imageSize, y: imageY, width: imageSize, height: imageSize)
            sampleImage.draw(in: sampleImageRect)
            _ = drawCenteredText("Breed Match", font: labelFont, color: .gray, y: imageY + imageSize + 5, centerX: sampleImageRect.midX)
        }
        
        return imageY + imageSize + 40
    }
    
    private static func drawStatistics(allProbabilities: [ChartSlice], currentY: CGFloat) -> CGFloat {
        let y = currentY
        
        // Simple statistics in a row
        let cardWidth: CGFloat = maxContentWidth / 4
        let statsFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let labelFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        
        let stats = [
            ("Total Breeds", "\(allProbabilities.count)", UIColor.systemBlue),
            ("High Match (>10%)", "\(allProbabilities.filter { $0.value > 0.1 }.count)", UIColor.systemGreen),
            ("Possible (>1%)", "\(allProbabilities.filter { $0.value > 0.01 }.count)", UIColor.systemOrange),
            ("Best Match", "\(String(format: "%.0f", (allProbabilities.first?.value ?? 0) * 100))%", UIColor.systemPurple)
        ]
        
        for (index, stat) in stats.enumerated() {
            let x = margin + CGFloat(index) * cardWidth
            let centerX = x + cardWidth / 2
            
            // Draw value
            _ = drawCenteredText(stat.1, font: statsFont, color: stat.2, y: y, centerX: centerX)
            
            // Draw label
            _ = drawCenteredText(stat.0, font: labelFont, color: .gray, y: y + 20, centerX: centerX)
        }
        
        return y + 50
    }
    
    private static func drawBreedTable(allProbabilities: [ChartSlice], currentY: CGFloat) -> CGFloat {
        var y = currentY
        
        // Table header
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let cellFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        
        guard let context = UIGraphicsGetCurrentContext() else { return y }
        
        let rowHeight: CGFloat = 16
        let rowsPerPage = Int((pageSize.height - 200) / rowHeight) // Calculate rows that fit on a page
        let totalRows = allProbabilities.count
        var currentRow = 0
        
        while currentRow < totalRows {
            // Draw table header with lighter background
            context.setFillColor(UIColor(red: 0.985, green: 0.985, blue: 0.985, alpha: 1.0).cgColor)
            let headerRect = CGRect(x: margin, y: y, width: maxContentWidth, height: 22)
            context.fill(headerRect)
            
            // Header text
            _ = drawText("Rank", font: headerFont, color: .black, x: margin + 8, y: y + 5, maxWidth: 40)
            _ = drawText("Breed Name", font: headerFont, color: .black, x: margin + 50, y: y + 5, maxWidth: 300)
            _ = drawText("Confidence", font: headerFont, color: .black, x: margin + 400, y: y + 5, maxWidth: 100)
            
            y += 22
            
            // Calculate how many rows to show on this page
            let remainingRows = totalRows - currentRow
            let rowsThisPage = min(remainingRows, rowsPerPage)
            
            // Draw table rows
            for i in 0..<rowsThisPage {
                let rowIndex = currentRow + i
                let slice = allProbabilities[rowIndex]
                let rowY = y + CGFloat(i * Int(rowHeight))
                
                // Alternate row background with very light gray
                if i % 2 == 1 {
                    context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0).cgColor) // Very light gray
                    let rowRect = CGRect(x: margin, y: rowY, width: maxContentWidth, height: rowHeight)
                    context.fill(rowRect)
                }
                
                // Rank
                let rankText = "\(rowIndex + 1)"
                _ = drawText(rankText, font: cellFont, color: .gray, x: margin + 12, y: rowY + 3, maxWidth: 30)
                
                // Breed name with color coding
                let nameColor: UIColor = rowIndex == 0 ? .systemBlue :
                                       slice.value > 0.1 ? .systemGreen :
                                       slice.value > 0.01 ? .systemOrange : .gray
                
                var displayName = slice.label
                if displayName.count > 40 {
                    displayName = String(displayName.prefix(37)) + "..."
                }
                
                _ = drawText(displayName, font: cellFont, color: nameColor, x: margin + 50, y: rowY + 3, maxWidth: 340)
                
                // Confidence percentage
                let percentage = "\(String(format: "%.2f", slice.value * 100))%"
                _ = drawText(percentage, font: cellFont, color: nameColor, x: margin + 420, y: rowY + 3, maxWidth: 80)
            }
            
            currentRow += rowsThisPage
            y += CGFloat(rowsThisPage * Int(rowHeight)) + 20
            
            // If there are more rows, start a new page
            if currentRow < totalRows {
                startNewPage()
                y = margin + 30 // Leave space at top of new page
            }
        }
        
        return y
    }
    
    private static func drawCharts(chartData: [ChartSlice], currentY: CGFloat) -> CGFloat {
        var y = currentY
        
        // Generate pie chart with legend
        if let pieChartImage = generatePieChartImage( data: chartData) {
            y = drawSectionTitle("Breed Distribution", currentY: y)
            
            // Draw pie chart
            let chartSize: CGFloat = 200
            let chartX = margin + 20
            let chartRect = CGRect(x: chartX, y: y, width: chartSize, height: chartSize)
            pieChartImage.draw(in: chartRect)
            
            // Draw legend next to pie chart
            drawPieChartLegend(chartData: chartData, startX: chartX + chartSize + 30, startY: y + 30)
            
            y += chartSize + 40
        }
        
        // Generate color-coded bar chart
        if let barChartImage = generateBarChartImage( data: chartData) {
            if y > pageSize.height - 350 { // Check if we need a new page
                startNewPage()
                y = margin
            }
            
            y = drawSectionTitle("Confidence Levels", currentY: y)
            
            let chartWidth: CGFloat = maxContentWidth
            let chartHeight: CGFloat = 220
            let chartRect = CGRect(x: margin, y: y, width: chartWidth, height: chartHeight)
            barChartImage.draw(in: chartRect)
            
            // Draw bar chart legend below
            drawBarChartLegend(chartData: chartData, startY: y + chartHeight + 10)
            
            y += chartHeight + 80
        }
        
        return y
    }
    
    private static func drawPieChartLegend(chartData: [ChartSlice], startX: CGFloat, startY: CGFloat) {
        let font = UIFont.systemFont(ofSize: 11, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        var y = startY
        for (index, slice) in chartData.enumerated() {
            // Draw color indicator
            context.setFillColor(chartColors[index % chartColors.count].cgColor)
            let indicatorRect = CGRect(x: startX, y: y + 2, width: 12, height: 12)
            context.fillEllipse(in: indicatorRect)
            
            // Draw text
            let percentage = String(format: "%.1f", slice.value * 100)
            let text = "\(slice.label) (\(percentage)%)"
            (text as NSString).draw(at: CGPoint(x: startX + 20, y: y), withAttributes: attributes)
            
            y += 18
        }
    }
    
    private static func drawBarChartLegend(chartData: [ChartSlice], startY: CGFloat) {
        let font = UIFont.systemFont(ofSize: 10, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let itemsPerRow = 2 // Reduced from 3 to 2 for more space
        let itemWidth = maxContentWidth / CGFloat(itemsPerRow)
        let maxTextWidth = itemWidth - 25 // Space for indicator + padding
        
        for (index, slice) in chartData.enumerated() {
            let row = index / itemsPerRow
            let col = index % itemsPerRow
            
            let x = margin + CGFloat(col) * itemWidth
            let y = startY + CGFloat(row) * 25 // Increased row height from 20 to 25
            
            // Draw color indicator
            context.setFillColor(chartColors[index % chartColors.count].cgColor)
            let indicatorRect = CGRect(x: x, y: y + 3, width: 10, height: 10)
            context.fillEllipse(in: indicatorRect)
            
            // Create text with percentage
            let percentage = String(format: "%.1f", slice.value * 100)
            let fullText = "\(slice.label) (\(percentage)%)"
            
            // Calculate text size and truncate if needed
            let textSize = (fullText as NSString).size(withAttributes: attributes)
            
            let displayText: String
            if textSize.width > maxTextWidth {
                // Truncate breed name to fit
                let availableWidth = maxTextWidth - ((" (\(percentage)%)" as NSString).size(withAttributes: attributes).width + 10)
                
                // Find how many characters fit
                var truncatedName = slice.label
                while (truncatedName as NSString).size(withAttributes: attributes).width > availableWidth && truncatedName.count > 3 {
                    truncatedName = String(truncatedName.dropLast())
                }
                
                if truncatedName.count < slice.label.count {
                    truncatedName = truncatedName + "..."
                }
                
                displayText = "\(truncatedName) (\(percentage)%)"
            } else {
                displayText = fullText
            }
            
            // Draw the text
            (displayText as NSString).draw(at: CGPoint(x: x + 15, y: y), withAttributes: attributes)
        }
    }
    
    private static func drawBreedDetailsPage(breed: DogBreed, currentY: CGFloat) -> CGFloat {
        var y = currentY
        
        // Page title
        y = drawSectionTitle("Breed Information: \(breed.name)", currentY: y)
        
        // Overview
        let overviewTitle = "Overview"
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let overviewHeight = drawText(overviewTitle, font: titleFont, color: .black, x: margin, y: y, maxWidth: maxContentWidth)
        y += overviewHeight + 10
        
        let overviewFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let overviewTextHeight = drawWrappedText(breed.overview, font: overviewFont, color: .black, x: margin, y: y, maxWidth: maxContentWidth, maxHeight: 100)
        y += overviewTextHeight + 20
        
        // Fun Fact
        let funFactHeight = drawText("Fun Fact", font: titleFont, color: .black, x: margin, y: y, maxWidth: maxContentWidth)
        y += funFactHeight + 10
        
        let funFactTextHeight = drawWrappedText(breed.funFact, font: overviewFont, color: .black, x: margin, y: y, maxWidth: maxContentWidth, maxHeight: 60)
        y += funFactTextHeight + 20
        
        // Traits
        if !breed.traits.isEmpty {
            let traitsHeight = drawText("Key Traits", font: titleFont, color: .black, x: margin, y: y, maxWidth: maxContentWidth)
            y += traitsHeight + 10
            
            for trait in breed.traits {
                if y > pageSize.height - 100 { // Check if we need a new page
                    startNewPage()
                    y = margin
                }
                let bulletText = "• \(trait)"
                let bulletHeight = drawText(bulletText, font: overviewFont, color: .black, x: margin + 10, y: y, maxWidth: maxContentWidth - 20)
                y += bulletHeight + 8
            }
        }
        
        return y
    }
    
    private static func drawSectionTitle(_ title: String, currentY: CGFloat) -> CGFloat {
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let height = drawText(title, font: titleFont, color: .black, x: margin, y: currentY, maxWidth: maxContentWidth)
        return currentY + height + 15
    }
    
    private static func drawText(_ text: String, font: UIFont, color: UIColor, x: CGFloat, y: CGFloat, maxWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let boundingRect = attributedString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        attributedString.draw(in: CGRect(x: x, y: y, width: maxWidth, height: boundingRect.height))
        return boundingRect.height
    }
    
    private static func drawWrappedText(_ text: String, font: UIFont, color: UIColor, x: CGFloat, y: CGFloat, maxWidth: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let boundingRect = attributedString.boundingRect(with: CGSize(width: maxWidth, height: maxHeight), options: .usesLineFragmentOrigin, context: nil)
        attributedString.draw(in: CGRect(x: x, y: y, width: maxWidth, height: min(boundingRect.height, maxHeight)))
        return min(boundingRect.height, maxHeight)
    }
    
    private static func drawCenteredText(_ text: String, font: UIFont, color: UIColor, y: CGFloat, centerX: CGFloat? = nil) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()
        let x = (centerX ?? (pageSize.width / 2)) - (size.width / 2)
        attributedString.draw(at: CGPoint(x: x, y: y))
        return size.height
    }
    
    private static func drawFooter() {
        let footerText = "Generated by Perro Scan - AI-powered dog breed identification"
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        _ = drawCenteredText(footerText, font: footerFont, color: .gray, y: pageSize.height - 30)
    }
    
    // MARK: - Chart Generation
    
    private static func generatePieChartImage(data chartData: [ChartSlice]) -> UIImage? {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // White background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw pie chart using Core Graphics
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius: CGFloat = 75
            var currentAngle: CGFloat = -CGFloat.pi / 2
            
            for (index, slice) in chartData.enumerated() {
                let sliceAngle = CGFloat(slice.value) * 2 * CGFloat.pi
                let endAngle = currentAngle + sliceAngle
                
                cgContext.setFillColor(chartColors[index % chartColors.count].cgColor)
                cgContext.move(to: center)
                cgContext.addArc(center: center, radius: radius, startAngle: currentAngle, endAngle: endAngle, clockwise: false)
                cgContext.fillPath()
                
                // Add white border between slices
                cgContext.setStrokeColor(UIColor.white.cgColor)
                cgContext.setLineWidth(2)
                cgContext.move(to: center)
                cgContext.addArc(center: center, radius: radius, startAngle: currentAngle, endAngle: endAngle, clockwise: false)
                cgContext.strokePath()
                
                currentAngle = endAngle
            }
            
            // Draw center circle for donut effect
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fillEllipse(in: CGRect(x: center.x - 25, y: center.y - 25, width: 50, height: 50))
            cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            cgContext.setLineWidth(1)
            cgContext.strokeEllipse(in: CGRect(x: center.x - 25, y: center.y - 25, width: 50, height: 50))
        }
    }
    
    private static func generateBarChartImage(data chartData: [ChartSlice]) -> UIImage? {
        let size = CGSize(width: maxContentWidth, height: 220)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // White background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Chart area
            let chartRect = CGRect(x: 60, y: 20, width: size.width - 100, height: size.height - 80)
            let barWidth = chartRect.width / CGFloat(chartData.count)
            
            // Draw bars with consistent colors
            for (index, slice) in chartData.enumerated() {
                let barHeight = CGFloat(slice.value) * chartRect.height
                let barRect = CGRect(
                    x: chartRect.minX + CGFloat(index) * barWidth + 4,
                    y: chartRect.maxY - barHeight,
                    width: barWidth - 8,
                    height: barHeight
                )
                
                // Use same color scheme as pie chart
                cgContext.setFillColor(chartColors[index % chartColors.count].cgColor)
                cgContext.fill(barRect)
                
                // Add border to bars
                cgContext.setStrokeColor(UIColor.white.cgColor)
                cgContext.setLineWidth(1)
                cgContext.stroke(barRect)
            }
            
            // Draw Y-axis labels
            let font = UIFont.systemFont(ofSize: 10)
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
            
            // Y-axis labels (0%, 20%, 40%, 60%, 80%, 100%)
            for i in 0...5 {
                let percentage = i * 20
                let text = "\(percentage)%"
                let y = chartRect.maxY - (CGFloat(i) / 5.0) * chartRect.height - 5
                (text as NSString).draw(at: CGPoint(x: 5, y: y), withAttributes: attributes)
                
                // Draw grid lines
                if i > 0 {
                    cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                    cgContext.setLineWidth(0.5)
                    cgContext.move(to: CGPoint(x: chartRect.minX, y: y + 5))
                    cgContext.addLine(to: CGPoint(x: chartRect.maxX, y: y + 5))
                    cgContext.strokePath()
                }
            }
            
            // Draw X and Y axes
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setLineWidth(1)
            // Y-axis
            cgContext.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
            cgContext.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
            // X-axis
            cgContext.move(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
            cgContext.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
            cgContext.strokePath()
        }
    }
}

