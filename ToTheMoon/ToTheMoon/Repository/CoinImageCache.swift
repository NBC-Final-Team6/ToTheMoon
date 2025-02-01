//
//  CoinImageCache.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/29/25.
//

import Foundation
import UIKit

final class CoinImageCache {
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let directory: URL

    static let shared = CoinImageCache()

    private init() {
        // 앱 내 저장 디렉토리 설정 (Caches 폴더 사용)
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        directory = paths[0].appendingPathComponent("CoinImages")

        // 폴더 생성 (없으면)
        do {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("❌ [ERROR] 이미지 캐시 디렉토리 생성 실패: \(error.localizedDescription)")
        }
    }

    /// **이미지 가져오기**
    func getImage(for coinID: String) -> UIImage? {
        let key = coinID.lowercased() as NSString

        // 1️⃣ 메모리 캐시 확인
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }

        // 2️⃣ 디스크 캐시 확인 (파일 존재 여부 체크)
        let fileURL = directory.appendingPathComponent("\(coinID.lowercased()).png")
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("❌ [CACHE MISS] 디스크에 이미지 없음: \(coinID)")
            return nil
        }

        do {
            let imageData = try Data(contentsOf: fileURL)
            if let image = UIImage(data: imageData) {
                cache.setObject(image, forKey: key) // 메모리 캐시에 저장
                //print("✅ [CACHE] 디스크에서 이미지 로드 성공: \(coinID)")
                return image
            }
        } catch {
            print("❌ [ERROR] 디스크에서 이미지 로드 실패: \(error.localizedDescription)")
        }

        return nil // 캐시 없음
    }

    /// **이미지 저장**
    func setImage(for coinID: String, image: UIImage) {
        let key = coinID.lowercased() as NSString
        cache.setObject(image, forKey: key) // 메모리 캐시에 저장

        // 디스크에 저장
        let fileURL = directory.appendingPathComponent("\(coinID.lowercased()).png")
        do {
            if let data = image.pngData() {
                try data.write(to: fileURL)
            } else {
                print("❌ [ERROR] 이미지 PNG 변환 실패: \(coinID)")
            }
        } catch {
            print("❌ [ERROR] 디스크에 이미지 저장 실패: \(error.localizedDescription)")
        }
    }
}
