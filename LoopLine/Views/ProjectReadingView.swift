import SwiftData
import SwiftUI

struct ProjectReadingView: View {
    @Query private var settings: [AppSettings]
    @Bindable var project: Project

    private var usesLargeControls: Bool {
        settings.first?.largeControls ?? true
    }

    var body: some View {
        VStack(spacing: 0) {
            ReadingTrackingControls(project: project, usesLargeControls: usesLargeControls)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

            sourceContent
        }
        .background(LoopLineTheme.readingBackground.ignoresSafeArea())
        .navigationTitle("Reading Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LoopLineTheme.readingBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private var sourceContent: some View {
        switch project.sourceType {
        case .pdf:
            PDFReadingView(project: project)
        case .image:
            ImageReadingView(project: project)
        case .text:
            ReadingModeView(project: project)
        }
    }
}
