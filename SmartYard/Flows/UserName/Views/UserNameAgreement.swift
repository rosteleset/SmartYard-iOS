//
//  UserNameAgreement.swift
//  SmartYard
//
//  Created by Александр Попов on 26.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI
import SwifterSwift
import UIKit

struct UserNameAgreementText: UIViewRepresentable {
    let caption: NSAttributedString
    let openLink: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(openLink: openLink)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.tintColor = UserNameAgreement.linkColor
        view.linkTextAttributes = [
            .foregroundColor: UserNameAgreement.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: UserNameAgreement.linkColor
        ]
        view.delegate = context.coordinator
        view.attributedText = caption
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.openLink = openLink
        if view.attributedText?.isEqual(to: caption) != true {
            view.attributedText = caption
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var openLink: (URL) -> Void

        init(openLink: @escaping (URL) -> Void) {
            self.openLink = openLink
        }

        func textView(
            _ textView: UITextView,
            shouldInteractWith url: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            openLink(url)
            return false
        }
    }
}

@MainActor
enum UserNameAgreement {
    static let linkColor = UIColor.SmartYard.blue

    static func caption(serverHTML: String?) -> NSAttributedString? {
        let bundledHTML = NSLocalizedString(
            "auth.userName.agreement.html",
            comment: "Optional HTML for the agreement caption"
        ).trimmed
        if let html = serverHTML ?? (bundledHTML.isEmpty ? nil : bundledHTML) {
            return makeAgreementText(html: html)
        }

        return makeAgreementLinks().map { makeAgreementText(links: $0) }
    }

    private static func makeAgreementText(html: String) -> NSAttributedString? {
        guard !html.trimmed.isEmpty else { return nil }

        let font = UIFont.SourceSansPro.regular(size: 14)
        let document = """
        <head>
          <meta charset="utf-8">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'">
        </head>
        <body style="font-family: '\(font.familyName)'; font-size: \(font.pointSize)px">
        \(html)
        </body>
        """
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let parsed = try? NSAttributedString(
            data: Data(document.utf8),
            options: options,
            documentAttributes: nil
        ) else { return nil }

        let visibleText = parsed.string.trimmed
        guard !visibleText.isEmpty, let range = parsed.string.range(of: visibleText) else { return nil }

        let caption = NSMutableAttributedString(
            attributedString: parsed.attributedSubstring(from: NSRange(range, in: parsed.string))
        )
        let fullRange = NSRange(location: 0, length: caption.length)
        caption.addAttribute(.foregroundColor, value: UIColor.SmartYard.semiBlack, range: fullRange)
        caption.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            guard let value else { return }
            let url = value as? URL
            if ["http", "https"].contains(url?.scheme?.lowercased() ?? ""), url?.host?.isEmpty == false {
                return
            }
            caption.removeAttribute(.link, range: range)
            caption.removeAttribute(.underlineStyle, range: range)
        }
        return caption
    }

    private static func makeAgreementLinks() -> [(substring: String, url: URL)]? {
        let documents: [(key: String, urlString: String?)] = [
            ("auth.userName.agreement.personalDataLinkText", Constants.personalDataProcessingAgreementURL),
            ("auth.userName.agreement.privacyPolicyLinkText", Constants.privacyPolicyURL),
            ("auth.userName.agreement.userAgreementLinkText", Constants.userAgreementURL)
        ]
        let links = documents.compactMap { document -> (substring: String, url: URL)? in
            guard
                let urlString = document.urlString?.trimmed,
                !urlString.isEmpty,
                let url = URL(string: urlString)
            else {
                return nil
            }

            return (NSLocalizedString(document.key, comment: ""), url)
        }

        return links.isEmpty ? nil : links
    }

    private static func makeAgreementText(links: [(substring: String, url: URL)]) -> NSAttributedString {
        let listFormatter = ListFormatter()
        listFormatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ru")
        let linkTexts = links.map(\.substring)
        let text = String(
            format: NSLocalizedString("auth.userName.agreement.text", comment: ""),
            listFormatter.string(from: linkTexts) ?? linkTexts.joined(separator: ", ")
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineSpacing = 2
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.SourceSansPro.regular(size: 14),
                .foregroundColor: UIColor.SmartYard.semiBlack,
                .paragraphStyle: paragraphStyle
            ]
        )

        links.forEach { substring, url in
            guard let range = text.range(of: substring) else {
                return
            }

            attributedString.addAttributes(
                [
                    .link: url,
                    .foregroundColor: linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: linkColor
                ],
                range: NSRange(range, in: text)
            )
        }

        return attributedString
    }
}
