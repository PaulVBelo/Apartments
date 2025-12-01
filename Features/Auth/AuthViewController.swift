import UIKit

final class AuthViewController: UIViewController {

    // MARK: - Dependencies
    private let api: APIClient
    init(api: APIClient) {
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIView()

    private let card = UIView()
    private let titleLabel = UILabel()

    // labels (новое)
    private let headerLabel = UILabel()
    private let emailLabel = UILabel()
    private let passwordLabel = UILabel()
    private let confirmLabel = UILabel()

    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let confirmField = UITextField()

    private let primaryButton = UIButton(type: .system)      // enter / create account
    private let switchModeButton = UIButton(type: .system)   // register / back to login

    private let spinner = UIActivityIndicatorView(style: .medium)

    // MARK: - State
    private enum Mode { case login, register }
    private var mode: Mode = .login { didSet { updateForMode(animated: true) } }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        layoutUI()
        updateForMode(animated: false)
    }

    // MARK: - Actions
    @objc private func primaryTapped() {
        view.endEditing(true)
        setLoading(true)

        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let pass  = passwordField.text ?? ""
        let conf  = confirmField.text ?? ""

        switch mode {
        case .login:
            guard isLikelyEmail(email), (8...16).contains(pass.count) else {
                setLoading(false); showAlert("Check email and password (8–16 chars)."); return
            }
            Task {
                do {
                    let dto = try await api.login(email: email, password: pass)
                    AppState.shared.userId = dto.user_id
                    setLoading(false)
                    
                    RootSwitcher.toMain()
                } catch {
                    setLoading(false); showAlert(userMessage(from: error))
                }
            }

        case .register:
            guard isLikelyEmail(email) else {
                setLoading(false); showAlert("Invalid email format."); return
            }
            guard (8...16).contains(pass.count) else {
                setLoading(false); showAlert("Password must be 8–16 chars."); return
            }
            guard pass == conf else {
                setLoading(false); showAlert("Passwords do not match."); return
            }
            Task {
                do {
                    try await api.register(email: email, password: pass)
                    setLoading(false)
                    showAlert("Registered. Now sign in.")
                    mode = .login
                } catch {
                    setLoading(false); showAlert(userMessage(from: error))
                }
            }
        }
    }

    @objc private func switchModeTapped() {
        mode = (mode == .login) ? .register : .login
    }

    // MARK: - UI setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 64/255, green: 165/255, blue: 207/255, alpha: 1)

        headerLabel.text = "BOOKING ADVISOR"
        headerLabel.textColor = .white
        headerLabel.textAlignment = .center
        headerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 28)
        view.addSubview(headerLabel)
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(content)
        
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        content.addSubview(card)
        
        titleLabel.text = "Login"
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        card.addSubview(titleLabel)
        
        // labels
        emailLabel.text = "email"
        passwordLabel.text = "password"
        confirmLabel.text = "confirm password"
        [emailLabel, passwordLabel, confirmLabel].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .medium)
            $0.textColor = .secondaryLabel
            card.addSubview($0)
        }

        // fields
        [emailField, passwordField, confirmField].forEach { tf in
            tf.borderStyle = .none
            tf.layer.cornerRadius = 10
            tf.layer.borderColor = UIColor.systemGray4.cgColor
            tf.layer.borderWidth = 1
            tf.backgroundColor = .white
            tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
            tf.leftViewMode = .always
            tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        // email
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.placeholder = "e-mail: example@site.com"
        emailField.textContentType = .username

        // passwords — убираем Strong Password overlay
        [passwordField, confirmField].forEach { tf in
            tf.isSecureTextEntry = true
            tf.textContentType = .password
            tf.autocorrectionType = .no
            tf.smartQuotesType = .no
            tf.smartDashesType = .no
            tf.spellCheckingType = .no
        }
        passwordField.placeholder = "password"
        confirmField.placeholder = "confirm password"

        [emailField, passwordField, confirmField].forEach { card.addSubview($0) }

        primaryButton.setTitle("enter", for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        primaryButton.backgroundColor = .systemTeal
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.layer.cornerRadius = 12
        primaryButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        card.addSubview(primaryButton)

        switchModeButton.setTitle("register", for: .normal)
        switchModeButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        switchModeButton.setTitleColor(.systemBlue, for: .normal)
        switchModeButton.addTarget(self, action: #selector(switchModeTapped), for: .touchUpInside)
        card.addSubview(switchModeButton)

        spinner.hidesWhenStopped = true
        card.addSubview(spinner)
    }

    private func layoutUI() {
        [headerLabel, scroll, content, card, titleLabel,
         emailLabel, emailField,
         passwordLabel, passwordField,
         confirmLabel, confirmField,
         primaryButton, switchModeButton, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            scroll.topAnchor.constraint(equalTo: headerLabel.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),

            card.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor, constant: 32),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            // email
            emailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            emailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            emailField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 6),
            emailField.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            emailField.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),

            // password
            passwordLabel.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 14),
            passwordLabel.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            passwordLabel.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),

            passwordField.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 6),
            passwordField.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),

            // confirm
            confirmLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 14),
            confirmLabel.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            confirmLabel.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),

            confirmField.topAnchor.constraint(equalTo: confirmLabel.bottomAnchor, constant: 6),
            confirmField.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            confirmField.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),

            primaryButton.topAnchor.constraint(equalTo: confirmField.bottomAnchor, constant: 20),
            primaryButton.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),

            switchModeButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: 10),
            switchModeButton.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor),
            switchModeButton.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16),

            spinner.centerXAnchor.constraint(equalTo: primaryButton.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor),
        ])
    }

    private func updateForMode(animated: Bool) {
        let apply = {
            switch self.mode {
            case .login:
                self.titleLabel.text = "Login"
                self.primaryButton.setTitle("enter", for: .normal)
                self.switchModeButton.setTitle("register", for: .normal)
                self.confirmField.isHidden = true
                self.confirmLabel.isHidden = true
            case .register:
                self.titleLabel.text = "Register"
                self.primaryButton.setTitle("create account", for: .normal)
                self.switchModeButton.setTitle("back to login", for: .normal)
                self.confirmField.isHidden = false
                self.confirmLabel.isHidden = false
            }
            self.view.layoutIfNeeded()
        }
        animated ? UIView.animate(withDuration: 0.25, animations: apply) : apply()
    }

    private func setLoading(_ isLoading: Bool) {
        [emailField, passwordField, confirmField, primaryButton, switchModeButton].forEach {
            $0.isUserInteractionEnabled = !isLoading
            $0.alpha = isLoading ? 0.6 : 1.0
        }
        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    private func isLikelyEmail(_ s: String) -> Bool {
        s.contains("@") && s.contains(".") && !s.contains(" ")
    }

    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    private func userMessage(from error: Error) -> String {
        if let apiErr = error as? APIError {
            switch apiErr {
            case .badRequest(let message):  return message
            case .conflict(let message):    return message
            case .server(let message):      return "Server error: \(message)"
            case .unknownStatus(let code):  return "Unexpected server response (\(code))."
            }
        }
        return "Something went wrong. Please try again."
    }
}
