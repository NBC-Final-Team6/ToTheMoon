//
//  Font.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/25/25.
//

import UIKit.UIFont

extension UIFont {
    enum FontType {
        case extraLarge
        case large
        case medium
        case small
        case extraSmall
        
        /// 각 타입에 맞는 폰트 크기 반환 (4의 배수)
        var size: CGFloat {
            switch self {
            case .extraLarge: return 32 // 4 * 8
            case .large: return 24     // 4 * 6
            case .medium: return 16    // 4 * 4
            case .small: return 12     // 4 * 3
            case .extraSmall: return 8 // 4 * 2
            }
        }
        
        /// 각 타입에 맞는 폰트 반환
        var font: UIFont {
            return UIFont.systemFont(ofSize: self.size) // 시스템 기본 폰트 사용
        }
    }
}

// UIFont의 커스텀 속성 추가
extension UIFont {
    static var extraLarge: UIFont {
        return FontType.extraLarge.font
    }
    
    static var large: UIFont {
        return FontType.large.font
    }
    
    static var medium: UIFont {
        return FontType.medium.font
    }
    
    static var small: UIFont {
        return FontType.small.font
    }
    
    static var extraSmall: UIFont {
        return FontType.extraSmall.font
    }
}
