//
//  DetailsScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI
import Kingfisher

struct DetailsScreen: View {
    @StateObject var vm: DetailsViewModel
    
    init(entry: Entry, source: Source?) {
        self._vm = StateObject(
            wrappedValue: DetailsViewModel(
                entry: entry,
                context: source
            )
        )
    }
    
    var body: some View {
        contentView
            .task { vm.loadDetails() }
            .environmentObject(vm)
            .confirmationDialog(with: $vm.confirmationRequest)
            .animation(.easeInOut, value: vm.stateIdentifier)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch vm.state {
        case .conflict(let options):
            ConflictSelectionView(options: options)
        case .empty:
            EmptyStateView()
        case .error(let error):
            ErrorView(error: error)
        case .loading:
            LoadingView()
        case .success:
            DetailContentView()
        }
    }
}

// MARK: - Conflict Selection View
extension DetailsScreen {
    @ViewBuilder
    private func ConflictSelectionView(options: [Detail]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            ContentUnavailableView {
                Label("Conflict Detected", systemImage: "arrow.triangle.2.circlepath.circle")
            } description: {
                Text("Multiple entries were found when matching by name. Please select the one you'd like to use.")
            }
            
            LazyVStack(spacing: 12) {
                ForEach(options, id: \.manga.id) { option in
                    Button {
                        vm.requestConfirmation(for: option)
                    } label: {
                        OptionRow(option: option)
                    }
                    .buttonStyle(.plain)
                    
                    if option.manga.id != options.last?.manga.id {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Empty State View
extension DetailsScreen {
    @ViewBuilder
    private func EmptyStateView() -> some View {
        ContentUnavailableView {
            Label("No Details Found", systemImage: "book.closed")
        } description: {
            Text("Could not find any details for the provided manga.")
        } actions: {
            Button("Retry") {
                vm.loadDetails()
            }
        }
    }
}

// MARK: - Error View
extension DetailsScreen {
    @ViewBuilder
    private func ErrorView(error: Error) -> some View {
        ContentUnavailableView {
            Label("An Error Occurred", systemImage: "exclamationmark.triangle.fill")
        } description: {
            VStack(spacing: 12) {
                Text("Something went wrong loading details of \(vm.entry.title)...")
                    .font(.headline)
                    .fontWeight(.regular)
                
                Text(error.localizedDescription)
                    .fontDesign(.monospaced)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        } actions: {
            Button("Retry", action: { vm.loadDetails() })
                .buttonStyle(.automatic)
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Loading View

extension DetailsScreen {
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .shimmer()
            }
            .frame(height: 45)
            .shimmer()
            
            VStack(alignment: .leading) {
                Group {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height / 6)
                        .cornerRadius(4)
                        .shimmer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .cornerRadius(4)
                        .opacity(0.6)
                        .shimmer()
                }
                .redacted(reason: .placeholder)
                
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                            .shimmer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 12)
                            .cornerRadius(2)
                            .shimmer()
                    }
                }
                .padding(.top, 8)
            }
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 1000)
        }
    }
}

// MARK: - Option Row
extension DetailsScreen {
    @ViewBuilder
    private func OptionRow(option: Detail) -> some View {
        HStack(alignment: .top) {
            GeometryReader { geometry in
                let cellWidth = geometry.size.width
                let cellHeight = cellWidth * 16 / 11
                
                KFImage(URL(string: option.covers.first(where: { $0.active })?.url ?? "" ))
                    .placeholder { Color.tint.shimmer() }
                    .resizable()
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(6)
                    .clipped()
            }
            .aspectRatio(11/16, contentMode: .fit)
            .frame(height: 150)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(option.manga.title)
                        .lineLimit(2)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if (option.manga.inLibrary) {
                        Text("In Library")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.appBlue.opacity(0.85))
                            .foregroundColor(.text.opacity(0.75))
                            .cornerRadius(15)
                    }
                }
                
                Text(option.authors.map { $0.name }.joined(separator: ", "))
                    .lineLimit(1)
                    .font(.subheadline)
                
                Text(option.manga.synopsis)
                    .lineLimit(3, reservesSpace: true)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(option.tags) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.tint)
                                .foregroundColor(.text.opacity(0.75))
                                .cornerRadius(15)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detail Content View
extension DetailsScreen {
    private struct DetailContentView: View {
        @EnvironmentObject private var vm: DetailsViewModel
        
        var body: some View {
            ZStack {
                BackdropView(cover: vm.details?.covers.first)
                
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer().frame(height: geometry.size.height / 8)
                            
                            if let details = vm.details {
                                LoadedDetails(details: details)
                            }
                            else {
                                PlaceholderView(geometry: geometry)
                            }
                        }
                        .animation(.easeInOut, value: vm.details != nil)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 12)
                        .background(BackgroundGradientView())
                    }
                    .refreshable {
                        // TODO: 
                    }
                }
                
                ContinueReadingView()
            }
        }
        
        @ViewBuilder
        private func LoadedDetails(details: Detail) -> some View {
            HeaderView()
            
            ActionButtonsView()
            
            SynopsisView(synopsis: details.manga.synopsis)
            
            TagsView(tags: details.tags)
            
            Divider()
            
            TrackingView()
            
            Divider()
            
            SourcesView()
            
            Divider()
            
            CollectionsView()
            
            Divider()
            
            MetadataView()
            
            Divider()
            
            AlternativeTitlesView()
            
            Divider()
            
            ChapterListView()
        }
    }
}

// MARK: - Confirmation Dialog Extension
extension View {
    func confirmationDialog(with request: Binding<DetailsViewModel.ConfirmationRequest?>) -> some View {
        self.alert(
            request.wrappedValue?.title ?? "Confirm",
            isPresented: .init(
                get: { request.wrappedValue != nil },
                set: { if !$0 { request.wrappedValue = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                request.wrappedValue = nil
            }
            Button("Confirm") {
                guard let viewModel = (self as? EnvironmentObject<DetailsViewModel>)?.wrappedValue else {
                    request.wrappedValue = nil
                    return
                }
                viewModel.confirmSelection()
            }
        } message: {
            Text(request.wrappedValue?.message ?? "")
        }
    }
}
