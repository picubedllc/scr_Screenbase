//
//  SettingsView.swift
//  Screenbase
//

import SwiftUI

struct SettingsView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                NavigationStack {
                    SettingsListView(viewModel: viewModel)
                        .screenTitle("Settings")
                }
            } else {
                ProgressView()
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = SettingsViewModel(subscriptionAccess: purchaseManager)
        }
    }
}

#Preview {
    let purchaseManager = PurchaseManager(service: MockPurchaseService())
    return SettingsView()
        .environment(AppState(showMainApp: true))
        .environment(PhotosManager(service: MockPhotosService(status: .authorized)))
        .environment(purchaseManager)
}
