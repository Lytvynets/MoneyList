

import SwiftUI
import SwiftData
import StoreKit
import PhotosUI
import UIKit
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Environment(\.requestReview) private var requestReview
    
    @State private var showPaywall = false
    @State private var showEditProfile = false
    
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    
                    if !purchaseManager.isPro {
                        proBanner
                            .listRowBackground(FinoraColor.background)
                            .listRowInsets(EdgeInsets())
                    }
                }
                
                Section("General") {
                    NavigationLink { AccountsView() } label: { row("creditcard", "My accounts") }
                    NavigationLink { CategoriesView() } label: { row("folder", "Categories") }
                    NavigationLink { GoalsView() } label: { row("target", "Goals") }
                    NavigationLink { DefaultCurrencyView() } label: { row("dollarsign.circle", "Default currency") }
                }
                .listRowBackground(FinoraColor.surface)
                
                Section("Security & Sync") {
                    NavigationLink { FaceIDSettingsView() } label: { row("faceid", "Face ID / Sign-in protection") }
                    NavigationLink { NotificationsSettingsView() } label: { row("bell", "Notifications") }
                    NavigationLink { ICloudSyncView() } label: { row("icloud", "iCloud Sync") }
                }
                .listRowBackground(FinoraColor.surface)
                
                Section("Data") {
                    exportRow
                }
                .listRowBackground(FinoraColor.surface)
                
                Section("Support") {
                    Link(destination: URL(string: AppDefaults.supportURL)!) { row("questionmark.circle", "Help") }
                    Button { requestReview() } label: { row("star", "Leave a review") }
                }
                .listRowBackground(FinoraColor.surface)
            }
            .scrollIndicators(.hidden)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tabBarSafeArea()
            .background(FinoraColor.background)
            .navigationTitle("Profile")
            .fullScreenCover(isPresented: $showPaywall) { PaywallView(onDismiss: { showPaywall = false }) }
            .sheet(isPresented: $showEditProfile) { EditProfileView() }
        }
    }
    
    
    private var proBanner: some View {
        ZStack {
            Image("premium")
                .resizable()
                .scaledToFit()
                .onTapGesture {
                    showPaywall = true
                }
        }
    }
    
    private var exportRow: some View {
        HStack {
            row("square.and.arrow.up", "Export data")
            Spacer()
            if purchaseManager.canExport {
                ShareLink(item: exportCSV()) {
                    Image(systemName: "chevron.right").foregroundStyle(FinoraColor.textTertiary)
                }
            } else {
                Button { showPaywall = true } label: {
                    Image(systemName: "lock.fill").foregroundStyle(FinoraColor.brassGold)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func exportCSV() -> String {
        let descriptor = FetchDescriptor<Transaction>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return ExportService.csv(for: all)
    }
    
    private func row(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(FinoraColor.verdant).frame(width: 22)
            Text(title).font(FinoraFont.body).foregroundStyle(FinoraColor.textPrimary)
        }
        .padding(.vertical, 4)
    }
    
    private func initials(for name: String) -> String {
        String(name.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
    }
}


private struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var name = ""
    @State private var email = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var avatarData: Data?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            Spacer()
                            if let avatarData, let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage).resizable().scaledToFill()
                                    .frame(width: 88, height: 88).clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 64))
                            }
                            Spacer()
                        }
                    }
                }
                Section {
                    TextField("Name", text: $name)
                    TextField("Email (optional)", text: $email)
                } footer: {
                    Text("This is just a display name shown in the app — there's no login or account involved, and nothing here is sent anywhere.")
                }
            }
            .navigationTitle("Your Name & Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                name = profiles.first?.name ?? ""
                email = profiles.first?.email ?? ""
                avatarData = profiles.first?.avatarImageData
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { avatarData = try? await newItem?.loadTransferable(type: Data.self) }
            }
        }
    }
    
    private func save() {
        let profile = profiles.first ?? UserProfile()
        if profiles.isEmpty { modelContext.insert(profile) }
        profile.name = name
        profile.email = email.isEmpty ? nil : email
        profile.avatarImageData = avatarData
        try? modelContext.save()
        dismiss()
    }
}


private struct DefaultCurrencyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    var body: some View {
        List(CurrencyCode.common, id: \.self) { code in
            Button {
                profiles.first?.defaultCurrencyCode = code
                try? modelContext.save()
            } label: {
                HStack {
                    Text(code).foregroundStyle(FinoraColor.textPrimary)
                    Spacer()
                    if profiles.first?.defaultCurrencyCode == code {
                        Image(systemName: "checkmark").foregroundStyle(FinoraColor.verdant)
                    }
                }
            }
            .listRowBackground(FinoraColor.surface)
        }
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(FinoraColor.background)
        .navigationTitle("Default Currency")
    }
}


private struct FaceIDSettingsView: View {
    @EnvironmentObject private var biometricService: BiometricAuthService
    @AppStorage(AppDefaults.Keys.biometricLockEnabled) private var biometricLockEnabled = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Require \(biometricService.biometryTypeName) to open Finora", isOn: $biometricLockEnabled)
                    .disabled(!biometricService.isBiometricAvailable)
            } footer: {
                if !biometricService.isBiometricAvailable {
                    Text("No Face ID, Touch ID or passcode is set up on this device.")
                }
            }
        }
        .navigationTitle("Face ID")
    }
}


struct NotificationsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var systemStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        Form {
            Section {
                Toggle("Budget alerts", isOn: Binding(
                    get: { profiles.first?.notificationsEnabled ?? false },
                    set: { newValue in
                        profiles.first?.notificationsEnabled = newValue
                        try? modelContext.save()
                        if newValue {
                            Task {
                                await NotificationService.shared.requestAuthorizationIfNeeded()
                                await refreshStatus()
                            }
                        }
                    }
                ))
                .disabled(systemStatus == .denied)
            } footer: {
                if systemStatus == .denied {
                    Text("Notifications are off for Money List in iOS Settings — enable them there to get budget alerts.")
                } else {
                    Text("You'll get an alert the first time a category's spending crosses 80%, then again at 100% of its monthly budget.")
                }
            }
            
            if systemStatus == .denied {
                Section {
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .task { await refreshStatus() }
    }
    
    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        systemStatus = settings.authorizationStatus
    }
}


private struct ICloudSyncView: View {
    var body: some View {
        Form {
            Section {
                Label("Synced via your private iCloud", systemImage: "checkmark.icloud.fill")
                    .foregroundStyle(FinoraColor.verdant)
            } footer: {
                Text("Money List doesn't have a login screen — your data follows the Apple ID you're already signed into on this device, and never leaves your private iCloud storage.")
            }
        }
        .navigationTitle("iCloud Sync")
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Transaction.self], inMemory: true)
        .environmentObject(PurchaseManager())
        .environmentObject(BiometricAuthService())
}
