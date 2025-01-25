import UIKit
import SnapKit

class FavoritesView: UIView {
   
    let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "ToTheMoon"
        label.textColor = .text
        label.font = .large
        return label
    }()
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .text
        return button
    }()
    
    let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["인기 화폐", "관심 목록"])
        control.selectedSegmentIndex = 1
        control.backgroundColor = .container
        control.selectedSegmentTintColor = .personel
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.text,
            .font: UIFont.medium
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.text,
            .font: UIFont.medium
        ]
        control.setTitleTextAttributes(normalAttributes, for: .normal)
        control.setTitleTextAttributes(selectedAttributes, for: .selected)
        return control
    }()
    
    let sortStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    let sortLabel: UILabel = {
        let label = UILabel()
        label.text = "전체 0"
        label.textColor = .text
        label.font = .medium
        return label
    }()

    let sortToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("인기순 ▼", for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.font = .medium
        return button
    }()

    @objc private func toggleDropdown() {
        if sortToggleButton.title(for: .normal) == "인기순 ▼" {
            sortToggleButton.setTitle("인기순 ▲", for: .normal)
        } else {
            sortToggleButton.setTitle("인기순 ▼", for: .normal)
        }
    }
    
    let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "moon.fill"))
        imageView.tintColor = .personel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let noFavoritesLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 관심 등록된 코인이 없습니다. \n현재 시세에서 관심있는 코인을 추가해 보세요."
        label.textColor = .text
        label.font = .medium
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("코인 추가하기", for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.backgroundColor = .personel
        button.layer.cornerRadius = 10
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .background
        
        // Add subviews
        addSubview(logoLabel)
        addSubview(searchButton)
        addSubview(segmentedControl)
        addSubview(sortStackView)
        sortStackView.addArrangedSubview(sortLabel)
        sortStackView.addArrangedSubview(sortToggleButton)
        addSubview(imageView)
        addSubview(noFavoritesLabel)
        addSubview(addButton)
        
        // Layout using SnapKit
        logoLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }
        
        searchButton.snp.makeConstraints { make in
            make.centerY.equalTo(logoLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(logoLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        sortStackView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        // Add action to toggle button
        sortToggleButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(sortStackView.snp.bottom).offset(30)
            make.width.height.equalTo(150)
        }
        
        noFavoritesLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.top.equalTo(noFavoritesLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
}
