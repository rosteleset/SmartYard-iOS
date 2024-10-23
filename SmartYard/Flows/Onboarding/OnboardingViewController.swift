//
//  OnboardingViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 21.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class OnboardingViewController: BaseViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var pageControl: UIPageControl!
    
    @IBOutlet fileprivate weak var skipButton: UIButton!
    @IBOutlet fileprivate weak var nextButton: WhiteButtonWithBorder!
    @IBOutlet fileprivate weak var letsStartButton: BlueButton!
    
    private let viewModel: OnboardingViewModel
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePageControl()
        scrollView.delegate = self
        letsStartButton.isHidden = true
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupScreens()
    }
    
    private func bind() {
        nextButton.rx
            .tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let oldFrame = self.scrollView.frame
                    let nextPage = Int(self.scrollView.contentOffset.x / oldFrame.size.width) + 1
                
                    var newFrame = oldFrame
                    newFrame.origin.x = newFrame.size.width * CGFloat(nextPage)
                    
                    self.scrollView.scrollRectToVisible(newFrame, animated: true)
                }
            )
            .disposed(by: disposeBag)
        
        let input = OnboardingViewModel.Input(
            skipTapped: skipButton.rx.tap.asDriver(),
            letsStartTapped: letsStartButton.rx.tap.asDriver()
        )
        
        _ = viewModel.transform(input: input)
    }
    
    private func configurePageControl() {
        pageControl.numberOfPages = OnboardingPage.allCases.count
        pageControl.currentPageIndicatorTintColor = UIColor.SmartYard.blue
        pageControl.pageIndicatorTintColor = UIColor.SmartYard.gray.withAlphaComponent(0.2)
    }
    
    private func setupScreens() {
        var scrollFrame = CGRect.zero
        
        scrollView.removeSubviews()
        
        OnboardingPage.allCases.enumerated().forEach { offset, element in
            scrollFrame.origin.x = scrollView.frame.size.width * CGFloat(offset)
            scrollFrame.size = CGSize(width: scrollView.width, height: scrollView.height)
            
            guard let view = UIView.loadFromNib(named: "OnboardingBaseView") as? OnboardingBaseView else {
                return
            }
            
            view.frame = scrollFrame
            view.configure(with: element)
            
            scrollView.addSubview(view)
        }
        
        scrollView.contentSize = CGSize(
            width: scrollView.frame.size.width * CGFloat(OnboardingPage.allCases.count),
            height: scrollView.frame.size.height
        )
    }
    
    fileprivate func configureControls(with page: Int) {
        pageControl.currentPage = page
        
        let isLastPage = page == OnboardingPage.allCases.count - 1
        nextButton.isHidden = isLastPage
        skipButton.isHidden = isLastPage
        letsStartButton.isHidden = !isLastPage
    }
    
}

extension OnboardingViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        configureControls(with: Int((scrollView.contentOffset.x / scrollView.frame.size.width).rounded()))
    }

}
