import UIKit
import SnapKit

class FavoritesView: UIView {
    // UI Components
    let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "ToTheMoon"
        label.textColor = .text
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["인기 화폐", "관심 목록"])
        control.selectedSegmentIndex = 1 // 기본 선택된 탭 (관심 목록)
        control.backgroundColor = .darkGray
        control.selectedSegmentTintColor = .systemTeal
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        return control
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "rocketImage"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let noFavoritesLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 관심 등록된 코인이 없습니다."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    let suggestionLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 시세에서 관심있는 코인을 추가해 보세요."
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("코인 추가하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemTeal
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
        backgroundColor = .black
        
        // Add subviews
        addSubview(logoLabel)
        addSubview(searchButton)
        addSubview(segmentedControl)
        addSubview(imageView)
        addSubview(noFavoritesLabel)
        addSubview(suggestionLabel)
        addSubview(addButton)
        
        // Layout using SnapKit
        logoLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(16)
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
        
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(segmentedControl.snp.bottom).offset(30)
            make.width.height.equalTo(150)
        }
        
        noFavoritesLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        suggestionLabel.snp.makeConstraints { make in
            make.top.equalTo(noFavoritesLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.top.equalTo(suggestionLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
}
