//
//  CoinImageCache.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/29/25.
//

import Foundation
import UIKit

final class CoinImageCache {
    private let cache = NSCache<NSString, UIImage>() // UIImage 캐싱
    private let fileManager = FileManager.default
    private let directory: URL

    static let shared = CoinImageCache()

    private init() {
        // 앱 내 저장 디렉토리 설정 (Caches 폴더 사용)
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        directory = paths[0].appendingPathComponent("CoinImages")

        // 폴더 생성 (없으면)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /// **이미지 가져오기**
    func getImage(for symbol: String) -> UIImage? {
        let key = symbol.uppercased() as NSString

        // 1. 메모리 캐시 확인
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }

        // 2. 디스크 캐시 확인
        let fileURL = directory.appendingPathComponent("\(symbol).png")
        if let image = UIImage(contentsOfFile: fileURL.path) {
            cache.setObject(image, forKey: key) // 메모리 캐시에 저장
            return image
        }

        return nil // 캐시 없음
    }

    /// **이미지 저장**
    func setImage(for symbol: String, image: UIImage) {
        let key = symbol.uppercased() as NSString
        cache.setObject(image, forKey: key) // 메모리 캐시에 저장

        // 디스크에 저장
        let fileURL = directory.appendingPathComponent("\(symbol).png")
        if let data = image.pngData() {
            try? data.write(to: fileURL)
        }
    }
}
