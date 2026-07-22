//
//  LoginView.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.authService) private var authService
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: AuthViewModel?
    @State private var showSignUp = false
    
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
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView()
        }
    }
    
    @ViewBuilder
    private func content(viewModel: AuthViewModel) -> some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.xs) {
                    Text("QuickChat")
                        .font(AppFont.title)
                    Text("Đăng nhập để tiếp tục")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.xl)
                
                VStack(spacing: Spacing.sm) {
                    TextField("Email", text: $viewModel.email)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
#endif
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Mật khẩu", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(.red)
                }
                
                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Đăng nhập")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || !viewModel.isLoginFormValid)
                
                socialDivider
                
                // Nút chuẩn Apple — tự quản lý luồng ASAuthorizationController,
                // ViewModel chỉ chuẩn bị request (nonce) và nhận kết quả.
                SignInWithAppleButton(.signIn) { request in
                    viewModel.prepareAppleSignInRequest(request)
                } onCompletion: { result in
                    Task { await viewModel.handleAppleSignInCompletion(result)}
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: 375)
                .frame(height: 44)
                .disabled(viewModel.isLoading)
                
#if os(iOS)
                Button {
                    Task { await viewModel.signInWithGoole() }
                } label: {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Đăng nhập với Google")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
#endif
                
                Button("Chưa có tài khoản? Đăng ký") {
                    showSignUp = true
                }
                .buttonStyle(.bordered)
                .padding(.top, Spacing.sm)
            }
            .padding()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                 toastCenter.show(message, type: .error)
             }
        }
    }
    
    private var socialDivider: some View {
        HStack {
            VStack { Divider() }
            Text("hoặc")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            VStack { Divider() }
        }
    }
}
