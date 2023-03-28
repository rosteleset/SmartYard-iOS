//
//  ChatwootViewController.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD
//import MessageKit

//struct Sender: SenderType {
//    var senderId: String
//    var displayName: String
//}
//
//struct Message: MessageType {
//    var sender: SenderType
//    var messageId: String
//    var sentDate: Date
//    var kind: MessageKind
//}
//
//struct Media: MediaItem {
//    var url: URL?
//    var image: UIImage?
//    var placeholderImage: UIImage
//    var size: CGSize
//}

class ChatwootViewController: BaseViewController {
//class ChatwootViewController: MessagesViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
//    var fakeNavBar: FakeNavBar = FakeNavBar()
//    @IBOutlet private weak var myButton: BlueButton!
    
//    let disposeBag = DisposeBag()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

//    let currentUser = Sender(senderId: "self", displayName: "Я")
//
//    let answerUser = Sender(senderId: "other", displayName: "Техподдержка")
//
//    var messages = [Message]()
    
    private let viewModel: ChatwootViewModel

    var loader: JGProgressHUD?

    init(viewModel: ChatwootViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fakeNavBar.translatesAutoresizingMaskIntoConstraints = false

        let topFakeNavBar = fakeNavBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 44)
        topFakeNavBar.isActive = true

        fakeNavBar.configueDarkNavBar()
        
        configureView()
        bind()
    }
    
    private func configureView() {
        
//        messagesCollectionView.messagesDataSource = self
//        messagesCollectionView.messagesLayoutDelegate = self
//        messagesCollectionView.messagesDisplayDelegate = self
//
//        messageInputBar.sendButton
//            .configure {
//                $0.setSize(CGSize(width: 90, height: 36), animated: false)
//                $0.isEnabled = false
//                $0.title = "Отправить"
//                $0.backgroundColor = UIColor(white: 0.9, alpha: 1)
//                $0.layerCornerRadius = 8
//                $0.tintColor = UIColor.blue
//                $0.setTitleColor(UIColor.SmartYard.blue, for: .normal)
//                $0.setTitleColor(UIColor(white: 0.8, alpha: 1), for: .disabled)
//                $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
//            }.onTouchUpInside {
//                $0.inputBarAccessoryView?.didSelectSendButton()
//            }
//        messageInputBar.setRightStackViewWidthConstant(to: 90, animated: false)
//
//        messageInputBar.inputTextView.placeholder = "Ваше сообщение..."
//
//        messagesCollectionView.contentInset.top = 44
        
//        fakeNavBar.isHidden = false
        
    }
    
    private func bind() {
        
        let input = ChatwootViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
//        messages.append(Message(sender: currentUser,
//                                messageId: "1",
//                                sentDate: Date().addingTimeInterval(-10000),
//                                kind: .text("Привет!!!")))
//
//        messages.append(Message(sender: answerUser,
//                                messageId: "2",
//                                sentDate: Date().addingTimeInterval(-9000),
//                                kind: .text("И вам доброго здоровья. И вам доброго здоровья. И вам доброго здоровья. ")))

    }
    
}

//extension ChatwootViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
//    func currentSender() -> SenderType {
//        return currentUser
//    }
//
//    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        return messages[indexPath.section]
//    }
//
//    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
//        return messages.count
//    }
//
//    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
//
//        avatarView.initials = message.sender.displayName.first?.description ?? "?"
//    }
//
//    func setupConstraints() {
//        messagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
//
//        let top = messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor)
//        let bottom = messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        let leading = messagesCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
//        let trailing = messagesCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
//        NSLayoutConstraint.activate([top, bottom, trailing, leading])
//    }
//
//}
