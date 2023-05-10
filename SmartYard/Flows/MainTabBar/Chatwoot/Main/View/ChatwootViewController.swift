//
//  ChatwootViewController.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity closure_body_length line_length file_length

import UIKit
import RxSwift
import RxCocoa
import JGProgressHUD
import MessageKit
import InputBarAccessoryView
import Photos

class ChatwootViewController: MessagesViewController, LoaderPresentable {
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    private var NBView: UIView?
    private var currentUser = SenderDataItem(id: 0, name: "")
    private var refreshControl = UIRefreshControl()

    let disposeBag = DisposeBag()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private var messages = [MessageDataItem]()
    private let viewModel: ChatwootViewModel

    private var isSendingPhoto = false {
        didSet {
            messageInputBar.leftStackViewItems.forEach { item in
                guard let item = item as? InputBarButtonItem else {
                    return
                }
                item.isEnabled = !self.isSendingPhoto
            }
            
        }
    }
    private var isFullscreenImage = false
    private var isTypingActive = true
    
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

        configureView()
        bind()
    }
    
    private func configureView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self

        self.showMessageTimestampOnSwipeLeft = false // swipe left to show time activate
                
        let nbview = UIView()
        
        view.addSubview(nbview)
        
        nbview.frame = CGRect(x: 0, y: 0, width: view.width + 20, height: 88)
        nbview.backgroundColor = .white
        nbview.insertSubview(fakeNavBar, at: 0)
        self.NBView = nbview
        fakeNavBar.translatesAutoresizingMaskIntoConstraints = false

        let topFakeNavBar = fakeNavBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 44)
        topFakeNavBar.isActive = true
        fakeNavBar.backgroundColor = UIColor(white: 1, alpha: 1.0)

        fakeNavBar.configueDarkNavBar()

        messageInputBar.sendButton
            .configure {
                $0.setSize(CGSize(width: 90, height: 36), animated: false)
                $0.isEnabled = false
                $0.title = "Отправить"
                $0.backgroundColor = UIColor(white: 0.9, alpha: 1)
                $0.layerCornerRadius = 8
                $0.tintColor = UIColor.blue
                $0.setTitleColor(UIColor.SmartYard.blue, for: .normal)
                $0.setTitleColor(UIColor(white: 0.8, alpha: 1), for: .disabled)
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            }
            .onTouchUpInside {
                $0.inputBarAccessoryView?.didSelectSendButton()
            }
        messageInputBar.setRightStackViewWidthConstant(to: 90, animated: false)
        messageInputBar.inputTextView.placeholder = "Ваше сообщение..."
        messagesCollectionView.contentInset.top = 44
        addAttachmentBarButton()
        messagesCollectionView.refreshControl = refreshControl
        
        currentUser = SenderDataItem(
            id: 0,
            name: viewModel.getAccessService().clientName!.name
        )

    }
    
    private func bind() {
        
        let input = ChatwootViewModel.Input(
            isViewVisible: rx.isVisible.asDriver(onErrorJustReturn: false),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            )
            .disposed(by: disposeBag)
        
        output.messages
            .drive(
                onNext: { messageModels in
                    self.messages.removeAll { message in
                        if let messageId = message.messageId.int,
                           messageId < 0 {
                            if self.isSendingPhoto, messageId < -1 {
                                return true
                            } else if !self.isSendingPhoto {
                                return true
                            }
                        }
                        return false
                    }
                    var answerUser = SenderDataItem(id: -1, name: "")
                    
                    for message in messageModels {
                        if let ismessage = self.messages.enumerated().first(where: { $0.element.messageId == String(message.id) }) {
                            continue
                        }
                        
                        let dtmessage = self.messages.enumerated().first(where: { $0.element.sentDate > message.createdAt })
                        
                        let messageSender = SenderDataItem(
                            id: message.sender.id,
                            name: message.sender.name
                        )

                        if let phoneNumber = message.sender.phoneNumber,
                           let userPhoneNumber = self.viewModel.getAccessService().clientPhoneNumber,
                            "+7" + userPhoneNumber == phoneNumber {
                            self.currentUser = messageSender
                        } else {
                            answerUser = messageSender
                        }
                        
                        if let content = message.content {
                            let messageItem = MessageDataItem(
                                sender: messageSender,
                                messageId: String(message.id),
                                sentDate: message.createdAt,
                                kind: .text(content)
                            )
                            if dtmessage == nil {
                                self.messages.append(messageItem)
                            } else {
                                self.messages.insert(messageItem, at: dtmessage!.offset)
                            }
                        }
                        if !message.attachments.isEmpty {
                            for attachment in message.attachments {
                                
                                switch attachment.fileType {
                                case "image":
                                    let fotoKind = MediaDataItem(
                                        imageurl: attachment.dataUrl,
                                        placeholderurl: attachment.thumbUrl!
                                    )
                                    let messageItem = MessageDataItem(
                                        sender: messageSender,
                                        messageId: String(message.id),
                                        sentDate: message.createdAt,
                                        kind: .photo(fotoKind)
                                    )
                                    if dtmessage == nil {
                                        self.messages.append(messageItem)
                                    } else {
                                        self.messages.insert(messageItem, at: dtmessage!.offset)
                                    }
                                case "audio":
                                    let audioKind = AudioDataItem(audiourl: attachment.dataUrl)
                                    let messageItem = MessageDataItem(
                                        sender: messageSender,
                                        messageId: String(message.id),
                                        sentDate: message.createdAt,
                                        kind: .audio(audioKind)
                                    )
                                    if dtmessage == nil {
                                        self.messages.append(messageItem)
                                    } else {
                                        self.messages.insert(messageItem, at: dtmessage!.offset)
                                    }
                                default: break
                                }
                            }
                        }
                    }
                    
                    self.messagesCollectionView.reloadData()
                    if self.viewModel.isScrollable() {
                        self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                    }
                    // TODO: Тут включаем индикацию ввода текста
//                    if self.isTypingActive {
//                        DispatchQueue.main.async {
//                            self.setTypingIndicatorViewHidden(false, animated: true)
//                        }
//                    }
                    
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.view.endEditing(true)
                    }
                    
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }
}

extension ChatwootViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc private func attachButtonTaped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            picker.sourceType = .camera
//        } else {
            picker.sourceType = .photoLibrary
//        }
        
        present(picker, animated: true)
    }
    
    private func addAttachmentBarButton() {
        let attachButton = InputBarButtonItem(type: .system)
        attachButton.tintColor = .darkGray
        if #available(iOS 13.0, *) {
            attachButton.image = UIImage(systemName: "photo")
        } else {
            attachButton.image = UIImage(named: "Photo")
        }
        
        attachButton.addTarget(
            self,
            action: #selector(attachButtonTaped),
            for: .primaryActionTriggered
        )
        
        attachButton.setSize(CGSize(width: 60, height: 30), animated: false)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        
        messageInputBar.setStackViewItems([attachButton], forStack: .left, animated: false)
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize = widthRatio > heightRatio ?
        CGSize(width: size.width * heightRatio, height: size.height * heightRatio) :
        CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func sendPhoto(_ image: UIImage) {
        
        guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MyTmpFile.jpg") else {
            return
        }
        isSendingPhoto = true
        let tmpImage = resizeImage(image: image, targetSize: CGSize(width: 250, height: 250))
        
        let jpegData = tmpImage?.jpegData(compressionQuality: 0.6)
        do {
            try jpegData?.write(to: imageURL)
            let messageItem = MessageDataItem(
                sender: currentUser,
                messageId: "-1",
                sentDate: Date(),
                kind: .photo(MediaDataItem(
                    imageurl: imageURL.absoluteString,
                    placeholderurl: imageURL.absoluteString
                ))
            )
            messages.append(messageItem)
            messagesCollectionView.reloadData()
            if viewModel.isScrollable() {
                messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
            }
        } catch {}
        
        DispatchQueue.main.async {
            self.viewModel.sendMessage(image: image, text: nil)
            self.isSendingPhoto = false
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        if let asset = info[.phAsset] as? PHAsset {
            let size = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFit,
                options: nil) { result, _ in
                    guard let image = result else {
                        return
                    }
                    self.sendPhoto(image)
            }
            
        } else if let image = info[.originalImage] as? UIImage {
            sendPhoto(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension ChatwootViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        let messageItem = MessageDataItem(
            sender: currentUser,
            messageId: "-10",
            sentDate: Date(),
            kind: .text(text)
        )
        messages.append(messageItem)
        messagesCollectionView.reloadData()
        if viewModel.isScrollable() {
            messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        }
        DispatchQueue.main.async {
            self.viewModel.sendMessage(image: nil, text: text)
        }
        
        inputBar.inputTextView.text = ""
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        return
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        return
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {
        return
    }

}

extension Date {
    
    func isInSameDayOf(date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    func wasYesterday() -> Bool {
        return Calendar.current.isDateInYesterday(self)
    }
}

extension ChatwootViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
        
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            return
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        switch message.kind {
        case .photo(let photoItem):
            if let img = photoItem.url,
               let imageview = (cell as? MediaMessageCell)?.imageView {
                self.imageTaped(imageURL: img, position: imageview.superview?.convert(imageview.frame, to: nil))
            }
        default: break
        }
    }

    func imageTaped(imageURL: URL, position: CGRect?) {

        let fullscreenVc = FullscreenImageViewController(position: position)
        
        fullscreenVc.modalPresentationStyle = .overFullScreen
        fullscreenVc.modalTransitionStyle = .crossDissolve

        fullscreenVc.setImageLayer(imageURL)

        self.present(fullscreenVc, animated: true)
        
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.fakeNavBar.isHidden = false
        messageInputBar.isHidden = false
        self.isFullscreenImage = false
        sender.view?.removeFromSuperview()
    }
    
    func messageTimestampLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let messageDate = message.sentDate
        let timeFormatter = DateFormatter()
        
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: messageDate)
        
        return NSAttributedString(string: timeString, attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let messageDate = message.sentDate
        let timeFormatter = DateFormatter()
        
        timeFormatter.dateFormat = "HH:mm"
//        timeFormatter.dateFormat = "dd.MM HH:mm"
        let timeString = timeFormatter.string(from: messageDate)
        
        return NSAttributedString(string: timeString, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.darkGray])
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        let size = CGFloat(36)
        
        if indexPath.section == 0 {
            return size
        }

        let lastIndexPath = IndexPath(row: 0, section: indexPath.section - 1)
        let lastMessage = messageForItem(at: lastIndexPath, in: messagesCollectionView)

        if message.sentDate.isInSameDayOf(date: lastMessage.sentDate) {
            return .zero
        }

        return size
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        let size = CGFloat(16)
        
        return size
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isNextMessageSameSender(at: indexPath) ? 0 : 10
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        var name = dateFormatter.string(from: message.sentDate)

        if message.sentDate.isToday() {
            name = "Сегодня"
        } else if message.sentDate.wasYesterday() {
            name = "Вчера"
        }
//        let cellshadow = NSShadow()
//        cellshadow.shadowBlurRadius = 3
//        cellshadow.shadowColor = UIColor.gray
//        cellshadow.shadowOffset = CGSize(width: 2, height: 2)
        let attributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
            NSAttributedString.Key.foregroundColor: UIColor.darkGray
//            NSAttributedString.Key.shadow: cellshadow
        ]
        return NSAttributedString(string: name, attributes: attributes)
    }
    
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        if message.sender.senderId == currentUser.senderId {
            avatarView.initials = message.sender.displayName.first?.description ?? "?"
        } else {
            let avatar = Avatar(image: UIImage(named: "ChatwootAvatar"), initials: "")
            avatarView.set(avatar: avatar)
        }
        avatarView.isHidden = isNextMessageSameSender(at: indexPath)
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else {
            return false
        }
        
        if messages[indexPath.section].sentDate.isInSameDayOf(date: messages[indexPath.section + 1].sentDate) {
            return messages[indexPath.section].sender.displayName == messages[indexPath.section + 1].sender.displayName
        }
        
        return false
    }

    func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor.SmartYard.blue
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        switch message.kind {
        case .photo:
            return .white
        case .audio:
            return .white
        default: break
        }

        return isFromCurrentSender(message: message) ? .lightGray : UIColor.SmartYard.blue
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .white
    }
    
}
