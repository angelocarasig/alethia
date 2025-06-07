//
//  QueueStatusView.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import SwiftUI

struct QueueStatusView: View {
    @StateObject private var queueProvider = QueueProvider.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                ActiveOperationsTab()
                    .tabItem {
                        Label("Active", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .badge(activeOperationsCount)
                    .tag(0)
                
                PendingOperationsTab()
                    .tabItem {
                        Label("Pending", systemImage: "clock.circle.fill")
                    }
                    .badge(pendingOperationsCount)
                    .tag(1)
                
                CompletedOperationsTab()
                    .tabItem {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                    }
                    .badge(completedOperationsCount)
                    .tag(2)
                
                FailedOperationsTab()
                    .tabItem {
                        Label("Failed", systemImage: "xmark.circle.fill")
                    }
                    .badge(failedOperationsCount)
                    .tag(3)
            }
            .environmentObject(queueProvider)
        }
    }
    
    private var activeOperationsCount: Int {
        queueProvider.operations.values.filter { operation in
            if case .ongoing = operation.state { return true }
            return false
        }.count
    }
    
    private var pendingOperationsCount: Int {
        queueProvider.operations.values.filter { $0.state == .pending }.count
    }
    
    private var completedOperationsCount: Int {
        queueProvider.operations.values.filter { $0.state == .completed }.count
    }
    
    private var failedOperationsCount: Int {
        queueProvider.operations.values.filter {
            if case .failed = $0.state { return true }
            return false
        }.count
    }
}

private struct ActiveOperationsTab: View {
    @EnvironmentObject private var queueProvider: QueueProvider
    @State private var animationScale = false
    
    private var activeOperations: [QueueOperation] {
        queueProvider.operations.values.filter { operation in
            if case .ongoing = operation.state { return true }
            return false
        }.sorted { $0.id < $1.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if activeOperations.isEmpty {
                    EmptyStateView(
                        icon: "arrow.clockwise.circle.fill",
                        title: "No Active Operations",
                        description: "All operations are either pending or completed",
                        color: .blue
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Constants.Spacing.large) {
                            ForEach(activeOperations, id: \.id) { operation in
                                ActiveOperationCard(operation: operation)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(Constants.Padding.screen)
                    }
                }
            }
            .navigationTitle("Active Operations")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct PendingOperationsTab: View {
    @EnvironmentObject private var queueProvider: QueueProvider
    
    private var pendingOperations: [QueueOperation] {
        queueProvider.operations.values.filter { $0.state == .pending }
            .sorted { $0.id < $1.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if pendingOperations.isEmpty {
                    EmptyStateView(
                        icon: "clock.circle.fill",
                        title: "No Pending Operations",
                        description: "All operations are either active or completed",
                        color: .orange
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Constants.Spacing.large) {
                            ForEach(pendingOperations, id: \.id) { operation in
                                PendingOperationCard(operation: operation)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(Constants.Padding.screen)
                    }
                }
            }
            .navigationTitle("Pending Operations")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct CompletedOperationsTab: View {
    @EnvironmentObject private var queueProvider: QueueProvider
    @State private var showClearAlert = false
    
    private var completedOperations: [QueueOperation] {
        queueProvider.operations.values.filter { $0.state == .completed }
            .sorted { $0.id < $1.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if completedOperations.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Completed Operations",
                        description: "Completed operations will appear here",
                        color: .green
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Constants.Spacing.large) {
                            ForEach(completedOperations, id: \.id) { operation in
                                CompletedOperationCard(operation: operation)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(Constants.Padding.screen)
                    }
                }
            }
            .navigationTitle("Completed Operations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !completedOperations.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showClearAlert = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                                .labelStyle(.titleAndIcon)
                        }
                        .tint(.red)
                    }
                }
            }
            .alert("Clear All Completed?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        clearAllCompleted()
                    }
                }
            } message: {
                Text("This will remove all completed operations from the list.")
            }
        }
    }
    
    private func clearAllCompleted() {
        let completedIds = completedOperations.map(\.id)
        for id in completedIds {
            queueProvider.operations.removeValue(forKey: id)
        }
    }
}

private struct FailedOperationsTab: View {
    @EnvironmentObject private var queueProvider: QueueProvider
    @State private var showClearAlert = false
    
    private var failedOperations: [QueueOperation] {
        queueProvider.operations.values.filter {
            if case .failed = $0.state { return true }
            return false
        }.sorted { $0.id < $1.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if failedOperations.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Failed Operations",
                        description: "Great! No operations have failed",
                        color: .green
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Constants.Spacing.large) {
                            ForEach(failedOperations, id: \.id) { operation in
                                FailedOperationCard(operation: operation)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(Constants.Padding.screen)
                    }
                }
            }
            .navigationTitle("Failed Operations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !failedOperations.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showClearAlert = true
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            }
            .alert("Clear All Failed?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        clearAllFailed()
                    }
                }
            } message: {
                Text("This will remove all failed operations from the list.")
            }
        }
    }
    
    private func clearAllFailed() {
        let failedIds = failedOperations.map(\.id)
        for id in failedIds {
            queueProvider.operations.removeValue(forKey: id)
        }
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Constants.Spacing.toolbar * 1.25) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(color.gradient)
                .symbolEffect(.bounce, options: .repeating.speed(0.5))
            
            VStack(spacing: Constants.Spacing.regular) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Constants.Icon.Size.regular)
    }
}

private struct ActiveOperationCard: View {
    let operation: QueueOperation
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(operationColor.gradient)
                        .frame(width: 48, height: 48)
                    
                    operationIcon
                        .font(.title3)
                        .foregroundColor(.white)
                        .symbolEffect(.rotate.byLayer, options: .repeating.speed(1))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: Constants.Spacing.regular) {
                        Text(operationTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        OperationTypePill(type: operation.type)
                    }
                    
                    Text(operationSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        operation.cancel()
                    }
                } label: {
                    Text("Cancel")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, Constants.Spacing.large)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if case .ongoing(let progress) = operation.state {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.checkbox)
                                .fill(Color(.systemGray5))
                                .frame(height: Constants.Spacing.regular)
                            
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.checkbox)
                                .fill(operationColor.gradient)
                                .frame(width: geometry.size.width * progress, height: Constants.Spacing.regular)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: Constants.Spacing.regular)
                    
                    HStack {
                        Text("\(Int(progress * 100))% complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(estimatedTimeRemaining(progress: progress))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(Constants.Padding.screen)
        .background(
            RoundedRectangle(cornerRadius: Constants.Padding.screen)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: Constants.Spacing.regular, x: 0, y: Constants.Spacing.minimal)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed.toggle()
                }
            }
        }
    }
    
    private var operationIcon: some View {
        Group {
            switch operation.type {
            case .chapterDownload:
                Image(systemName: "arrow.down")
            case .metadataRefresh:
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    private var operationColor: Color {
        switch operation.type {
        case .chapterDownload:
            return .green
        case .metadataRefresh:
            return .blue
        }
    }
    
    private var operationTitle: String {
        switch operation.type {
        case .chapterDownload(let chapter):
            return "Downloading: \(chapter.toString())"
        case .metadataRefresh(let entry):
            return "Updating: \(entry.title)"
        }
    }
    
    private var operationSubtitle: String {
        switch operation.type {
        case .chapterDownload:
            return "Chapter Download"
        case .metadataRefresh:
            return "Metadata Refresh"
        }
    }
    
    private func estimatedTimeRemaining(progress: Double) -> String {
        guard progress > 0 else { return "Calculating..." }
        let remaining = Int((1.0 - progress) * 60)
        if remaining < 60 {
            return "\(remaining)s remaining"
        } else {
            return "\(remaining / 60)m remaining"
        }
    }
}

private struct PendingOperationCard: View {
    let operation: QueueOperation
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .opacity(isAnimating ? 0 : 1)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                    )
                
                Image(systemName: "clock")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .onAppear {
                isAnimating = true
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Constants.Spacing.regular) {
                    Text(operationTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    OperationTypePill(type: operation.type)
                }
                
                Text("Waiting in queue...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    operation.cancel()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(Constants.Spacing.regular)
                    .background(Circle().fill(Color(.systemGray5)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Constants.Padding.screen)
        .background(
            RoundedRectangle(cornerRadius: Constants.Padding.screen)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: Constants.Spacing.regular, x: 0, y: Constants.Spacing.minimal)
        )
    }
    
    private var operationTitle: String {
        switch operation.type {
        case .chapterDownload(let chapter):
            return chapter.toString()
        case .metadataRefresh(let entry):
            return entry.title
        }
    }
}

private struct CompletedOperationCard: View {
    let operation: QueueOperation
    @State private var showCheckmark = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "checkmark")
                    .font(.title3)
                    .foregroundColor(.green)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
            }
            .onAppear {
                showCheckmark = true
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Constants.Spacing.regular) {
                    Text(operationTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    OperationTypePill(type: operation.type)
                }
                
                Text("Completed successfully")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.primary)
        }
        .padding(Constants.Padding.screen)
        .background(
            RoundedRectangle(cornerRadius: Constants.Padding.screen)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: Constants.Spacing.regular, x: 0, y: Constants.Spacing.minimal)
        )
    }
    
    private var operationTitle: String {
        switch operation.type {
        case .chapterDownload(let chapter):
            return chapter.toString()
        case .metadataRefresh(let entry):
            return entry.title
        }
    }
}

private struct FailedOperationCard: View {
    let operation: QueueOperation
    @State private var showError = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(showError ? -5 : 5))
                        .animation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true), value: showError)
                }
                .onAppear {
                    showError = true
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: Constants.Spacing.regular) {
                        Text(operationTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        OperationTypePill(type: operation.type)
                    }
                    
                    if case .failed(let error) = operation.state {
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .lineLimit(isExpanded ? nil : 2)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(Constants.Spacing.regular)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                HStack(spacing: Constants.Spacing.large) {
                    Button {
                        // Retry action
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, Constants.Padding.screen)
                            .padding(.vertical, Constants.Spacing.regular)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        // View details action
                    } label: {
                        Label("Details", systemImage: "info.circle")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, Constants.Padding.screen)
                            .padding(.vertical, Constants.Spacing.regular)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(Constants.Padding.screen)
        .background(
            RoundedRectangle(cornerRadius: Constants.Padding.screen)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: Constants.Spacing.regular, x: 0, y: Constants.Spacing.minimal)
        )
    }
    
    private var operationTitle: String {
        switch operation.type {
        case .chapterDownload(let chapter):
            return chapter.toString()
        case .metadataRefresh(let entry):
            return entry.title
        }
    }
}

private struct OperationTypePill: View {
    let type: QueueOperationType
    
    var body: some View {
        HStack(spacing: Constants.Spacing.minimal) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, Constants.Spacing.regular)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
    
    private var icon: String {
        switch type {
        case .chapterDownload:
            return "arrow.down.circle.fill"
        case .metadataRefresh:
            return "arrow.trianglehead.2.counterclockwise.rotate.90"
        }
    }
    
    private var label: String {
        switch type {
        case .chapterDownload:
            return "CHAPTER"
        case .metadataRefresh:
            return "METADATA"
        }
    }
    
    private var color: Color {
        switch type {
        case .chapterDownload:
            return .green
        case .metadataRefresh:
            return .blue
        }
    }
}

#Preview("Queue Status View") {
    QueueStatusView()
}
