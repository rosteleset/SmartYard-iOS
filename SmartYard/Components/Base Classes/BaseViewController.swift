//
//  BaseViewController.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift //
import RxCocoa //
import RxRelay //
import RxDataSources // Diffabale

class BaseViewController: UIViewController, HasDisposeBag {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    func someFunction() {
        let button = UIButton()

        let observable = Observable.just(1)

        let publishSubject = PublishSubject<[Int]>()
        let behaviorSubject = BehaviorSubject<[Int]>(value: [1])

        behaviorSubject
            .distinctUntilChanged()
            .filter { array in
                array[0] % 2 == 0
            }
            .mapToVoid()
            .subscribe {

            }
            .disposed(by: disposeBag)

        behaviorSubject.onNext([0])
        behaviorSubject.onNext([0])

        behaviorSubject.onNext([2, 3])
        behaviorSubject.onNext([5, 3])



        behaviorSubject
            .subscribe { number in
                print(number)
            }
            .disposed(by: disposeBag)

        observable
            .subscribe { number in
                print(number)
            }
            .disposed(by: disposeBag)

        observable
            .subscribe { number in
                print(number)
            }
            .disposed(by: disposeBag)

        observable
            .subscribe { number in
                print(number)
            }
            .disposed(by: disposeBag)

    }

}
