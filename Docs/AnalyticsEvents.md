# Analytics Events

Firebase Analytics уже подключен в приложении через CocoaPods (`FirebaseAnalytics 10.29.0`) и инициализируется в `AppDelegate` через `FirebaseApp.configure()`. Все события должны отправляться через `AnalyticsTracking` / `AppAnalytics`, прямой `Analytics.logEvent(...)` разрешен только внутри `FirebaseAnalyticsTracker`.

Для проверки DebugView запустите debug-сборку с аргументом `-FIRDebugEnabled` и проверьте события в Firebase Console.

## Privacy

В аналитику нельзя отправлять телефон, email, ФИО, точный адрес, квартиру, access/refresh/push token, полный QR-код, сырые URL и любые персональные данные. Ошибки логируются через `app_error`, а `error_message_safe` проходит очистку от email, URL, телефоноподобных строк и длинных token-like значений.

## Events

| Event name | Когда отправляется | Parameters | Где используется |
|---|---|---|---|
| app_opened | Приложение запущено | app_version, build_number, environment | AppDelegate |
| app_first_opened | Первый запуск приложения на устройстве | app_version, build_number, environment | AppDelegate |
| app_became_active | Приложение стало активным | app_version, build_number, environment | AppDelegate |
| app_entered_background | Приложение ушло в background | app_version, build_number, environment | AppDelegate |
| screen_opened | Открыт основной экран | screen, source | BaseViewController + AnalyticsScreenTrackable |
| app_error | Безопасное логирование ошибки | scenario, screen, error_code, error_message_safe | ErrorTracker, support, push permission |
| auth_screen_opened | Открыт экран авторизации | screen, source, scenario | Auth screens |
| auth_phone_entered | Пользователь ввел телефон до полной длины | screen, source, scenario | InputPhoneNumberViewModel |
| auth_code_requested | Запрошен SMS/OTP/flash/outgoing-call код | screen, source, scenario | InputPhoneNumberViewModel, PinCodeViewModel |
| auth_code_request_success | Код успешно запрошен | screen, source, scenario, result | InputPhoneNumberViewModel, PinCodeViewModel |
| auth_code_request_failed | Ошибка запроса кода | screen, source, scenario, result, error_code, error_message_safe | InputPhoneNumberViewModel, PinCodeViewModel |
| auth_code_confirmed | Код/звонок успешно подтвержден | screen, source, scenario, result | PinCodeViewModel, OutgoingCallViewModel |
| auth_code_confirmation_failed | Ошибка подтверждения кода/звонка | screen, source, scenario, result, error_code, error_message_safe | PinCodeViewModel, OutgoingCallViewModel |
| auth_success | Авторизация завершилась успешно | screen, source, scenario, result | PinCodeViewModel, OutgoingCallViewModel |
| auth_logout | Пользовательская сессия завершена | screen, source, scenario | CommonSettingsViewModel |
| address_list_opened | Загружен список адресов | screen, addresses_count, has_multiple_addresses, source | AddressesListViewModel |
| address_selected | Пользователь выбрал/раскрыл адрес | screen, addresses_count, has_multiple_addresses, source | AddressesListViewModel |
| address_switch_success | Переключение/раскрытие адреса выполнено | screen, addresses_count, has_multiple_addresses, source, result | AddressesListViewModel |
| address_switch_failed | Ошибка переключения адреса | screen, addresses_count, has_multiple_addresses, source, result, error_code | AppAnalyticsEvent API |
| intercom_screen_opened | Открыт экран домофона/доступа | screen, source | AddressAccess screens |
| door_open_tapped | Нажали открыть дверь | screen, source, scenario, access_type | AddressesListViewModel |
| door_open_success | Дверь успешно открыта | screen, source, scenario, access_type, result | AddressesListViewModel |
| door_open_failed | Ошибка открытия двери | screen, source, scenario, access_type, result, error_code | AddressesListViewModel |
| door_open_cancelled | Открытие двери отменено | screen, source, scenario, access_type, result | AppAnalyticsEvent API |
| cameras_list_opened | Открыт список/карта камер | screen, source | Camera screens |
| camera_selected | Выбрана камера | screen, source, scenario, camera_type | AddressesListViewModel, CamerasListViewModel, YardMapViewModel |
| camera_stream_start_requested | Запрошен запуск live/archive потока | screen, source, scenario, camera_type, stream_type | SelectCameraContainerViewModel |
| camera_stream_started | Live-поток запущен | screen, source, scenario, camera_type, stream_type, result | OnlinePlaybackCoordinator |
| camera_stream_failed | Ошибка запуска потока | screen, source, scenario, camera_type, stream_type, result, error_code | AppAnalyticsEvent API |
| camera_fullscreen_opened | Открыт fullscreen камеры | screen, source, scenario, camera_type, stream_type | OnlinePageViewController |
| camera_fullscreen_closed | Закрыт fullscreen камеры | screen, source, scenario, camera_type, stream_type | OnlineFullscreenViewController |
| camera_landscape_enabled | Fullscreen открыт в landscape | screen, source, scenario, camera_type | OnlineFullscreenViewController |
| camera_snapshot_tapped | Нажат снимок камеры | screen, source, scenario, camera_type, stream_type | AppAnalyticsEvent API |
| events_list_opened | Открыт список событий | screen, source | HistoryViewController |
| event_details_opened | Открыта карточка события | screen, event_type, source, has_media | HistoryViewModel |
| event_filter_opened | Открыт фильтр событий | screen, filter_type, source | HistoryViewController |
| event_filter_applied | Фильтр событий применен | screen, filter_type, source | HistoryViewController |
| event_type_selected | Выбран тип события | screen, event_type, source | HistoryViewController |
| event_video_opened | Открыто событие с видео | screen, event_type, source, has_media | HistoryViewModel |
| event_image_opened | Открыто событие с изображением | screen, event_type, source, has_media | HistoryViewModel |
| qr_scanner_opened | Открыт QR-сканер | screen, source, scenario | QRCodeScanViewController |
| qr_scan_started | Запущено сканирование QR | screen, source, scenario | QRCodeScanViewController |
| qr_scan_success | QR успешно считан | screen, source, scenario, qr_type, result | QRCodeScanViewModel, deeplink |
| qr_scan_failed | Ошибка сканирования QR | screen, source, scenario, qr_type, result, error_code | QRCodeScanViewController |
| qr_scan_invalid_format | QR имеет неподдерживаемый формат | screen, source, scenario, qr_type, result, error_code | AppAnalyticsEvent API |
| qr_access_grant_success | Доступ по QR успешно выдан | screen, source, scenario, qr_type, result | AddressesListViewModel, AppCoordinator, InputAddressViewModel, ServiceSoonAvailableViewModel |
| qr_access_grant_failed | Ошибка выдачи доступа по QR | screen, source, scenario, qr_type, result, error_code | AddressesListViewModel, AppCoordinator, InputAddressViewModel, ServiceSoonAvailableViewModel |
| push_permission_requested | Запрошено разрешение на push | source, scenario | AppDelegate |
| push_permission_granted | Push-разрешение выдано | source, scenario, result | AppDelegate |
| push_permission_denied | Push-разрешение отклонено | source, scenario, result | AppDelegate |
| push_received | Получен push | push_type, source, scenario | AppDelegate |
| push_opened | Push открыт | push_type, source, scenario, result | AppDelegate |
| push_action_tapped | Нажато действие push | push_type, source, scenario | AppDelegate |
| push_open_failed | Ошибка открытия push | push_type, source, scenario, result, error_code | AppDelegate |
| payments_screen_opened | Открыт экран платежей | screen, source, scenario | PaymentsViewController |
| payment_start_tapped | Начат платежный сценарий | screen, source, scenario, payment_type, amount_range | PaymentsViewModel, PayContractViewModel |
| payment_method_selected | Выбран способ оплаты | screen, source, scenario, payment_type, amount_range | PaymentPopupController |
| payment_started | Платеж отправлен в процессинг/банк | screen, source, scenario, payment_type, amount_range | PaymentPopupController |
| payment_success | Платеж завершен успешно | screen, source, scenario, payment_type, amount_range, result | PaymentPopupController, AppDelegate |
| payment_failed | Ошибка платежа | screen, source, scenario, payment_type, amount_range, result, error_code | PaymentPopupController, AppDelegate |
| payment_cancelled | Платеж отменен пользователем | screen, source, scenario, payment_type, amount_range, result | PaymentPopupController |
| settings_opened | Открыт экран настроек | screen, source | SettingsViewController |
| setting_toggled | Переключена настройка | setting_name, new_value, screen | CommonSettingsViewModel |
| notification_setting_changed | Изменена настройка уведомлений | setting_name, new_value, screen | CommonSettingsViewModel |
| theme_changed | Изменена тема | setting_name, new_value, screen | CommonSettingsViewModel |
| language_changed | Изменен язык | setting_name, new_value, screen | AppAnalyticsEvent API |
| account_delete_tapped | Нажато удаление аккаунта | screen, setting_name | CommonSettingsViewModel |
| logout_tapped | Нажат выход из аккаунта | screen, setting_name | CommonSettingsViewModel |
