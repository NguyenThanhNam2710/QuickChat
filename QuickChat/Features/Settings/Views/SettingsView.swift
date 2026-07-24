//
//  SettingsView.swift
//  QuickChat
//
//  Created by NamNT97 on 24/7/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable private var localizationManager = LocalizationManager.shared

    var body: some View {
        Form {
            Section {
                Picker(L10n.Settings.languagePickerLabel, selection: $localizationManager.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text(L10n.Settings.languageSectionHeader)
            } footer: {
                Text(L10n.Settings.languageFooter)
            }
        }
        .navigationTitle(L10n.Settings.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
