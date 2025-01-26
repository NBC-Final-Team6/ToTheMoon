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
        
        /// 일반 폰트 반환
        func regular() -> UIFont {
            return UIFont.systemFont(ofSize: self.size)
        }
        
        /// 굵은 폰트 반환
        func bold() -> UIFont {
            return UIFont.systemFont(ofSize: self.size, weight: .bold)
        }
    }
}

// UIFont의 커스텀 속성 추가
extension UIFont {
    static var extraLarge: FontType {
        return .extraLarge
    }
    
    static var large: FontType {
        return .large
    }
    
    static var medium: FontType {
        return .medium
    }
    
    static var small: FontType {
        return .small
    }
    
    static var extraSmall: FontType {
        return .extraSmall
    }
}
