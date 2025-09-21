//
//  ResultsView.swift
//  PerroScan
//

import SwiftUI
import Charts

struct ResultsView: View {
    @EnvironmentObject private var viewModel: ClassificationViewModel
    @State private var selectedBreed: DogBreed?
    @State private var selectedTab = 0 // 0: Pie, 1: Bar, 2: Table
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if !viewModel.result.isEmpty {
                    chartHeader
                    chartToggle
                    
                    switch selectedTab {
                    case 0:
                        pieChartView
                        probabilityList
                    case 1:
                        barChartView
                    case 2:
                        tableView
                    default:
                        pieChartView
                        probabilityList
                    }
                }
                
                if viewModel.result.isEmpty {
                    emptyStateView
                }
            }
        }
        .fullScreenCover(item: $selectedBreed) { breed in
            DogBreedDetailView(breed: breed)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getOtherLabel(confidence: Double) -> (label: String, description: String, color: Color) {
        if confidence > 0.4 {
            return ("Not a Dog", "Nice try but... not a dog", .gray)
        } else {
            return ("Other", "Multiple traits detected", .orange)
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Results Yet",
            systemImage: "pawprint.fill",
            description: Text("Scan a dog photo to see breed predictions.")
        )
    }
    
    private var chartHeader: some View {
        Text(selectedTab == 0 ? "Top 5 Breeds" :
             selectedTab == 1 ? "Dog Breed Distribution" :
             "All Results")
            .font(.title)
            .fontWeight(.bold)
    }
    
    private var chartToggle: some View {
        Picker("View Type", selection: $selectedTab) {
            Text("Pie Chart").tag(0)
            Text("Bar Chart").tag(1)
            Text("Table").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    private var pieChartView: some View {
        Chart(viewModel.result.topFiveWithOther) { slice in
            SectorMark(
                angle: .value("Probability", slice.value),
                innerRadius: .ratio(0.80),
                outerRadius: slice.value == viewModel.result.topFiveWithOther.max(by: { $0.value < $1.value })?.value ? .ratio(1.0) : .ratio(0.95)
            )
            .foregroundStyle(by: .value("Breed", slice.label))
            .opacity(slice.value == viewModel.result.topFiveWithOther.max(by: { $0.value < $1.value })?.value ? 1.0 : 0.7)
        }
        .chartLegend(position: .bottom, alignment: .center)
        .frame(height: 260)
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(alignment: .center) {
            // Center label showing the highest confidence
            VStack(spacing: 1) {
                if let highest = viewModel.result.topFiveWithOther.max(by: { $0.value < $1.value }) {
                    if highest.label == "Other" {
                        let otherInfo = getOtherLabel(confidence: highest.value)
                        Text(otherInfo.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.1f", highest.value * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(otherInfo.color)
                        
                        Text(otherInfo.description)
                            .font(.caption2)
                            .foregroundColor(otherInfo.color)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    } else {
                        Text(highest.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text("\(String(format: "%.1f", highest.value * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        // Only show "Strong Match" if probability > 50%
                        if highest.value > 0.5 {
                            Text("Strong Match")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text("Top Match")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: 120) // Constrain width to fit better in center
        }
    }
    
    private var barChartView: some View {
        VStack(spacing: 12) {
            
            ScrollView(.horizontal, showsIndicators: true) {
                Chart(viewModel.result.allProbabilities) { slice in
                    BarMark(
                        x: .value("Breed", slice.label),
                        y: .value("Probability", slice.value * 100)
                    )
                    .foregroundStyle(
                        slice.value > 0.1 ? .green :
                        slice.value > 0.01 ? .yellow : .gray.opacity(0.5)
                    )
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(String(format: "%.1f", doubleValue))%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(width: max(1200, CGFloat(viewModel.result.allProbabilities.count) * 8), height: 300)
                .padding(.vertical, 20)
                .chartLegend(.hidden)
            }
            .frame(height: 450)
            
            // Simple Statistics
            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.result.allProbabilities.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Total Breeds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.result.allProbabilities.filter { $0.value > 0.10 }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("High Match")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.result.allProbabilities.filter { $0.value > 0.01 }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    Text("Possible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    let topResult = viewModel.result.allProbabilities.first?.value ?? 0
                    Text("\(String(format: "%.0f", topResult * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("Best Match")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var tableView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("All \(viewModel.result.allProbabilities.count) Breeds")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.result.allProbabilities.enumerated()), id: \.element.id) { index, slice in
                        HStack {
                            Text("\(index + 1).")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            
                            if let breed = DogBreedStore.getBreed(named: slice.label) {
                                Button {
                                    selectedBreed = breed
                                } label: {
                                    Text(slice.label)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(slice.label)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Text("\(String(format: "%.2f", slice.value * 100))%")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(index % 2 == 0 ? .clear : .gray.opacity(0.05))
                    }
                }
            }
            .background(.gray.opacity(0.02))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var probabilityList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Analysis Results")
                    .font(.headline)
                
                Spacer()
                
                // Confidence indicator
                if let highest = viewModel.result.topFiveWithOther.max(by: { $0.value < $1.value }) {
                    HStack(spacing: 4) {
                        if highest.label == "Other" {
                            let otherInfo = getOtherLabel(confidence: highest.value)
                            Image(systemName: otherInfo.color == .gray ? "questionmark.circle.fill" : "pawprint.fill")
                            .foregroundColor(otherInfo.color)
                            .font(.caption)
                            
                            Text(otherInfo.label)
                                .font(.caption)
                                .foregroundColor(otherInfo.color)
                            
                        } else {
                            // Only show "Strong Match" if probability > 50%
                            if highest.value > 0.5 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text("Strong Match")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Top Match")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 6) {
                ForEach(viewModel.result.topFiveWithOther) { slice in
                    probabilityRow(for: slice)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func probabilityRow(for slice: ChartSlice) -> some View {
        let isHighest = slice.value == viewModel.result.topFiveWithOther.max(by: { $0.value < $1.value })?.value
        
        return HStack {
            if slice.label == "Other" {
                let otherInfo = getOtherLabel(confidence: slice.value)
                
                HStack(spacing: 6) {
                    Image(systemName: otherInfo.color == .gray ? "questionmark.circle.fill" :
                                      otherInfo.color == .red ? "exclamationmark.triangle.fill" :
                                      "pawprint.fill")
                        .foregroundColor(isHighest ? otherInfo.color : .secondary)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(otherInfo.label)
                            .font(.body)
                            .foregroundStyle(isHighest ? otherInfo.color : .secondary)
                        
                        if isHighest {
                            Text(otherInfo.description)
                                .font(.caption2)
                                .foregroundStyle(otherInfo.color.opacity(0.8))
                        }
                    }
                }
            } else {
                if let breed = DogBreedStore.getBreed(named: slice.label) {
                    Button {
                        selectedBreed = breed
                    } label: {
                        HStack(spacing: 6) {
                            if isHighest {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            
                            Text(slice.label)
                                .font(.body)
                                .foregroundStyle(.blue)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 6) {
                        if isHighest {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Text(slice.label)
                            .font(.body)
                            .foregroundStyle(isHighest ? .primary : .secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(slice.value, format: .percent.precision(.fractionLength(2)))
                .monospacedDigit()
                .font(.body)
                .fontWeight(isHighest ? .bold : .regular)
                .foregroundStyle(isHighest ? (slice.label == "Other" ? getOtherLabel(confidence: slice.value).color : .blue) : .secondary)
            
            if slice.label != "Other" && DogBreedStore.getBreed(named: slice.label) != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHighest ? (slice.label == "Other" ? getOtherLabel(confidence: slice.value).color.opacity(0.1) : .blue.opacity(0.1)) : .clear)
        .cornerRadius(8)
    }
}

#Preview {
    ResultsView()
        .environmentObject(ClassificationViewModel())
}

