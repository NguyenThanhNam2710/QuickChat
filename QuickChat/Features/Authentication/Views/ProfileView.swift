//
//  ProfileView.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.authService) private var authService
    @Environment(\.userService) private var userService
    @Environment(ToastCenter.self) private var toastCenter
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(authService: authService, userService: userService)
            }
        }
        .navigationTitle(L10n.Profile.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    @ViewBuilder
    private func content(viewModel: ProfileViewModel) -> some View {
        @Bindable var viewModel = viewModel

        Form {
            Section(L10n.Profile.accountSectionHeader) {
                LabeledContent(L10n.Common.email, value: viewModel.email)
            }

            Section(L10n.Profile.displayNameSectionHeader) {
                TextField(L10n.Profile.displayNameSectionHeader, text: $viewModel.displayName)
                if let nameErrorMessage = viewModel.nameErrorMessage {
                    Text(nameErrorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(.red)
                }
                Button {
                    Task { await viewModel.saveDisplayName() }
                } label: {
                    if viewModel.isSavingName {
                        ProgressView()
                    } else {
                        Text(L10n.Profile.saveNameButton)
                    }
                }
                .disabled(viewModel.isSavingName || !viewModel.isNameValid)
            }

            if viewModel.canChangePassword {
                Section(L10n.Profile.changePasswordSectionHeader) {
                    SecureField(L10n.Profile.currentPasswordPlaceholder, text: $viewModel.currentPassword)
                    SecureField(L10n.Profile.newPasswordPlaceholder, text: $viewModel.newPassword)
                    SecureField(L10n.Profile.confirmNewPasswordPlaceholder, text: $viewModel.confirmNewPassword)

                    if let passwordErrorMessage = viewModel.passwordErrorMessage {
                        Text(passwordErrorMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await viewModel.savePassword() }
                    } label: {
                        if viewModel.isSavingPassword {
                            ProgressView()
                        } else {
                            Text(L10n.Profile.changePasswordSectionHeader)
                        }
                    }
                    .disabled(viewModel.isSavingPassword || !viewModel.isPasswordFormValid)
                }
            } else {
                Section {
                    Text(L10n.Profile.noPasswordNote)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(L10n.Profile.settingsSectionHeader) {
                NavigationLink(L10n.Profile.settingsLink) {
                    SettingsView()
                }
            }
        }
        .onChange(of: viewModel.didUpdateName) { _, success in
            if success { toastCenter.show(L10n.Profile.nameUpdatedToast, type: .success) }
        }
        .onChange(of: viewModel.didUpdatePassword) { _, success in
            if success { toastCenter.show(L10n.Profile.passwordUpdatedToast, type: .success) }
        }
    }
}
