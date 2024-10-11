//
//  PDFViewController.swift
//  SmartYard
//
//  Created by devcentra on 20.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController {
    
    private var pdfView = PDFView()
    
    private let pdfURL: URL!
    private let document: PDFDocument!
    
    init(pdfUrl: URL) {
        self.pdfURL = pdfUrl
        self.document = PDFDocument(url: pdfUrl)
        pdfView.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(code:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configPDFView()
        configDismiss()
    }
    
    override func viewDidLayoutSubviews() {
        pdfView.frame = view.safeAreaLayoutGuide.layoutFrame
    }
    
    private func configDismiss() {
        let dismissButton = UIButton(frame: CGRect(x: 20, y: 25, width: 40, height: 40))
        dismissButton.layer.cornerRadius = dismissButton.frame.width / 2
        dismissButton.setTitle("X", for: .normal)
        dismissButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 26)
        dismissButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        dismissButton.setTitleColor(.white, for: .normal)
        dismissButton.backgroundColor = .black
        dismissButton.alpha = 0.7
        view.addSubview(dismissButton)
        dismissButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    }
    
    @objc private func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func configPDFView() {
        view.backgroundColor = .white
        view.addSubview(pdfView)
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
    }
}
