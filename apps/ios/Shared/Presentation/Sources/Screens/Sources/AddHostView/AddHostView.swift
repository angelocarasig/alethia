//
//  AddHostView.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI
import Domain

public struct AddHostView: View {
    @State private var vm = AddHostViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var acceptedTerms = false
    @State private var acceptedContent = false
    @State private var acceptedRisk = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: dimensions.spacing.large) {
                        Header()
                        
                        if !hasAcceptedAllTerms {
                            TermsSection()
                        }
                        
                        SearchField()
                        
                        if let errorMessage = vm.errorMessage {
                            ErrorBanner(errorMessage)
                        }
                        
                        if let manifest = vm.validatedManifest {
                            SuccessContent(manifest)
                        }
                        
                        Spacer(minLength: dimensions.spacing.screen)
                    }
                    .padding(dimensions.padding.screen)
                }
                
                BottomButtons()
            }
            .navigationTitle("Add Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: dismiss.callAsFunction)
                        .foregroundColor(theme.colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ButtonModal(
                        buttonIcon: "questionmark.circle.dashed",
                        modalTitle: "About Hosts"
                    ) {
                        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
                            Text("Hosts connect Alethia to external manga sources.")
                                .font(.subheadline)
                                .foregroundColor(theme.colors.foreground)
                            
                            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                                Text("Adding a host:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.colors.foreground)
                                
                                VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                                    HStack(alignment: .top, spacing: dimensions.spacing.regular) {
                                        Text("•")
                                        Text("Enter its URL below")
                                    }
                                    
                                    HStack(alignment: .top, spacing: dimensions.spacing.regular) {
                                        Text("•")
                                        Text("Test connection")
                                    }
                                    
                                    HStack(alignment: .top, spacing: dimensions.spacing.regular) {
                                        Text("•")
                                        Text("Save")
                                    }
                                }
                                .font(.footnote)
                                .foregroundColor(theme.colors.foreground.opacity(0.8))
                            }
                            
                            HStack(alignment: .top, spacing: dimensions.spacing.regular) {
                                Text("Note:")
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.colors.appOrange)
                                
                                Text("Host content is managed by third-party providers. Alethia serves only as a reader interface.")
                                    .foregroundColor(theme.colors.foreground.opacity(0.7))
                            }
                            .font(.caption)
                            .padding(.top, dimensions.spacing.regular)
                        }
                    }
                }
            }
            .animation(theme.animations.spring, value: vm.isLoading)
            .animation(theme.animations.spring, value: vm.errorMessage != nil)
            .animation(theme.animations.spring, value: vm.validatedManifest != nil)
            .animation(theme.animations.spring, value: hasAcceptedAllTerms)
        }
    }
}

private extension AddHostView {
    @ViewBuilder
    func Header() -> some View {
        VStack(spacing: dimensions.spacing.regular) {
            Image(systemName: "server.rack")
                .font(.system(size: 44))
                .fontWeight(.light)
                .symbolRenderingMode(.hierarchical)
            
            Text("Configure external content sources that support Alethia's host format.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, dimensions.padding.screen)
    }
    
    @ViewBuilder
    func TermsSection() -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Text("Before you continue")
                .font(.headline)
                .foregroundColor(theme.colors.foreground)
            
            VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                TermsCheckbox(
                    isChecked: $acceptedTerms,
                    text: "I understand that Alethia does not host, control, or moderate any content provided by third-party hosts. The app serves only as a reader interface, and all content responsibility lies with the external host providers."
                )
                
                TermsCheckbox(
                    isChecked: $acceptedContent,
                    text: "I acknowledge that content availability, legality, and licensing varies by region and host. Some content may be geo-restricted, require authentication, or become unavailable without notice. Alethia cannot guarantee continuous access to any external content."
                )
                
                TermsCheckbox(
                    isChecked: $acceptedRisk,
                    text: "I accept full responsibility for the hosts I add and the content I access. I understand that third-party hosts may contain adult content, copyrighted material, or malicious code. I will verify the legitimacy and safety of any host before use."
                )
            }
        }
        .padding(dimensions.padding.screen)
        .background(theme.colors.accent.opacity(0.05))
        .cornerRadius(dimensions.cornerRadius.button)
    }
    
    @ViewBuilder
    func TermsCheckbox(isChecked: Binding<Bool>, text: String) -> some View {
        HStack(alignment: .top, spacing: dimensions.spacing.regular) {
            Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                .font(.body)
                .foregroundColor(theme.colors.foreground.opacity(isChecked.wrappedValue ? 1 : 0.3))
                .symbolRenderingMode(.hierarchical)
                .transition(theme.transitions.pop())
                .id(isChecked.wrappedValue)
            
            Text(text)
                .font(.footnote)
                .foregroundColor(theme.colors.foreground.opacity(0.8))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .tappable {
            isChecked.wrappedValue.toggle()
        }
        .buttonStyle(.plain)
        .animation(theme.animations.spring, value: isChecked.wrappedValue)
    }
    
    @ViewBuilder
    func SearchField() -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
            Text("Host URL")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.foreground.opacity(0.6))
            
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: "link")
                    .font(.callout)
                    .foregroundColor(theme.colors.foreground.opacity(0.4))
                
                TextField("Enter URL", text: $vm.hostURL)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .disabled(vm.isLoading || !hasAcceptedAllTerms)
                    .onChange(of: vm.hostURL) {
                        vm.clearError()
                    }
                
                if !vm.hostURL.isEmpty && !vm.isLoading && hasAcceptedAllTerms {
                    Button(action: { vm.hostURL = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                            .foregroundColor(theme.colors.foreground.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                    .fill(theme.colors.foreground.opacity(hasAcceptedAllTerms ? 0.06 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                    .strokeBorder(
                        vm.isLoading ? theme.colors.accent : Color.clear,
                        lineWidth: vm.isLoading ? 2 : 0
                    )
                    .animation(vm.isLoading ? Animation.easeInOut(duration: 1).repeatForever() : .default, value: vm.isLoading)
            )
            .opacity(hasAcceptedAllTerms ? 1 : 0.5)
            
            Text("e.g. https://api.alethia.moe")
                .font(.footnote)
                .foregroundColor(theme.colors.foreground.opacity(0.4))
        }
    }
    
    @ViewBuilder
    func ErrorBanner(_ message: String) -> some View {
        Banner(
            icon: "xmark.circle.fill",
            title: "Something Went Wrong",
            subtitle: message,
            color: theme.colors.appRed
        )
        .iconFont(.body)
        .rightContent { EmptyView() }
        .transition(.opacity)
    }
    
    @ViewBuilder
    func SuccessContent(_ manifest: HostManifest) -> some View {
        VStack(spacing: dimensions.spacing.large) {
            Banner(
                icon: "checkmark.circle.fill",
                title: "New Host!",
                subtitle: "@\(manifest.author)/\(manifest.name)".lowercased(),
                color: theme.colors.appGreen
            )
            
            SourcesList(manifest)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    func BottomButtons() -> some View {
        HStack(spacing: dimensions.spacing.regular) {
            Banner(
                icon: "bolt.circle.fill",
                title: vm.validatedManifest != nil ? "Re-Test" : "Test",
                subtitle: nil,
                color: theme.colors.appOrange,
                action: {
                    Task {
                        await vm.testConnection()
                    }
                }
            )
            .loading(vm.isLoading)
            .disabled(!canTest)
            
            Banner(
                icon: "square.and.arrow.down.fill",
                title: "Save",
                subtitle: nil,
                color: theme.colors.appBlue,
                action: {
                    Task {
                        if await vm.saveHost() {
                            dismiss()
                        }
                    }
                }
            )
            .loading(vm.isSaving)
            .disabled(vm.validatedManifest == nil)
        }
        .animation(.easeInOut(duration: 0.25), value: canTest)
        .padding(dimensions.padding.screen)
    }
    
    @ViewBuilder
    func SourcesList(_ manifest: HostManifest) -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            HStack {
                Text("AVAILABLE SOURCES")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                
                Spacer()
                
                Text("\(manifest.sources.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.accent)
                    .padding(.horizontal, dimensions.padding.regular)
                    .padding(.vertical, dimensions.padding.minimal)
                    .background(theme.colors.accent.opacity(0.1))
                    .clipShape(.capsule)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(manifest.sources.enumerated()), id: \.element.slug) { index, source in
                    SourceRow(source)
                    
                    if index < manifest.sources.count - 1 {
                        Divider()
                            .foregroundColor(theme.colors.foreground.opacity(0.1))
                    }
                }
            }
            .padding(.horizontal, dimensions.padding.screen)
            .background(theme.colors.tint)
            .cornerRadius(dimensions.cornerRadius.button)
        }
    }
    
    @ViewBuilder
    func SourceRow(_ source: SourceManifest) -> some View {
        HStack(spacing: dimensions.spacing.large) {
            AsyncImage(url: source.icon) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                        .fill(theme.colors.foreground.opacity(0.05))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(theme.colors.foreground.opacity(0.2))
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                        .fill(theme.colors.foreground.opacity(0.05))
                        .overlay {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(theme.colors.foreground.opacity(0.2))
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: dimensions.icon.regular.width, height: dimensions.icon.regular.height)
            .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular))
            
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                // title
                Text(source.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // auth type
                HStack {
                    Image(systemName: "key.fill")
                    Text(source.auth.type.displayText)
                        .fontWeight(.semibold)
                }
                .font(.caption2)
                .padding(.horizontal, dimensions.padding.regular)
                .padding(.vertical, dimensions.padding.minimal)
                .background(theme.colors.appOrange.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .strokeBorder(theme.colors.appOrange.opacity(0.3), lineWidth: 1.5)
                )
                .cornerRadius(dimensions.cornerRadius.card)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "hexagon")
                    .font(.caption)
                Text("^[\(source.presets.count) Preset](inflect: true)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, dimensions.padding.regular)
            .background(theme.colors.appGreen.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                    .strokeBorder(theme.colors.appGreen.opacity(0.3), lineWidth: 1.5)
            )
            .cornerRadius(dimensions.cornerRadius.card)
            
            if source.nsfw {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                    Text("NSFW")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, dimensions.padding.regular)
                .padding(.vertical, dimensions.padding.regular)
                .background(theme.colors.appRed.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .strokeBorder(theme.colors.appRed.opacity(0.3), lineWidth: 1.5)
                )
                .cornerRadius(dimensions.cornerRadius.card)
            }
        }
        .padding(.vertical, dimensions.padding.regular)
    }
    
    var canTest: Bool {
        hasAcceptedAllTerms && !vm.hostURL.isEmpty && !vm.isLoading
    }
    
    var hasAcceptedAllTerms: Bool {
        acceptedTerms && acceptedContent && acceptedRisk
    }
}
