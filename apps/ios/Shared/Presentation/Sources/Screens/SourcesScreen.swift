//
//  SourcesScreen.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI
import Domain

public struct SourcesScreen: View {
    @State private var vm = SourcesViewModel()
    @State private var showingAddSourceSheet = false
    @State private var searchText = ""
    @State private var selectedHost: Host? = nil
    @State private var collapsedSections: Set<String> = ["disabled"]  // Only disabled is collapsed by default
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: dimensions.spacing.regular) {
                if !vm.isEmpty || !vm.isLoading {
                    searchSection
                }
                
                if !vm.hosts.isEmpty {
                    filterBar
                    Divider()
                }
                
                mainContent
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, dimensions.padding.screen)
            .animation(theme.animations.spring, value: vm.isLoading)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2), value: searchText)
            .navigationTitle("Sources")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSourceSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSourceSheet) {
                AddHostView()
            }
            .onAppear {
                vm.startObserving()
            }
            .onDisappear {
                vm.stopObserving()
            }
        }
    }
}

// MARK: - Main Content Views
private extension SourcesScreen {
    
    @ViewBuilder
    var mainContent: some View {
        if vm.isLoading {
            Spinner(prompt: "Loading your sources...", size: .large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if displayedSources.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "No sources configured" : "No matches found",
                systemImage: searchText.isEmpty ? "books.vertical" : "magnifyingglass",
                description: Text(searchText.isEmpty ? "Add a host to start browsing from various sources" : "Try different keywords or check your filter settings")
            )
        } else {
            sourcesList
        }
    }
    
    var searchSection: some View {
        VStack {
            Searchbar(searchText: $searchText)
            
            if !searchText.isEmpty {
                NavigationLink {
                    Text("TODO: Search Screen")
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.subheadline)
                        Text("Search sources for '\(searchText)'?")
                            .font(.subheadline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(dimensions.padding.screen)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(.rect(cornerRadius: 10))
                }
                .transition(theme.transitions.slide(.top))
            }
        }
    }
    
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: dimensions.spacing.regular) {
                FilterChip(
                    title: "All",
                    isSelected: selectedHost == nil
                ) {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.2)) {
                        selectedHost = nil
                    }
                }
                
                ForEach(vm.hosts, id: \.id) { host in
                    FilterChip(
                        title: host.displayName,
                        isSelected: selectedHost?.id == host.id
                    ) {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.2)) {
                            selectedHost = host
                        }
                    }
                }
            }
            .padding(.vertical, dimensions.padding.regular)
        }
    }
    
    var sourcesList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: dimensions.spacing.large) {
                let sources = displayedSources
                let pinned = sources.filter { $0.pinned && !$0.disabled }
                let disabled = sources.filter { $0.disabled }
                let regular = sources.filter { !$0.pinned && !$0.disabled }
                
                // pinned section
                if !pinned.isEmpty {
                    ExpandableSection(
                        title: "Pinned",
                        isExpanded: isSectionExpanded("pinned")
                    ) {
                        toggleSection("pinned")
                    } content: {
                        ForEach(pinned, id: \.id) { source in
                            SourceRow(source: source)
                        }
                    }
                }
                
                // regular sources
                if selectedHost == nil {
                    regularSourcesByHost(regular)
                } else {
                    ForEach(regular, id: \.id) { source in
                        SourceRow(source: source)
                    }
                }
                
                // disabled section
                if !disabled.isEmpty {
                    ExpandableSection(
                        title: "Disabled",
                        count: disabled.count,
                        isExpanded: isSectionExpanded("disabled")
                    ) {
                        toggleSection("disabled")
                    } content: {
                        ForEach(disabled, id: \.id) { source in
                            SourceRow(source: source)
                        }
                    }
                }
            }
            .padding(.bottom, dimensions.padding.screen)
        }
    }
    
    @ViewBuilder
    func regularSourcesByHost(_ regular: [Source]) -> some View {
        let grouped = Dictionary(grouping: regular, by: \.host)
        ForEach(vm.hosts, id: \.id) { host in
            if let hostSources = grouped[host.displayName], !hostSources.isEmpty {
                let sectionKey = "host-\(host.id)"
                
                ExpandableSection(
                    title: host.displayName,
                    count: hostSources.count,
                    isExpanded: isSectionExpanded(sectionKey)
                ) {
                    toggleSection(sectionKey)
                } content: {
                    ForEach(hostSources, id: \.id) { source in
                        SourceRow(source: source)
                    }
                }
            }
        }
    }
    
    var displayedSources: [Source] {
        vm.sources(for: selectedHost?.id, matching: searchText)
    }
    
    func toggleSection(_ key: String) {
        withAnimation(theme.animations.spring) {
            if collapsedSections.contains(key) {
                collapsedSections.remove(key)
            } else {
                collapsedSections.insert(key)
            }
        }
    }
    
    func isSectionExpanded(_ key: String) -> Bool {
        !collapsedSections.contains(key)
    }
}

// MARK: - Reusable Components
private extension SourcesScreen {
    
    struct FilterChip: View {
        @Environment(\.dimensions) private var dimensions
        @Environment(\.theme) private var theme
        
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? theme.colors.background : theme.colors.foreground)
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.spacing.large)
                .background(isSelected ? theme.colors.foreground : theme.colors.tint)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button, style: .continuous))
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .tappable(action: action)
        }
    }
    
    struct ExpandableSection<Content: View>: View {
        @Environment(\.dimensions) private var dimensions
        @Environment(\.theme) private var theme
        
        let title: String
        var count: Int? = nil
        let isExpanded: Bool
        let toggle: () -> Void
        @ViewBuilder let content: () -> Content
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let count = count {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.foreground.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.foreground.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.vertical, dimensions.padding.regular)
                .contentShape(.rect)
                .tappable(action: toggle)
                
                if isExpanded {
                    VStack(spacing: 0) {
                        content()
                    }
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
                }
            }
        }
    }
    
    struct SourceRow: View {
        @Environment(\.dimensions) private var dimensions
        @Environment(\.theme) private var theme
        
        let source: Source
        
        var body: some View {
            NavigationLink {
                Text(source.name)  // placeholder detail view
            } label: {
                HStack(spacing: dimensions.spacing.large) {
                    SourceIcon(url: source.icon.absoluteString, isDisabled: source.disabled)
                    
                    sourceInfo
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.colors.foreground.opacity(0.3))
                }
                .padding(.vertical, dimensions.padding.regular)
            }
            .disabled(source.disabled)
        }
        
        var sourceInfo: some View {
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                HStack(spacing: dimensions.spacing.regular) {
                    Text(source.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.foreground)
                        .lineLimit(1)
                        .opacity(source.disabled ? 0.5 : 1.0)
                    
                    if source.disabled {
                        disabledBadge
                    }
                }
                
                Text(source.host)
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                    .lineLimit(1)
            }
        }
        
        var disabledBadge: some View {
            Text("DISABLED")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.alert)
                .padding(.horizontal, dimensions.padding.regular)
                .padding(.vertical, dimensions.padding.minimal)
                .background(theme.colors.alert.opacity(0.15))
                .clipShape(.capsule)
        }
    }
}
