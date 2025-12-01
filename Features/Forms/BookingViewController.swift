import UIKit

extension Notification.Name {
    static let bookingsChanged = Notification.Name("bookingsChanged")
}

/// Экран бронирования апартамента
final class BookingViewController: UIViewController {

    // MARK: - Dependencies / state

    private let apartment: MediumApartmentResponse
    private let existingBookings: [BookingRangeDTO]

    /// Выбранное начало / конец (полные Date с датой+временем).
    /// По умолчанию nil, пока пользователь ничего не выбрал.
    private var fromDate: Date?
    private var toDate: Date?

    // MARK: - UI

    private let addressLabel = UILabel()

    // календари и их selection-объекты
    private let fromCalendar = UICalendarView()
    private let toCalendar = UICalendarView()
    private var fromSelection: UICalendarSelectionSingleDate!
    private var toSelection: UICalendarSelectionSingleDate!

    // отдельные пикеры времени
    private let fromTimePicker = UIDatePicker()
    private let toTimePicker = UIDatePicker()

    private let totalLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    private var isSaving = false

    // MARK: - Init

    init(apartment: MediumApartmentResponse,
         bookings: [BookingRangeDTO]) {
        self.apartment = apartment
        self.existingBookings = bookings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Lifecycle

extension BookingViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Booking"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(onClose)
        )

        configureUI()
        updateTotal()   // пока нет дат → Total: 0
    }
}

// MARK: - UI configuration

private extension BookingViewController {
    func configureUI() {
        // Адрес
        addressLabel.text = apartment.address
        addressLabel.font = .preferredFont(forTextStyle: .headline)
        addressLabel.numberOfLines = 0
        
        let addressContainer = UIStackView(arrangedSubviews: [addressLabel])
        addressContainer.axis = .vertical
        addressContainer.spacing = 4
        
        // Общий диапазон для календарей: от сегодня и на 2 года вперёд
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let maxDate = cal.date(byAdding: .year, value: 2, to: todayStart)
        ?? todayStart.addingTimeInterval(60 * 60 * 24 * 365)
        
        let dateRange = DateInterval(start: todayStart, end: maxDate)
        
        // FROM блок
        let fromTitle = UILabel()
        fromTitle.text = "From"
        fromTitle.font = .preferredFont(forTextStyle: .headline)
        
        fromCalendar.calendar = cal
        fromCalendar.locale = .current
        fromCalendar.availableDateRange = dateRange
        let fromSel = UICalendarSelectionSingleDate(delegate: self)
        fromCalendar.selectionBehavior = fromSel
        fromSelection = fromSel
        
        fromTimePicker.datePickerMode = .time
        fromTimePicker.preferredDatePickerStyle = .compact
        fromTimePicker.addTarget(self, action: #selector(onTimeChanged), for: .valueChanged)
        
        let fromStack = UIStackView(arrangedSubviews: [fromTitle, fromCalendar, fromTimePicker])
        fromStack.axis = .vertical
        fromStack.spacing = 8
        
        // TO блок
        let toTitle = UILabel()
        toTitle.text = "To"
        toTitle.font = .preferredFont(forTextStyle: .headline)
        
        toCalendar.calendar = cal
        toCalendar.locale = .current
        toCalendar.availableDateRange = dateRange
        let toSel = UICalendarSelectionSingleDate(delegate: self)
        toCalendar.selectionBehavior = toSel
        toSelection = toSel
        
        toTimePicker.datePickerMode = .time
        toTimePicker.preferredDatePickerStyle = .compact
        toTimePicker.addTarget(self, action: #selector(onTimeChanged), for: .valueChanged)

        let toStack = UIStackView(arrangedSubviews: [toTitle, toCalendar, toTimePicker])
        toStack.axis = .vertical
        toStack.spacing = 8

        // Разделители
        func makeSeparator() -> UIView {
            let v = UIView()
            v.backgroundColor = .separator
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
            return v
        }
        let sep1 = makeSeparator()
        let sep2 = makeSeparator()

        // Ошибки
        errorLabel.textColor = .systemRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        // Нижняя панель
        totalLabel.font = .preferredFont(forTextStyle: .headline)
        totalLabel.textAlignment = .left

        sendButton.setTitle("SEND", for: .normal)
        sendButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        sendButton.tintColor = .white
        sendButton.backgroundColor = .systemGreen
        sendButton.layer.cornerRadius = 10
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)

        activity.hidesWhenStopped = true

        let bottomStack = UIStackView(arrangedSubviews: [totalLabel, sendButton, activity])
        bottomStack.axis = .horizontal
        bottomStack.alignment = .center
        bottomStack.spacing = 12

        // --- Скролл + контентный стек ---

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        let contentStack = UIStackView(arrangedSubviews: [
            addressContainer,
            fromStack,
            sep1,
            toStack,
            sep2,
            errorLabel,
            bottomStack
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
}

// MARK: - Actions

private extension BookingViewController {

    @objc func onTimeChanged() {
        recomputeDates()
        errorLabel.isHidden = true
        updateTotal()
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

    @objc func onSend() {
        view.endEditing(true)
        guard !isSaving else { return }

        errorLabel.isHidden = true
        
        guard let from = fromDate, let to = toDate else {
            showError("Please choose both start and end time.")
            return
        }
        guard to > from else {
            showError("End time must be after start time.")
            return
        }

        if hasOverlap(from: from, to: to) {
            showError("Selected time overlaps with another booking.")
            return
        }

        isSaving = true
        setSavingUI(true)

        let dto = BookingCreateDTO(
            user_id: AppState.shared.userId,
            apartment_id: apartment.id,
            time_from: from,
            time_to: to
        )

        Task {
            do {
                _ = try await AppState.shared.api.bookApartment(dto)

                if let cached = AppState.shared.api as? CachedClientWrapper {
                    await cached.invalidateBookings()
                    await cached.invalidateApartmentDetails()
                }

                await MainActor.run {
                    self.sendButton.setTitle("CONFIRMED", for: .normal)
                    self.sendButton.backgroundColor = .systemBlue
                    NotificationCenter.default.post(name: .bookingsChanged, object: nil)
                }

                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.setSavingUI(false)
                    self.showError("Failed to book: \(error)")
                }
            }
        }
    }
}

// MARK: - Helpers

private extension BookingViewController {

    func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute, .second], from: time)

        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute
        comps.second = t.second

        return cal.date(from: comps) ?? date
    }

    func nightsBetween(from: Date, to: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: from)
        let end   = cal.startOfDay(for: to)
        let comps = cal.dateComponents([.day], from: start, to: end)
        return max(comps.day ?? 0, 0)
    }

    func updateTotal() {
        guard let f = fromDate, let t = toDate else {
            totalLabel.text = "Total: 0"
            return
        }

        let nights = nightsBetween(from: f, to: t)
        if nights <= 0 {
            totalLabel.text = "Total: 0"
        } else {
            let total = Double(nights) * apartment.price
            totalLabel.text = String(format: "Total: %.2f (%d nights)", total, nights)
        }
    }

    func hasOverlap(from: Date, to: Date) -> Bool {
        for b in existingBookings {
            if !(to <= b.from || from >= b.to) {
                return true
            }
        }
        return false
    }

    func nearestBookingStart(after date: Date) -> Date? {
        existingBookings
            .map { $0.from }
            .filter { $0 > date }
            .min()
    }

    func recomputeDates() {
        let cal = Calendar.current

        // FROM
        if let comps = fromSelection.selectedDate,
           let day = cal.date(from: comps) {
            fromDate = combine(date: day, time: fromTimePicker.date)
        } else {
            fromDate = nil
        }

        // TO
        if let comps = toSelection.selectedDate,
           let day = cal.date(from: comps) {
            toDate = combine(date: day, time: toTimePicker.date)
        } else {
            toDate = nil
        }
    }
    
    func setSavingUI(_ saving: Bool) {
        sendButton.isEnabled = !saving
        fromCalendar.isUserInteractionEnabled = !saving
        toCalendar.isUserInteractionEnabled = !saving
        fromTimePicker.isUserInteractionEnabled = !saving
        toTimePicker.isUserInteractionEnabled = !saving

        if saving {
            activity.startAnimating()
        } else {
            activity.stopAnimating()
        }
    }

    func showError(_ text: String) {
        errorLabel.text = text
        errorLabel.isHidden = false
    }
}

// MARK: - UICalendarSelectionSingleDateDelegate

extension BookingViewController: UICalendarSelectionSingleDateDelegate {

    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) {
        // При выборе FROM обновляем ограничения для TO
        if selection === fromSelection {
            // Пересоздаём selectionBehavior, чтобы система заново спросила canSelectDate
            let newSelection = UICalendarSelectionSingleDate(delegate: self)
            newSelection.selectedDate = toSelection.selectedDate   // если был выбран день — переносим
            toCalendar.selectionBehavior = newSelection
            toSelection = newSelection
        }

        recomputeDates()
        errorLabel.isHidden = true
        updateTotal()
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       canSelectDate dateComponents: DateComponents?) -> Bool {
        guard let comps = dateComponents,
              let date = Calendar.current.date(from: comps) else { return false }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayStart = cal.startOfDay(for: date)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return false }

        // нельзя выбирать прошлое
        if dayStart < today { return false }

        // нельзя пересекаться с существующей бронью
        for b in existingBookings {
            let bStart = b.from
            let bEnd = b.to
            if !(dayEnd <= bStart || dayStart >= bEnd) {
                return false
            }
        }

        if selection === fromSelection {
            // для FROM этого достаточно
            return true
        }

        // Для TO нужен выбранный FROM
        let fromBase: Date?
        if let f = fromDate {
            fromBase = f
        } else if let fc = fromSelection.selectedDate,
                  let fDate = cal.date(from: fc) {
            fromBase = fDate
        } else {
            return false
        }

        guard let base = fromBase else { return false }
        let fromDay = cal.startOfDay(for: base)

        // TO-день должен быть строго позже FROM-дня
        if dayStart <= fromDay { return false }

        // нельзя заходить за ближайшую бронь после FROM
        if let limit = nearestBookingStart(after: base) {
            let limitDay = cal.startOfDay(for: limit)
            if dayStart >= limitDay {
                return false
            }
        }

        return true
    }
}
