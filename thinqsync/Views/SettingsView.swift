//
//  SettingsView.swift
//  thinqsync
//
//  Settings window for API configuration
//

import SwiftUI
import ServiceManagement

enum AIProvider: String, CaseIterable, Identifiable {
    case openRouter = "OpenRouter (Deepseek)"
    case openAI = "OpenAI"
    case anthropic = "Anthropic Claude"
    case googleGemini = "Google Gemini"

    var id: String { rawValue }

    var helpURL: String {
        switch self {
        case .openRouter:
            return "https://openrouter.ai/keys"
        case .openAI:
            return "https://platform.openai.com/api-keys"
        case .anthropic:
            return "https://console.anthropic.com/settings/keys"
        case .googleGemini:
            return "https://aistudio.google.com/app/apikey"
        }
    }

    var keychainKey: String {
        switch self {
        case .openRouter:
            return "DeepseekAPIKey"
        case .openAI:
            return "OpenAIAPIKey"
        case .anthropic:
            return "AnthropicAPIKey"
        case .googleGemini:
            return "GoogleGeminiAPIKey"
        }
    }
}

struct SettingsView: View {
    @AppStorage("AIProvider") private var selectedProvider: String = AIProvider.openRouter.rawValue
    @State private var apiKeys: [AIProvider: String] = [:]
    @State private var showingAPIKeyField: AIProvider?
    @State private var tempAPIKey: String = ""
    @State private var showingSavedConfirmation = false
    @AppStorage("LaunchAtLogin") private var launchAtLogin = false
    @AppStorage("AlwaysOnTop") private var alwaysOnTop = false
    @AppStorage("ShowOnAllWorkspaces") private var showOnAllWorkspaces = false

    var currentProvider: AIProvider {
        AIProvider.allCases.first { $0.rawValue == selectedProvider } ?? .openRouter
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
            }
            .padding(24)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // AI Provider Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Provider")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Choose your preferred AI provider for text improvement, summarization, and other AI features.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(AIProvider.allCases) { provider in
                                Text(provider.rawValue).tag(provider.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Divider()

                    // AI API Keys Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("API Keys")
                            .font(.system(size: 16, weight: .semibold))

                        ForEach(AIProvider.allCases) { provider in
                            VStack(alignment: .leading, spacing: 12) {
                                // Provider Header
                                HStack(spacing: 12) {
                                    Image(systemName: hasAPIKey(for: provider) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(hasAPIKey(for: provider) ? .green : .orange)
                                        .font(.system(size: 16))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(provider.rawValue)
                                            .font(.system(size: 13, weight: .medium))

                                        if provider == currentProvider {
                                            Text("Currently selected")
                                                .font(.system(size: 11))
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        if showingAPIKeyField == provider {
                                            showingAPIKeyField = nil
                                        } else {
                                            showingAPIKeyField = provider
                                            tempAPIKey = apiKeys[provider] ?? ""
                                        }
                                    }) {
                                        Text(hasAPIKey(for: provider) ? "Change" : "Add Key")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(16)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(8)

                                // API Key Input Field
                                if showingAPIKeyField == provider {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("\(provider.rawValue) API Key")
                                            .font(.system(size: 13, weight: .medium))

                                        SecureField("Enter your API key", text: $tempAPIKey)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))

                                        HStack(spacing: 12) {
                                            Button("Cancel") {
                                                showingAPIKeyField = nil
                                                tempAPIKey = ""
                                            }
                                            .buttonStyle(.bordered)

                                            Button("Save") {
                                                saveAPIKey(for: provider)
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .disabled(tempAPIKey.isEmpty)

                                            if hasAPIKey(for: provider) {
                                                Button("Remove") {
                                                    removeAPIKey(for: provider)
                                                }
                                                .buttonStyle(.bordered)
                                                .foregroundColor(.red)
                                            }
                                        }

                                        // Help Link
                                        Link(destination: URL(string: provider.helpURL)!) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "questionmark.circle")
                                                Text("Get your API key")
                                                    .font(.system(size: 12))
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }

                        if showingSavedConfirmation {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API Key saved successfully")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // General Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("General")
                            .font(.system(size: 16, weight: .semibold))

                        Toggle(isOn: $launchAtLogin) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Launch at Login")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Automatically start ThinqSync when you log in")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: launchAtLogin) { oldValue, newValue in
                            setLaunchAtLogin(enabled: newValue)
                        }
                        .padding(16)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)

                        Toggle(isOn: $alwaysOnTop) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Always on Top")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Keep notes floating above other windows")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)

                        Toggle(isOn: $showOnAllWorkspaces) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show on All Workspaces")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Notes follow you across all desktop spaces")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    Divider()

                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.system(size: 16, weight: .semibold))

                        HStack {
                            Text("ThinqSync")
                                .font(.system(size: 13))
                            Spacer()
                            Text("Version 1.0")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Text("A powerful menubar sticky notes app with AI-powered features and iCloud sync.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 550, height: 650)
        .onAppear {
            loadAPIKeys()
        }
    }

    private func hasAPIKey(for provider: AIProvider) -> Bool {
        guard let key = apiKeys[provider] else { return false }
        return !key.isEmpty
    }

    private func loadAPIKeys() {
        for provider in AIProvider.allCases {
            // Migrate any keys still in UserDefaults to Keychain
            KeychainHelper.migrateFromUserDefaults(userDefaultsKey: provider.keychainKey, keychainKey: provider.keychainKey)
            if let key = KeychainHelper.load(key: provider.keychainKey) {
                apiKeys[provider] = key
            }
        }
    }

    private func saveAPIKey(for provider: AIProvider) {
        _ = KeychainHelper.save(key: provider.keychainKey, value: tempAPIKey)
        apiKeys[provider] = tempAPIKey
        showingAPIKeyField = nil
        tempAPIKey = ""
        showingSavedConfirmation = true

        // Hide confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSavedConfirmation = false
        }
    }

    private func removeAPIKey(for provider: AIProvider) {
        KeychainHelper.delete(key: provider.keychainKey)
        apiKeys[provider] = nil
        showingAPIKeyField = nil
        tempAPIKey = ""
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}

#Preview {
    SettingsView()
}
