import SwiftUI
import SwiftData

@main
struct EpiLoggApp: App {
    private let storeError: String?
    private let container: ModelContainer?

    init() {
        do {
            let openedContainer = try LocalStore.makeContainer()
            container = openedContainer
            storeError = nil
        } catch {
            container = nil
            storeError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    RootView()
                        .modelContainer(container)
                } else {
                    StoreFailureView(message: storeError ?? "Lokal lagring kunne ikke åpnes.")
                }
            }
            .tint(AppStyle.accent)
            .environment(\.locale, Locale(identifier: "nb_NO"))
            .preferredColorScheme(.light)
        }
    }
}

struct StoreFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(AppStyle.accent)
            Text("Kunne ikke åpne loggen")
                .font(.title2.bold())
                .foregroundStyle(AppStyle.ink)
            Text(message)
                .foregroundStyle(AppStyle.muted)
                .multilineTextAlignment(.center)
            Text("Dataene er ikke slettet. Start appen på nytt, eller ta vare på denne feilmeldingen.")
                .font(.footnote)
                .foregroundStyle(AppStyle.muted)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.canvas)
    }
}

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if !profiles.contains(where: \.onboardingCompleted) {
                OnboardingView(onFinished: {})
            } else {
                MainTabs()
            }
        }
    }
}
