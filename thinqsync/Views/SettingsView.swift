//
//  SettingsView.swift
//  thinqsync
//
//  Settings window for API configuration
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @StateObject private var aiService = AIService.shared
    @State private var apiKeyInput: String = ""
    @State private var selectedModel: String = ""
    @State private var showingSavedConfirmation = false
    @State private var showingAPIKeyField = false
    @AppStorage("LaunchAtLogin") private var launchAtLogin = false
    @AppStorage("AlwaysOnTop") private var alwaysOnTop = false
    @AppStorage("ShowOnAllWorkspaces") private var showOnAllWorkspaces = false

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
                    // AI Configuration Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Features")
                            .font(.system(size: 16, weight: .semibold))

                        Text("ThinqSync uses OpenRouter to provide AI-powered text improvement, summarization, and more. Configure your API key below.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // API Key status and button
                        HStack(spacing: 12) {
                            Image(systemName: aiService.isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(aiService.isConfigured ? .green : .orange)
                                .font(.system(size: 16))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("OpenRouter API Key")
                                    .font(.system(size: 13, weight: .medium))
                                Text(aiService.isConfigured ? "Configured" : "Not configured")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                showingAPIKeyField.toggle()
                                if showingAPIKeyField {
                                    apiKeyInput = aiService.apiKey ?? ""
                                }
                            }) {
                                Text(aiService.isConfigured ? "Change" : "Add Key")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(16)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)

                        // API Key Input
                        if showingAPIKeyField {
                            VStack(alignment: .leading, spacing: 12) {
                                SecureField("Enter your OpenRouter API key", text: $apiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))

                                // Model selector
                                Text("Model")
                                    .font(.system(size: 13, weight: .medium))

                                Picker("Select Model", selection: $selectedModel) {
                                    ForEach(AIService.availableModels, id: \.self) { model in
                                        Text(model)
                                            .font(.system(size: 11, design: .monospaced))
                                            .tag(model)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()

                                HStack(spacing: 12) {
                                    Button("Cancel") {
                                        showingAPIKeyField = false
                                        apiKeyInput = ""
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Save") {
                                        aiService.apiKey = apiKeyInput
                                        aiService.selectedModel = selectedModel
                                        showingAPIKeyField = false
                                        apiKeyInput = ""
                                        showingSavedConfirmation = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showingSavedConfirmation = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(apiKeyInput.isEmpty)

                                    if aiService.isConfigured {
                                        Button("Remove") {
                                            aiService.clearAPIKey()
                                            showingAPIKeyField = false
                                            apiKeyInput = ""
                                        }
                                        .buttonStyle(.bordered)
                                        .foregroundColor(.red)
                                    }
                                }

                                Link(destination: URL(string: "https://openrouter.ai/keys")!) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "questionmark.circle")
                                        Text("Get your API key")
                                            .font(.system(size: 12))
                                    }
                                }

                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Free models (:free) may be rate-limited. Paid models are recommended.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
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
        .frame(width: 550, height: 600)
        .onAppear {
            apiKeyInput = aiService.apiKey ?? ""
            selectedModel = aiService.selectedModel
        }
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
