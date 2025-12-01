import UIKit

// MARK: - Notification для обновления MyApartments

extension Notification.Name {
    static let apartmentsChanged = Notification.Name("apartmentsChanged")
}

// MARK: - Режим и модели

/// Режим работы экрана: создание или редактирование существующей записи
enum ApartmentEditorMode {
    case create
    case edit(existing: MediumApartmentResponse)
}

/// Одна строка в таблице доп. полей (info)
struct InfoRow {
    var key: String
    var value: String
}

final class ApartmentEditorViewController: UIViewController {

    // MARK: - Public

    private let mode: ApartmentEditorMode

    init(mode: ApartmentEditorMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let addressField = UITextField()
    private let priceField = UITextField()

    private let infoHeaderLabel = UILabel()
    private let addInfoButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let descriptionLabel = UILabel()
    private let descriptionTextView = UITextView()

    private let errorLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)

    // MARK: - State

    private var infoRows: [InfoRow] = []
    private var isSaving = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        configureUI()
        configureForMode()
    }

    // MARK: - UI setup

    private func configureUI() {
        title = {
            switch mode {
            case .create: return "New Apartment"
            case .edit:   return "Edit Apartment"
            }
        }()
        
        // Scroll + stack
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentStack.axis = .vertical
        contentStack.spacing = 16
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
        
        // Address
        contentStack.addArrangedSubview(makeLabeledField(label: "Address", textField: addressField))
        addressField.placeholder = "Address"
        addressField.borderStyle = .roundedRect
        addressField.autocapitalizationType = .words
        addressField.clearButtonMode = .whileEditing
        
        // Price
        contentStack.addArrangedSubview(makeLabeledField(label: "Price per night", textField: priceField))
        priceField.placeholder = "Price"
        priceField.borderStyle = .roundedRect
        priceField.keyboardType = .decimalPad
        priceField.clearButtonMode = .whileEditing

        // Info header + "Add field"
        let infoHeaderStack = UIStackView()
        infoHeaderStack.axis = .horizontal
        infoHeaderStack.alignment = .center

        infoHeaderLabel.text = "Extra info"
        infoHeaderLabel.font = .preferredFont(forTextStyle: .headline)

        addInfoButton.setTitle("Add field", for: .normal)
        addInfoButton.addTarget(self, action: #selector(addInfoRow), for: .touchUpInside)

        infoHeaderStack.addArrangedSubview(infoHeaderLabel)
        infoHeaderStack.addArrangedSubview(UIView())
        infoHeaderStack.addArrangedSubview(addInfoButton)

        contentStack.addArrangedSubview(infoHeaderStack)

        // Table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tableView.tableFooterView = UIView()
        tableView.register(InfoCell.self, forCellReuseIdentifier: InfoCell.reuseId)
        contentStack.addArrangedSubview(tableView)

        // побольше места под таблицу (минимум под ~5 строк)
        tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true

        // Description
        descriptionLabel.text = "Description"
        descriptionLabel.font = .preferredFont(forTextStyle: .headline)
        contentStack.addArrangedSubview(descriptionLabel)

        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor.separator.cgColor
        descriptionTextView.font = .preferredFont(forTextStyle: .body)
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        contentStack.addArrangedSubview(descriptionTextView)

        // Error label
        errorLabel.textColor = .systemRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        contentStack.addArrangedSubview(errorLabel)

        // Bottom send button
        let bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.alignment = .center
        bottomStack.spacing = 8

        sendButton.setTitle("SEND", for: .normal)
        sendButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        sendButton.tintColor = .white
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 10
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)

        activity.hidesWhenStopped = true

        bottomStack.addArrangedSubview(sendButton)
        bottomStack.addArrangedSubview(activity)
        contentStack.addArrangedSubview(bottomStack)
    }

    private func makeLabeledField(label: String, textField: UITextField) -> UIStackView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .preferredFont(forTextStyle: .headline)

        let stack = UIStackView(arrangedSubviews: [labelView, textField])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    // MARK: - Mode config

    private func configureForMode() {
        switch mode {
        case .create:
            // по умолчанию добавляем rooms/beds
            infoRows = [
                InfoRow(key: "rooms", value: ""),
                InfoRow(key: "beds", value: "")
            ]

        case .edit(let ap):
            addressField.text = ap.address
            addressField.isEnabled = false
            addressField.backgroundColor = .systemGray5

            priceField.text = ap.price > 0 ? String(format: "%.2f", ap.price) : ""
            
            var rows: [InfoRow] = []
            for (k, v) in ap.info {
                let lk = k.lowercased()
                // text_desc идёт в отдельное поле
                if lk == "text_desc" { continue }
                rows.append(InfoRow(key: k, value: v))
            }
            // гарантируем наличие rooms / beds
            if !rows.contains(where: { $0.key.lowercased() == "rooms" }) {
                rows.append(InfoRow(key: "rooms", value: ""))
            }
            if !rows.contains(where: { $0.key.lowercased() == "beds" }) {
                rows.append(InfoRow(key: "beds", value: ""))
            }
            infoRows = rows

            if let desc = ap.info["text_desc"] {
                descriptionTextView.text = desc
            }
        }
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func addInfoRow() {
        infoRows.append(InfoRow(key: "", value: ""))
        tableView.reloadData()
    }

    @objc private func onSend() {
        view.endEditing(true)
        guard !isSaving else { return }

        errorLabel.isHidden = true

        // базовая валидация
        let address = addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let priceText = priceField.text?.replacingOccurrences(of: ",", with: ".") ?? ""

        guard !address.isEmpty else {
            showError("Address is required")
            return
        }
        guard let price = Double(priceText), price > 0 else {
            showError("Price must be a positive number")
            return
        }

        // собираем info
        var info: [String:String] = [:]
        for row in infoRows {
            let key = row.key.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty && value.isEmpty { continue }

            if key.lowercased() == "text_desc" {
                showError("Key 'text_desc' is reserved and cannot be used here.")
                return
            }
            guard !key.isEmpty else {
                showError("All custom fields must have a key.")
                return
            }
            info[key] = value
        }

        let desc = descriptionTextView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !desc.isEmpty {
            info["text_desc"] = desc
        }

        let infoOrNil = info.isEmpty ? nil : info

        isSaving = true
        setSavingUI(true)

        Task {
            do {
                switch mode {
                case .create:
                    let dto = ApartmentCreateDTO(
                        owner_id: AppState.shared.userId,
                        address: address,
                        price: price,
                        info: infoOrNil
                    )
                    _ = try await AppState.shared.api.createApartment(dto)

                case .edit(let ap):
                    let dto = ApartmentUpdateDTO(
                        owner_id: ap.owner_id,
                        price: price,
                        info: infoOrNil
                    )
                    try await AppState.shared.api.updateApartment(id: ap.id, dto: dto)
                }

                // инвалидируем кеши, если обёртка есть
                if let cached = AppState.shared.api as? CachedClientWrapper {
                    await cached.invalidateOwnerApartments()
                    await cached.invalidateApartmentDetails()
                }

                // уведомляем MyApartmentsScreen, что данные изменились
                NotificationCenter.default.post(name: .apartmentsChanged, object: nil)

                await MainActor.run {
                    self.sendButton.setTitle("SAVED", for: .normal)
                    self.sendButton.backgroundColor = .systemGreen
                }

                // ждём 2 секунды и закрываем экран
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.setSavingUI(false)
                    self.showError("Failed to save: \(error)")
                }
            }
        }
    }

    private func setSavingUI(_ saving: Bool) {
        sendButton.isEnabled = !saving
        addressField.isEnabled = !(saving && {
            if case .edit = mode { return true } else { return false }
        }())
        priceField.isEnabled = !saving
        tableView.isUserInteractionEnabled = !saving
        descriptionTextView.isEditable = !saving

        if saving {
            activity.startAnimating()
        } else {
            activity.stopAnimating()
            if case .edit = mode {
                addressField.isEnabled = false // в edit всё равно нельзя трогать
            }
        }
    }

    private func showError(_ text: String) {
        errorLabel.text = text
        errorLabel.isHidden = false
    }
}

// MARK: - UITableView

extension ApartmentEditorViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        infoRows.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: InfoCell.reuseId,
            for: indexPath
        ) as! InfoCell

        let row = infoRows[indexPath.row]

        cell.configure(
            key: row.key,
            value: row.value,
            onKeyChange: { [weak self, weak cell, weak tableView] newKey in
                guard
                    let self,
                    let tableView,
                    let cell,
                    let idx = tableView.indexPath(for: cell)?.row,
                    idx < self.infoRows.count
                else { return }
                self.infoRows[idx].key = newKey
                self.errorLabel.isHidden = true
            },
            onValueChange: { [weak self, weak cell, weak tableView] newValue in
                guard
                    let self,
                    let tableView,
                    let cell,
                    let idx = tableView.indexPath(for: cell)?.row,
                    idx < self.infoRows.count
                else { return }
                self.infoRows[idx].value = newValue
            },
            onRemove: { [weak self, weak cell, weak tableView] in
                guard
                    let self,
                    let tableView,
                    let cell,
                    let idx = tableView.indexPath(for: cell)?.row,
                    idx < self.infoRows.count
                else { return }

                tableView.beginUpdates()
                self.infoRows.remove(at: idx)
                tableView.deleteRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
                tableView.endUpdates()
            }
        )

        return cell
    }
}

// MARK: - Ячейка для key/value

final class InfoCell: UITableViewCell {

    static let reuseId = "InfoCell"

    private let keyField = UITextField()
    private let valueField = UITextField()
    private let removeButton = UIButton(type: .system)

    private var onKeyChange: ((String) -> Void)?
    private var onValueChange: ((String) -> Void)?
    private var onRemove: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none

        keyField.placeholder = "Key"
        keyField.borderStyle = .roundedRect
        keyField.autocapitalizationType = .none

        valueField.placeholder = "Value"
        valueField.borderStyle = .roundedRect

        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .systemGray2
        removeButton.addTarget(self, action: #selector(onRemoveTap), for: .touchUpInside)

        keyField.addTarget(self, action: #selector(onKeyEditingChanged), for: .editingChanged)
        valueField.addTarget(self, action: #selector(onValueEditingChanged), for: .editingChanged)

        let hStack = UIStackView(arrangedSubviews: [keyField, valueField, removeButton])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            removeButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(
        key: String,
        value: String,
        onKeyChange: @escaping (String) -> Void,
        onValueChange: @escaping (String) -> Void,
        onRemove: @escaping () -> Void
    ) {
        keyField.text = key
        valueField.text = value
        self.onKeyChange = onKeyChange
        self.onValueChange = onValueChange
        self.onRemove = onRemove
    }

    @objc private func onKeyEditingChanged() {
        onKeyChange?(keyField.text ?? "")
    }

    @objc private func onValueEditingChanged() {
        onValueChange?(valueField.text ?? "")
    }

    @objc private func onRemoveTap() {
        onRemove?()
    }
}
