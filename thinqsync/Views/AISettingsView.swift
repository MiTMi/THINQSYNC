//
//  AISettingsView.swift
//  thinqsync
//
//  Created by Claude on 04/11/2025.
//

import SwiftUI

struct AISettingsView: View {
    @StateObject private var aiService = DeepseekAIService.shared
    @State private var apiKeyInput: String = ""
    @State private var selectedModel: String = ""
    @State private var showingSaved = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "brain")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                Text("AI Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 20)

            // Divider
            Divider()

            // API Key Section
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenRouter API Key")
                    .font(.headline)

                Text("Enter your OpenRouter API key to enable AI features. Using Deepseek models.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("Get your API key at")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("openrouter.ai/keys")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Free models (:free) may be rate-limited. Paid models are recommended.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                SecureField("API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))

                Text("Model")
                    .font(.subheadline)
                    .padding(.top, 8)

                Picker("Select Model", selection: $selectedModel) {
                    ForEach(DeepseekAIService.availableModels, id: \.self) { model in
                        Text(model)
                            .font(.system(size: 11, design: .monospaced))
                            .tag(model)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Text("Try different models if one doesn't work")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button("Save") {
                        aiService.apiKey = apiKeyInput
                        aiService.selectedModel = selectedModel
                        showingSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingSaved = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKeyInput.isEmpty)

                    if aiService.isConfigured {
                        Button("Clear") {
                            apiKeyInput = ""
                            selectedModel = DeepseekAIService.availableModels[0]
                            aiService.clearAPIKey()
                        }
                        .buttonStyle(.bordered)
                    }

                    if showingSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(aiService.isConfigured ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(aiService.isConfigured ? "AI features enabled" : "AI features disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            // Features Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Available AI Features")
                    .font(.headline)
                    .padding(.bottom, 4)

                FeatureRow(icon: "wand.and.stars", title: "Improve Writing", description: "Enhance clarity and style")
                FeatureRow(icon: "doc.text.magnifyingglass", title: "Summarize", description: "Create concise summaries")
                FeatureRow(icon: "arrow.up.left.and.arrow.down.right", title: "Expand", description: "Add detail and context")
                FeatureRow(icon: "checkmark.seal", title: "Fix Grammar", description: "Correct errors")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            // Help text
            Text("Use slash commands (/) in any note to access AI features")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Close button
            Button("Done") {
                closeWindow()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 20)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 450, height: 580)
        .onAppear {
            apiKeyInput = aiService.apiKey ?? ""
            selectedModel = aiService.selectedModel
        }
    }

    private func closeWindow() {
        // Close the current window
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AISettingsView()
}
