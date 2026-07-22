//
//  SignUpView.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.authService) private var authService
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthViewModel?
    
    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                Color.clear
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(authService: authService)
            }
        }
        .navigationTitle("Đăng ký")
        
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    
    @ViewBuilder
    private func content(viewModel: AuthViewModel) -> some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(spacing: Spacing.md) {
                TextField("Tên hiển thị", text: $viewModel.displayName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Email", text: $viewModel.email)
#if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
#endif
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Mật khẩu (≥8 ký tự, có chữ hoa & số)", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Xác nhận mật khẩu", text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(.red)
                }
                
                Button {
                    Task { await viewModel.signUp() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Tạo tài khoản")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || !viewModel.isSignUpFormValid)
                
                //                Text("Đã có tài khoản Apple/Google?")
                //                    .font(AppFont.caption)
                //                    .foregroundStyle(.secondary)
                //                    .multilineTextAlignment(.center)
                //                    .padding(.top, Spacing.sm)
            }
            .padding()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastCenter.show(message, type: .error)
            }
        }
        .onChange(of: viewModel.didSignUpSuccessfully) { _, success in
            if success {
                toastCenter.show("Tạo tài khoản thành công!", type: .success)
                dismiss()
            }
        }
    }
}
