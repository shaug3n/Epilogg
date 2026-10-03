import SwiftUI

struct MainTabs: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Oversikt", systemImage: "chart.xyaxis.line")
            }
            LogListView()
                .tabItem {
                    Label("Logg", systemImage: "list.bullet.rectangle.portrait")
                }
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
        }
        .environment(\.locale, Locale(identifier: "nb_NO"))
        .tint(AppStyle.accent)
    }
}
