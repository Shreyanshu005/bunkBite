import SwiftUI
import Combine

struct VersionCheckView: View {
    let currentVersion: String
    let minimumVersion: String
    let appStoreURL: String

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Constants.primaryColor)

                Text("Update Required")
                    .font(.custom("Urbanist-Bold", size: 28))
                    .foregroundStyle(.black)

                Text("A new version of BunkBite is available. Please update to continue using the app.")
                    .font(.custom("Urbanist-Medium", size: 16))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(spacing: 8) {
                    HStack {
                        Text("Current Version:")
                            .font(.custom("Urbanist-Medium", size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                        Text(currentVersion)
                            .font(.custom("Urbanist-Bold", size: 14))
                            .foregroundStyle(.black)
                    }

                    HStack {
                        Text("Required Version:")
                            .font(.custom("Urbanist-Medium", size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                        Text(minimumVersion)
                            .font(.custom("Urbanist-Bold", size: 14))
                            .foregroundStyle(Constants.primaryColor)
                    }
                }
                .padding(.top, 8)

                Spacer()

                Button {
                    if let url = URL(string: appStoreURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Update Now")
                        .font(.custom("Urbanist-Bold", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Constants.primaryColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

class VersionManager: ObservableObject {
    @Published var needsUpdate = false
    @Published var minimumVersion = ""

    private let apiService = APIService.shared

    func checkVersion() async {
        do {

            guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                print("❌ Could not get current app version")
                return
            }

            print("📱 Current app version: \(currentVersion)")

            minimumVersion = try await apiService.getMinimumVersion()

            print("🔄 Minimum required version: \(minimumVersion)")

            if compareVersions(current: currentVersion, minimum: minimumVersion) {
                print("✅ App version is up to date")
                needsUpdate = false
            } else {
                print("⚠️ App needs update")
                needsUpdate = true
            }
        } catch {
            print("❌ Error checking version: \(error)")

            needsUpdate = false
        }
    }

    private func compareVersions(current: String, minimum: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let minimumComponents = minimum.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(currentComponents.count, minimumComponents.count) {
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            let minimumValue = i < minimumComponents.count ? minimumComponents[i] : 0

            if currentValue < minimumValue {
                return false
            } else if currentValue > minimumValue {
                return true
            }
        }

        return true
    }
}
