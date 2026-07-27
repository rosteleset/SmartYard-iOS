//
//  L10n+Generated.swift
//  SmartYard
//
//  Generated from Localizable.strings.
//

import Foundation

// swiftlint:disable file_length type_body_length nesting
extension L10n {
    enum Address {
        enum Confirmation {
            static let subtitle = tr("address.confirmation.subtitle")
            static let title = tr("address.confirmation.title")

            enum Courier {
                static let activationHint = tr("address.confirmation.courier.activationHint")
                static let envelopeHint = tr("address.confirmation.courier.envelopeHint")
                static let hintFormat = tr("address.confirmation.courier.hintFormat")
                static let leaveARequest = tr("address.confirmation.courier.leaveARequest")
                static let qrCodeHint = tr("address.confirmation.courier.qrCodeHint")
                static let requestButton = tr("address.confirmation.courier.requestButton")
                static let scanTheQrCode = tr("address.confirmation.courier.scanTheQrCode")
                static let use = tr("address.confirmation.courier.use")
            }

            enum Delivery {
                static let courierChangeMessage = tr("address.confirmation.delivery.courierChangeMessage")
                static let courierOption = tr("address.confirmation.delivery.courierOption")
                static let courierShort = tr("address.confirmation.delivery.courierShort")
                static let courierTitle = tr("address.confirmation.delivery.courierTitle")
                static let officeChangeMessage = tr("address.confirmation.delivery.officeChangeMessage")
                static let officeOption = tr("address.confirmation.delivery.officeOption")
                static let officeShort = tr("address.confirmation.delivery.officeShort")
                static let pickupTitle = tr("address.confirmation.delivery.pickupTitle")
            }

            enum Office {
                static let hint = tr("address.confirmation.office.hint")
                static let iLlDoSoButton = tr("address.confirmation.office.iLlDoSoButton")
                static let instructions = tr("address.confirmation.office.instructions")
            }
        }

        enum Entry {
            static let checkAvailableServicesButton = tr("address.entry.checkAvailableServicesButton")
            static let iHaveQrCodeButton = tr("address.entry.iHaveQrCodeButton")
            static let title = tr("address.entry.title")
        }

        enum Form {
            static let apartment = tr("address.form.apartment")
            static let apartmentValue = tr("address.form.apartmentValue")
            static let building = tr("address.form.building")
            static let city = tr("address.form.city")
            static let street = tr("address.form.street")
        }

        enum QRCode {
            static let loginRequiredMessage = tr("address.qrCode.loginRequiredMessage")
        }

        enum QRScan {
            static let pointYourCameraAtTheQrCode = tr("address.qrScan.pointYourCameraAtTheQrCode")
        }
    }

    enum App {
        enum Update {
            static let action = tr("app.update.action")
            static let availableTitle = tr("app.update.availableTitle")
            static let requiredMessage = tr("app.update.requiredMessage")
            static let requiredTitle = tr("app.update.requiredTitle")
        }
    }

    enum Auth {
        enum CallVerification {
            static let callButton = tr("auth.callVerification.callButton")
            static let callInstructionPrefix = tr("auth.callVerification.callInstructionPrefix")
            static let callInstructionSuffix = tr("auth.callVerification.callInstructionSuffix")
            static let confirmPhoneTitle = tr("auth.callVerification.confirmPhoneTitle")
            static let confirmPhoneTitleFormat = tr("auth.callVerification.confirmPhoneTitleFormat")
            static let editPhoneButton = tr("auth.callVerification.editPhoneButton")
            static let phoneNumberPlaceholder = tr("auth.callVerification.phoneNumberPlaceholder")
        }

        enum CodeRateLimit {
            static let message = tr("auth.codeRateLimit.message")
        }

        enum ContractLogin {
            static let contractNumberPlaceholder = tr("auth.contractLogin.contractNumberPlaceholder")
            static let createButton = tr("auth.contractLogin.createButton")
            static let forgotCredentialsButton = tr("auth.contractLogin.forgotCredentialsButton")
            static let forgotPasswordButton = tr("auth.contractLogin.forgotPasswordButton")
            static let hasOperatorAgreementTitle = tr("auth.contractLogin.hasOperatorAgreementTitle")
            static let iDonTHaveAContractButton = tr("auth.contractLogin.iDonTHaveAContractButton")
            static let loginButton = tr("auth.contractLogin.loginButton")
            static let passwordPlaceholder = tr("auth.contractLogin.passwordPlaceholder")
            static let restoreByContractPrompt = tr("auth.contractLogin.restoreByContractPrompt")
            static let subtitle = tr("auth.contractLogin.subtitle")
        }

        enum FlashCall {
            static let enterLastDigitsTitleFormat = tr("auth.flashCall.enterLastDigitsTitleFormat")
        }

        enum PasswordRecovery {
            static let chooseMethodButton = tr("auth.passwordRecovery.chooseMethodButton")
            static let codeSentMessage = tr("auth.passwordRecovery.codeSentMessage")
            static let contractPlaceholder = tr("auth.passwordRecovery.contractPlaceholder")
            static let restoreAccess = tr("auth.passwordRecovery.restoreAccess")
            static let sendCodeButton = tr("auth.passwordRecovery.sendCodeButton")
            static let subtitle = tr("auth.passwordRecovery.subtitle")

            enum Code {
                static let resendButton = tr("auth.passwordRecovery.code.resendButton")
                static let resendHint = tr("auth.passwordRecovery.code.resendHint")
                static let sentToPhoneTitle = tr("auth.passwordRecovery.code.sentToPhoneTitle")
                static let timerValue = tr("auth.passwordRecovery.code.timerValue")
            }

            enum Error {
                static let invalidContract = tr("auth.passwordRecovery.error.invalidContract")
            }

            enum Method {
                static let email = tr("auth.passwordRecovery.method.email")
                static let maskedContactPlaceholder = tr("auth.passwordRecovery.method.maskedContactPlaceholder")
                static let phone = tr("auth.passwordRecovery.method.phone")
                static let sendCodePrefix = tr("auth.passwordRecovery.method.sendCodePrefix")
                static let titlePrefix = tr("auth.passwordRecovery.method.titlePrefix")
            }
        }

        enum PhoneEntry {
            static let changeProviderButton = tr("auth.phoneEntry.changeProviderButton")
            static let providerName = tr("auth.phoneEntry.providerName")
            static let title = tr("auth.phoneEntry.title")

            enum Error {
                static let confirmationNumberMissing = tr("auth.phoneEntry.error.confirmationNumberMissing")
            }
        }

        enum Pin {
            static let invalidCode = tr("auth.pin.invalidCode")
        }

        enum ProviderSelection {
            static let chooseAProvider = tr("auth.providerSelection.chooseAProvider")
            static let searchPlaceholder = tr("auth.providerSelection.searchPlaceholder")
            static let subtitle = tr("auth.providerSelection.subtitle")

            enum Error {
                static let loadFailed = tr("auth.providerSelection.error.loadFailed")
            }

            enum Method {
                static let maskedContactPlaceholder = tr("auth.providerSelection.method.maskedContactPlaceholder")
            }
        }

        enum SMSCode {
            static let resendHint = tr("auth.smsCode.resendHint")
            static let sentToPhoneTitle = tr("auth.smsCode.sentToPhoneTitle")
            static let sentToPhoneTitleFormat = tr("auth.smsCode.sentToPhoneTitleFormat")
            static let timerValue = tr("auth.smsCode.timerValue")
        }

        enum UserName {
            static let howCanICallYou = tr("auth.userName.howCanICallYou")
        }
    }

    enum Camera {
        enum Archive {
            static let title = tr("camera.archive.title")

            enum Export {
                static let linkCopiedMessage = tr("camera.archive.export.linkCopiedMessage")
                static let processingMessage = tr("camera.archive.export.processingMessage")
                static let processingTitle = tr("camera.archive.export.processingTitle")
                static let successTitle = tr("camera.archive.export.successTitle")
            }
        }

        enum ArchivePlayer {
            static let downloadAndGetLinkButton = tr("camera.archivePlayer.downloadAndGetLinkButton")
            static let halfSpeedButton = tr("camera.archivePlayer.halfSpeedButton")
            static let oneAndHalfSpeedButton = tr("camera.archivePlayer.oneAndHalfSpeedButton")
            static let selectFragmentButton = tr("camera.archivePlayer.selectFragmentButton")
            static let videoDated = tr("camera.archivePlayer.videoDated")
        }

        enum City {
            static let incidentsTitle = tr("camera.city.incidentsTitle")
            static let mapTitle = tr("camera.city.mapTitle")
            static let publicCamerasTitle = tr("camera.city.publicCamerasTitle")
            static let requestRecordButton = tr("camera.city.requestRecordButton")

            enum Detail {
                static let addressPlaceholder = tr("camera.city.detail.addressPlaceholder")
                static let title = tr("camera.city.detail.title")
            }
        }

        enum Online {
            static let title = tr("camera.online.title")
        }

        enum RecordRequest {
            static let commentPlaceholder = tr("camera.recordRequest.commentPlaceholder")
            static let dateLabel = tr("camera.recordRequest.dateLabel")
            static let datePlaceholder = tr("camera.recordRequest.datePlaceholder")
            static let durationHint = tr("camera.recordRequest.durationHint")
            static let durationLabel = tr("camera.recordRequest.durationLabel")
            static let durationPlaceholder = tr("camera.recordRequest.durationPlaceholder")
            static let processingHint = tr("camera.recordRequest.processingHint")
            static let sendRequestButton = tr("camera.recordRequest.sendRequestButton")
            static let submittedMessage = tr("camera.recordRequest.submittedMessage")
            static let timeHoursPlaceholder = tr("camera.recordRequest.timeHoursPlaceholder")
            static let timeLabel = tr("camera.recordRequest.timeLabel")
            static let timeMinutesPlaceholder = tr("camera.recordRequest.timeMinutesPlaceholder")
        }

        enum Selection {
            static let title = tr("camera.selection.title")
        }
    }

    enum Chat {
        enum Error {
            static let unableToOpenPage = tr("chat.error.unableToOpenPage")
        }
    }

    enum Common {
        static let add = tr("common.add")
        static let all = tr("common.all")
        static let allow = tr("common.allow")
        static let back = tr("common.back")
        static let cancel = tr("common.cancel")
        static let delete = tr("common.delete")
        static let deny = tr("common.deny")
        static let edit = tr("common.edit")
        static let disable = tr("common.disable")
        static let done = tr("common.done")
        static let enable = tr("common.enable")
        static let error = tr("common.error")
        static let ignore = tr("common.ignore")
        static let next = tr("common.next")
        static let no = tr("common.no")
        static let ok = tr("common.ok")
        static let `open` = tr("common.open")
        static let opened = tr("common.opened")
        static let reset = tr("common.reset")
        static let resetDone = tr("common.resetDone")
        static let save = tr("common.save")
        static let search = tr("common.search")
        static let settings = tr("common.settings")
        static let share = tr("common.share")
        static let yes = tr("common.yes")

        enum Confirmation {
            static let title = tr("common.confirmation.title")
        }

        enum Time {
            static let hoursShort = tr("common.time.hoursShort")
            static let minutes = tr("common.time.minutes")
            static let minutesShort = tr("common.time.minutesShort")
            static let secondsShort = tr("common.time.secondsShort")
        }

        enum Weekday {
            enum Short {
                static let fri = tr("common.weekday.short.fri")
                static let mon = tr("common.weekday.short.mon")
                static let sat = tr("common.weekday.short.sat")
                static let sun = tr("common.weekday.short.sun")
                static let thu = tr("common.weekday.short.thu")
                static let tue = tr("common.weekday.short.tue")
                static let wed = tr("common.weekday.short.wed")
            }
        }
    }

    enum Error {
        enum Address {
            static let houseIdMissing = tr("error.address.houseIdMissing")
        }

        enum App {
            static let restoreStateFailed = tr("error.app.restoreStateFailed")
        }

        enum Auth {
            static let accessTokenMissing = tr("error.auth.accessTokenMissing")
            static let clientIdMissing = tr("error.auth.clientIdMissing")
            static let contractNumberNotFound = tr("error.auth.contractNumberNotFound")
            static let currentUserPhoneMissing = tr("error.auth.currentUserPhoneMissing")
            static let userAlreadyLoggedIn = tr("error.auth.userAlreadyLoggedIn")
        }

        enum Camera {
            static let setupFailed = tr("error.camera.setupFailed")
        }

        enum Common {
            static let unknown = tr("error.common.unknown")
        }

        enum Internal {
            static let selfDestroyed = tr("error.internal.selfDestroyed")
        }

        enum Network {
            static let baseModelParsingFailed = tr("error.network.baseModelParsingFailed")
            static let dataFieldMappingFailed = tr("error.network.dataFieldMappingFailed")
            static let internetRequiredToChangeUser = tr("error.network.internetRequiredToChangeUser")
            static let noConnection = tr("error.network.noConnection")
        }

        enum Notifications {
            static let appDisabled = tr("error.notifications.appDisabled")
            static let fcmTokenMissing = tr("error.notifications.fcmTokenMissing")
            static let instanceIdMissing = tr("error.notifications.instanceIdMissing")
            static let systemDisabled = tr("error.notifications.systemDisabled")
        }

        enum Permissions {
            static let cameraDenied = tr("error.permissions.cameraDenied")
            static let contactsDenied = tr("error.permissions.contactsDenied")
        }

        enum Request {
            static let executionFailed = tr("error.request.executionFailed")
        }
    }

    enum FaceRecognition {
        enum AddFace {
            static let addThisFace = tr("faceRecognition.addFace.addThisFace")
        }

        enum DeleteFace {
            static let deleteThisFace = tr("faceRecognition.deleteFace.deleteThisFace")
        }
    }

    enum History {
        static let title = tr("history.title")

        enum Detail {
            static let emptyStateMessage = tr("history.detail.emptyStateMessage")
            static let title = tr("history.detail.title")
        }

        enum Event {
            static let answeredCall = tr("history.event.answeredCall")
            static let gateOpeningByNumberplate = tr("history.event.gateOpeningByNumberplate")
            static let gateOpeningOnCall = tr("history.event.gateOpeningOnCall")
            static let guestAllowedHint = tr("history.event.guestAllowedHint")
            static let guestDeniedHint = tr("history.event.guestDeniedHint")
            static let imageMissing = tr("history.event.imageMissing")
            static let missedCall = tr("history.event.missedCall")
            static let openingFromApp = tr("history.event.openingFromApp")
            static let openingWithCode = tr("history.event.openingWithCode")
            static let openingWithFaceID = tr("history.event.openingWithFaceID")
            static let openingWithKey = tr("history.event.openingWithKey")
            static let unknown = tr("history.event.unknown")
        }

        enum EventTracking {
            static let toggleTitle = tr("history.eventTracking.toggleTitle")

            enum Comment {
                static let placeholderFormat = tr("history.eventTracking.comment.placeholderFormat")
                static let title = tr("history.eventTracking.comment.title")
            }
        }

        enum Filter {
            static let allApartments = tr("history.filter.allApartments")
            static let allButton = tr("history.filter.allButton")
            static let allInApartment = tr("history.filter.allInApartment")
            static let allOption = tr("history.filter.allOption")
            static let apptAllButton = tr("history.filter.apptAllButton")
            static let faceID = tr("history.filter.faceID")
            static let intercom = tr("history.filter.intercom")
            static let key = tr("history.filter.key")
            static let openingByApp = tr("history.filter.openingByApp")
            static let openingByCode = tr("history.filter.openingByCode")
            static let openingOnCall = tr("history.filter.openingOnCall")
        }

        enum VideoEventInfo {
            static let description = tr("history.videoEventInfo.description")
            static let forwardGestureHint = tr("history.videoEventInfo.forwardGestureHint")
            static let gesturesTitle = tr("history.videoEventInfo.gesturesTitle")
            static let rewindGestureHint = tr("history.videoEventInfo.rewindGestureHint")
            static let swipeGestureHint = tr("history.videoEventInfo.swipeGestureHint")
            static let title = tr("history.videoEventInfo.title")
        }
    }

    enum Home {
        enum AddressCard {
            enum Cameras {
                static let cameras = tr("home.addressCard.cameras.cameras")
                static let countValue = tr("home.addressCard.cameras.countValue")
            }

            enum Events {
                static let countValue = tr("home.addressCard.events.countValue")
                static let events = tr("home.addressCard.events.events")
            }
        }

        enum Addresses {
            static let title = tr("home.addresses.title")
        }

        enum AddressesEmpty {
            static let listIsEmpty = tr("home.addressesEmpty.listIsEmpty")
            static let offlineTitle = tr("home.addressesEmpty.offlineTitle")
            static let onlineTitle = tr("home.addressesEmpty.onlineTitle")
            static let toAddAnAddressTapAtTheTop = tr("home.addressesEmpty.toAddAnAddressTapAtTheTop")
        }
    }

    enum Intercom {
        enum Incoming {
            static let addressPlaceholder = tr("intercom.incoming.addressPlaceholder")
            static let answerAction = tr("intercom.incoming.answerAction")
            static let callCompletedStatus = tr("intercom.incoming.callCompletedStatus")
            static let connectingStatus = tr("intercom.incoming.connectingStatus")
            static let conversationStatus = tr("intercom.incoming.conversationStatus")
            static let declineAction = tr("intercom.incoming.declineAction")
            static let ignoreAction = tr("intercom.incoming.ignoreAction")
            static let microphoneMissingMessage = tr("intercom.incoming.microphoneMissingMessage")
            static let microphoneMissingTitle = tr("intercom.incoming.microphoneMissingTitle")
            static let notificationTitle = tr("intercom.incoming.notificationTitle")
            static let openedStatus = tr("intercom.incoming.openedStatus")
            static let peepholeAction = tr("intercom.incoming.peepholeAction")
            static let peepholeOnStatus = tr("intercom.incoming.peepholeOnStatus")
            static let previewAction = tr("intercom.incoming.previewAction")
            static let speakerAction = tr("intercom.incoming.speakerAction")
            static let title = tr("intercom.incoming.title")
            static let videoAction = tr("intercom.incoming.videoAction")
        }
    }

    enum LicensePlate {
        enum Keyboard {
            enum Language {
                static let russian = tr("licensePlate.keyboard.language.russian")
            }
        }
    }

    enum Menu {
        enum Main {
            static let menu = tr("menu.main.menu")
        }

        enum Support {
            static let callToTechSupport = tr("menu.support.callToTechSupport")
        }
    }

    enum Network {
        enum VPN {
            static let detectedWarning = tr("network.vpn.detectedWarning")
        }
    }

    enum Notification {
        enum IncomingDoorCall {
            static let quickReplyHint = tr("notification.incomingDoorCall.quickReplyHint")
            static let title = tr("notification.incomingDoorCall.title")
        }
    }

    enum Offline {
        enum Alert {
            static let noConnectionTitle = tr("offline.alert.noConnectionTitle")
            static let switchMode = tr("offline.alert.switchMode")
        }

        enum Hint {
            static let swipeToExit = tr("offline.hint.swipeToExit")
        }

        enum Home {
            static let title = tr("offline.home.title")
        }

        enum Message {
            static let connectionLost = tr("offline.message.connectionLost")
            static let connectionRestored = tr("offline.message.connectionRestored")
            static let serverUnavailable = tr("offline.message.serverUnavailable")
        }
    }

    enum Onboarding {
        static let coolLetSGetStartedButton = tr("onboarding.coolLetSGetStartedButton")
        static let skipButton = tr("onboarding.skipButton")

        enum Awareness {
            static let title = tr("onboarding.awareness.title")
        }

        enum Control {
            static let title = tr("onboarding.control.title")
        }

        enum Intercom {
            static let subtitle = tr("onboarding.intercom.subtitle")
        }

        enum Services {
            static let subtitle = tr("onboarding.services.subtitle")
        }

        enum Slide {
            static let videoSurveillance = tr("onboarding.slide.videoSurveillance")

            enum Awareness {
                static let subtitle = tr("onboarding.slide.awareness.subtitle")
            }
        }

        enum SmartYard {
            static let title = tr("onboarding.smartYard.title")
        }
    }

    enum Payments {
        enum AddressSelection {
            static let selectAddress = tr("payments.addressSelection.selectAddress")
        }

        enum Error {
            static let unableToOpenPage = tr("payments.error.unableToOpenPage")
        }

        enum TopUp {
            static let amount = tr("payments.topUp.amount")
            static let amountPlaceholder = tr("payments.topUp.amountPlaceholder")
            static let contractNumberPlaceholder = tr("payments.topUp.contractNumberPlaceholder")
            static let depositTitle = tr("payments.topUp.depositTitle")
            static let errorTitle = tr("payments.topUp.errorTitle")
            static let payButton = tr("payments.topUp.payButton")
            static let paymentByBankCardButton = tr("payments.topUp.paymentByBankCardButton")
            static let recommendedAmountPlaceholder = tr("payments.topUp.recommendedAmountPlaceholder")
            static let recommendedLabel = tr("payments.topUp.recommendedLabel")
            static let successMessage = tr("payments.topUp.successMessage")
            static let successMessageShort = tr("payments.topUp.successMessageShort")
            static let successTitle = tr("payments.topUp.successTitle")
            static let topUpBalance = tr("payments.topUp.topUpBalance")
        }
    }

    enum Permissions {
        enum Camera {
            static let message = tr("permissions.camera.message")
            static let title = tr("permissions.camera.title")
        }

        enum Microphone {
            static let title = tr("permissions.microphone.title")
        }
    }

    enum Profile {
        static let firstName = tr("profile.firstName")
        static let patronymic = tr("profile.patronymic")
    }

    enum QuickAction {
        enum Error {
            static let unsupported = tr("quickAction.error.unsupported")
        }

        enum FirstAddress {
            static let accessTitle = tr("quickAction.firstAddress.accessTitle")
            static let camerasNotFound = tr("quickAction.firstAddress.camerasNotFound")
            static let camerasTitle = tr("quickAction.firstAddress.camerasTitle")
            static let eventsTitle = tr("quickAction.firstAddress.eventsTitle")
            static let noAccessSettings = tr("quickAction.firstAddress.noAccessSettings")
            static let noAddresses = tr("quickAction.firstAddress.noAddresses")
            static let noCameras = tr("quickAction.firstAddress.noCameras")
            static let noEvents = tr("quickAction.firstAddress.noEvents")
        }
    }

    enum Request {
        enum Common {
            static let submittedTitle = tr("request.common.submittedTitle")
        }
    }

    enum Services {
        enum ActivationRequest {
            static let oops = tr("services.activationRequest.oops")
            static let requestButton = tr("services.activationRequest.requestButton")
            static let subtitle = tr("services.activationRequest.subtitle")
        }

        enum Available {
            static let loadingTitle = tr("services.available.loadingTitle")
            static let title = tr("services.available.title")

            enum Card {
                static let smartIntercom = tr("services.available.card.smartIntercom")
            }

            enum Error {
                static let noServiceSelected = tr("services.available.error.noServiceSelected")
            }

            enum SmartIntercom {
                static let subtitle = tr("services.available.smartIntercom.subtitle")
            }
        }

        enum Catalog {
            static let cableTV = tr("services.catalog.cableTV")
            static let internet = tr("services.catalog.internet")
            static let mobilePhone = tr("services.catalog.mobilePhone")
            static let smartIntercom = tr("services.catalog.smartIntercom")
            static let videoSurveillance = tr("services.catalog.videoSurveillance")
            static let wiredPhone = tr("services.catalog.wiredPhone")
        }

        enum Request {
            static let createButton = tr("services.request.createButton")
            static let loadingTitle = tr("services.request.loadingTitle")
            static let mainUserInfoFormat = tr("services.request.mainUserInfoFormat")
            static let unknownContractNumber = tr("services.request.unknownContractNumber")
        }

        enum Status {
            enum Activated {
                static let changePlanButton = tr("services.status.activated.changePlanButton")
                static let changePlanHint = tr("services.status.activated.changePlanHint")
                static let serviceActivated = tr("services.status.activated.serviceActivated")
                static let titleFormat = tr("services.status.activated.titleFormat")
            }

            enum NotActivated {
                static let requestButton = tr("services.status.notActivated.requestButton")
                static let subtitle = tr("services.status.notActivated.subtitle")
                static let title = tr("services.status.notActivated.title")
            }

            enum SoonAvailable {
                static let addressInstructionPlaceholder = tr("services.status.soonAvailable.addressInstructionPlaceholder")
                static let title = tr("services.status.soonAvailable.title")
            }

            enum Unavailable {
                static let message = tr("services.status.unavailable.message")
                static let requestButton = tr("services.status.unavailable.requestButton")
                static let title = tr("services.status.unavailable.title")
            }
        }
    }

    enum Session {
        enum Conflict {
            static let message = tr("session.conflict.message")
            static let title = tr("session.conflict.title")
        }
    }

    enum Settings {
        enum Address {
            static let addressSettings = tr("settings.address.addressSettings")
            static let deleteAddressButton = tr("settings.address.deleteAddressButton")
            static let hideEventLogTitle = tr("settings.address.hideEventLogTitle")
            static let intercom = tr("settings.address.intercom")
            static let intercomEnabled = tr("settings.address.intercomEnabled")
            static let keepAnEventLog = tr("settings.address.keepAnEventLog")
            static let label = tr("settings.address.label")
            static let noteLabel = tr("settings.address.noteLabel")
            static let receiveCalls = tr("settings.address.receiveCalls")
            static let receivePaperBills = tr("settings.address.receivePaperBills")
            static let recognizeFaces = tr("settings.address.recognizeFaces")
            static let recognizePlates = tr("settings.address.recognizePlates")
            static let whiteRabbitMode = tr("settings.address.whiteRabbitMode")

            enum WhiteRabbitInfo {
                static let description = tr("settings.address.whiteRabbitInfo.description")
                static let step1 = tr("settings.address.whiteRabbitInfo.step1")
                static let step2 = tr("settings.address.whiteRabbitInfo.step2")
                static let step3 = tr("settings.address.whiteRabbitInfo.step3")
                static let stepsTitle = tr("settings.address.whiteRabbitInfo.stepsTitle")
                static let title = tr("settings.address.whiteRabbitInfo.title")
                static let validityHint = tr("settings.address.whiteRabbitInfo.validityHint")
            }
        }

        enum AddressAccess {
            static let accessToAddress = tr("settings.addressAccess.accessToAddress")
            static let accessToTheBarrierGate = tr("settings.addressAccess.accessToTheBarrierGate")
            static let addressPlaceholder = tr("settings.addressAccess.addressPlaceholder")
            static let permanentAccessTitle = tr("settings.addressAccess.permanentAccessTitle")

            enum FaceID {
                static let beta = tr("settings.addressAccess.faceId.beta")
                static let disabledMessage = tr("settings.addressAccess.faceId.disabledMessage")
                static let registeredFaces = tr("settings.addressAccess.faceId.registeredFaces")
                static let setupButton = tr("settings.addressAccess.faceId.setupButton")
                static let title = tr("settings.addressAccess.faceId.title")
            }

            enum GateDetails {
                static let addressPlaceholder = tr("settings.addressAccess.gateDetails.addressPlaceholder")
                static let carFilter = tr("settings.addressAccess.gateDetails.carFilter")
                static let expired = tr("settings.addressAccess.gateDetails.expired")
                static let phoneFilter = tr("settings.addressAccess.gateDetails.phoneFilter")
                static let timeRemainingFormat = tr("settings.addressAccess.gateDetails.timeRemainingFormat")
                static let title = tr("settings.addressAccess.gateDetails.title")
                static let unlimited = tr("settings.addressAccess.gateDetails.unlimited")
            }

            enum GuestAccess {
                static let alertMessage = tr("settings.addressAccess.guestAccess.alertMessage")
                static let alertTitle = tr("settings.addressAccess.guestAccess.alertTitle")
                static let sentMessage = tr("settings.addressAccess.guestAccess.sentMessage")
            }

            enum NewPerson {
                static let addContact = tr("settings.addressAccess.newPerson.addContact")
            }

            enum RemoveAccess {
                static let message = tr("settings.addressAccess.removeAccess.message")
            }

            enum Shortcuts {
                static let addCar = tr("settings.addressAccess.shortcuts.addCar")
                static let addPerson = tr("settings.addressAccess.shortcuts.addPerson")
                static let allCars = tr("settings.addressAccess.shortcuts.allCars")
                static let allPeople = tr("settings.addressAccess.shortcuts.allPeople")
            }

            enum TemporaryAccess {
                static let codeTitle = tr("settings.addressAccess.temporaryAccess.codeTitle")
                static let guestAccessTitle = tr("settings.addressAccess.temporaryAccess.guestAccessTitle")
                static let title = tr("settings.addressAccess.temporaryAccess.title")
            }

            enum WaitingGuestInfo {
                static let message = tr("settings.addressAccess.waitingGuestInfo.message")
                static let title = tr("settings.addressAccess.waitingGuestInfo.title")
                static let validity = tr("settings.addressAccess.waitingGuestInfo.validity")
            }
        }

        enum AddressDeletion {
            static let other = tr("settings.addressDeletion.other")
            static let pleaseStateTheReason = tr("settings.addressDeletion.pleaseStateTheReason")
            static let terminateContractOption = tr("settings.addressDeletion.terminateContractOption")
            static let warningMessage = tr("settings.addressDeletion.warningMessage")

            enum Reason {
                static let placeholder = tr("settings.addressDeletion.reason.placeholder")
                static let terminateContract = tr("settings.addressDeletion.reason.terminateContract")
                static let unspecified = tr("settings.addressDeletion.reason.unspecified")
            }
        }

        enum Common {
            static let calls = tr("settings.common.calls")
            static let deleteAccountButton = tr("settings.common.deleteAccountButton")
            static let language = tr("settings.common.language")
            static let logoutButton = tr("settings.common.logoutButton")
            static let lowBalanceNotificationTitle = tr("settings.common.lowBalanceNotificationTitle")
            static let notifications = tr("settings.common.notifications")
            static let notifyAboutInsufficientFunds = tr("settings.common.notifyAboutInsufficientFunds")
            static let profileNamePlaceholder = tr("settings.common.profileNamePlaceholder")
            static let profilePhonePlaceholder = tr("settings.common.profilePhonePlaceholder")
            static let showCamerasOnTheMap = tr("settings.common.showCamerasOnTheMap")
            static let showNotifications = tr("settings.common.showNotifications")
            static let speakerphoneByDefault = tr("settings.common.speakerphoneByDefault")
            static let theme = tr("settings.common.theme")
            static let title = tr("settings.common.title")
            static let useCallkit = tr("settings.common.useCallkit")

            enum AddressOrder {
                static let description = tr("settings.common.addressOrder.description")
                static let resetDialogMessage = tr("settings.common.addressOrder.resetDialogMessage")
                static let resetDialogTitle = tr("settings.common.addressOrder.resetDialogTitle")
                static let resetHint = tr("settings.common.addressOrder.resetHint")
                static let title = tr("settings.common.addressOrder.title")
            }

            enum Appearance {
                static let dark = tr("settings.common.appearance.dark")
                static let light = tr("settings.common.appearance.light")
                static let sheetMessage = tr("settings.common.appearance.sheetMessage")
                static let sheetTitle = tr("settings.common.appearance.sheetTitle")
                static let system = tr("settings.common.appearance.system")
                static let title = tr("settings.common.appearance.title")
            }

            enum CallKitInfo {
                static let description = tr("settings.common.callKitInfo.description")
                static let title = tr("settings.common.callKitInfo.title")
            }

            enum DeleteAccount {
                static let message = tr("settings.common.deleteAccount.message")
                static let title = tr("settings.common.deleteAccount.title")
            }

            enum Logout {
                static let message = tr("settings.common.logout.message")
                static let title = tr("settings.common.logout.title")
            }
        }

        enum Faces {
            static let emptyStateMessage = tr("settings.faces.emptyStateMessage")
            static let faceRegistration = tr("settings.faces.faceRegistration")
            static let registeredFaces = tr("settings.faces.registeredFaces")
            static let registrationHint = tr("settings.faces.registrationHint")
        }

        enum Main {
            static let addAddressButton = tr("settings.main.addAddressButton")
            static let contractNumberTitle = tr("settings.main.contractNumberTitle")
            static let openPersonalAccountWebButton = tr("settings.main.openPersonalAccountWebButton")

            enum Access {
                static let title = tr("settings.main.access.title")
            }

            enum Address {
                static let title = tr("settings.main.address.title")
            }

            enum Addresses {
                static let title = tr("settings.main.addresses.title")
            }

            enum ServiceAction {
                static let activateServiceTemplate = tr("settings.main.serviceAction.activateServiceTemplate")
                static let changeTariffTemplate = tr("settings.main.serviceAction.changeTariffTemplate")
                static let talkAboutActivationTemplate = tr("settings.main.serviceAction.talkAboutActivationTemplate")
            }
        }

        enum TrackedEvents {
            static let emptyState = tr("settings.trackedEvents.emptyState")
            static let title = tr("settings.trackedEvents.title")

            enum DeleteConfirmation {
                static let title = tr("settings.trackedEvents.deleteConfirmation.title")
            }
        }

        enum ShareCar {
            static let platePlaceholder = tr("settings.shareCar.platePlaceholder")
            static let shareAccess = tr("settings.shareCar.shareAccess")
            static let subtitle = tr("settings.shareCar.subtitle")
        }

        enum SharePerson {
            static let name = tr("settings.sharePerson.name")
            static let shareAccess = tr("settings.sharePerson.shareAccess")
            static let shareButton = tr("settings.sharePerson.shareButton")
            static let subtitle = tr("settings.sharePerson.subtitle")
        }

    }

    enum Support {
        enum Call {
            static let phoneAction = tr("support.call.phoneAction")
        }

        enum Callback {
            static let requestButton = tr("support.callback.requestButton")
            static let successMessage = tr("support.callback.successMessage")
        }
    }

    enum Tab {
        static let addresses = tr("tab.addresses")
        static let chat = tr("tab.chat")
        static let menu = tr("tab.menu")
        static let notifications = tr("tab.notifications")
        static let payments = tr("tab.payments")
    }

    enum Validation {
        enum Name {
            enum FirstName {
                static let invalid = tr("validation.name.firstName.invalid")
            }

            enum LastName {
                static let invalid = tr("validation.name.lastName.invalid")
            }

            enum Patronymic {
                static let invalid = tr("validation.name.patronymic.invalid")
            }
        }

        enum Phone {
            static let invalidFormat = tr("validation.phone.invalidFormat")
        }
    }
}
// swiftlint:enable file_length type_body_length nesting
