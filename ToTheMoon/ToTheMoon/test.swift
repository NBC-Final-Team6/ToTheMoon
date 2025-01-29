//
//  test.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/29/25.
//

//
//  ViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift

class test: UIViewController {
    
    private let symbolService = SymbolService()
    private let disposeBag = DisposeBag()
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImageView() // 이미지뷰 UI 설정
        test() // ✅ 테스트 실행
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func test() {
        print("🔍 [TEST] 비트코인 이미지 요청 시작...")
        
        symbolService.fetchCoinThumbImage(coinSymbol: "mpl")
            .observe(on: MainScheduler.instance) // ✅ UI 업데이트를 메인 스레드에서 실행
            .subscribe(onSuccess: { [weak self] image in
                guard let self = self else { return }
                
                if let image = image {
                    print("✅ [TEST] 비트코인 이미지 다운로드 성공!")
                    self.imageView.image = image // ✅ 화면에 이미지 표시
                } else {
                    print("❌ [TEST] 비트코인 이미지 없음!")
                }
            }, onFailure: { error in
                print("❌ [TEST ERROR] 이미지 요청 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag) // ✅ 메모리 누수 방지
    }
}
