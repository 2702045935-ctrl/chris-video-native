//  Auth.swift
//  账号体系：手机号+验证码（未注册自动注册）/ 一键登录 / 第三方登录 + token 登录态

import Foundation
import SwiftUI

struct AuthUser: Codable {
    var id: String
    var name: String
    var avatar: String?
    var douyinId: String?
    var bio: String?
    var phone: String?
    var city: String?
    var interests: [String]?
    var profileComplete: Bool?
    var isNew: Bool?
    var followCount: Int?
    var fanCount: Int?
    var likeTotal: Int?
    var verified: Bool?
    var loginCount: Int?
    var provider: String?
}

struct AuthResult: Codable {
    var ok: Bool?
    var isNew: Bool?
    var token: String?
    var user: AuthUser?
    var error: String?
    var needAgreement: Bool?
    var notLoggedIn: Bool?
    var phone: String?
    var interests: [String]?
}

struct SendCodeResult: Codable {
    var ok: Bool?
    var error: String?
    var phone: String?
    var code: String?
    var universalCode: String?
    var expireIn: Int?
    var resendIn: Int?
}

struct AuthConfig: Codable {
    var agreementVersion: String?
    var universalCode: String?
    var providers: [String]?
    var interestTags: [String]?
}

@MainActor
final class Auth: ObservableObject {
    static let shared = Auth()

    @Published var user: AuthUser?
    @Published var config: AuthConfig?
    @Published var busy = false
    @Published var lastError = ""
    /// 游客模式：没登录也能刷，点赞评论时才要求登录
    @Published var guest = false

    private let tokenKey = "chris_video_token"

    var token: String {
        get { UserDefaults.standard.string(forKey: tokenKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    var isLoggedIn: Bool { user != nil }

    var deviceId: String {
        let key = "chris_video_device"
        if let d = UserDefaults.standard.string(forKey: key) { return d }
        let d = UUID().uuidString
        UserDefaults.standard.set(d, forKey: key)
        return d
    }

    func loadConfig() async {
        if config != nil { return }
        config = try? await Api.get("/api/auth/config", as: AuthConfig.self)
    }

    /// 启动时用本地 token 恢复登录态
    func restore() async {
        guard !token.isEmpty else { return }
        if let r = try? await Api.get("/api/auth/me", as: AuthResult.self), r.ok == true {
            user = r.user
        } else {
            token = ""
        }
    }

    func sendCode(_ phone: String) async -> SendCodeResult? {
        busy = true
        defer { busy = false }
        do {
            let r = try await Api.post("/api/auth/send-code", body: ["phone": phone], as: SendCodeResult.self)
            lastError = r.error ?? ""
            return r
        } catch {
            lastError = "网络不好，稍后再试"
            return nil
        }
    }

    func login(phone: String, code: String, agreed: Bool) async -> Bool {
        busy = true
        defer { busy = false }
        do {
            let r = try await Api.post("/api/auth/login",
                                       body: ["phone": phone, "code": code, "agreed": agreed,
                                              "deviceId": deviceId],
                                       as: AuthResult.self)
            if let t = r.token { token = t }
            user = r.user
            lastError = r.error ?? ""
            return r.ok == true
        } catch {
            lastError = "登录失败，检查一下服务器地址"
            return false
        }
    }

    func oneKey(agreed: Bool) async -> Bool {
        busy = true
        defer { busy = false }
        do {
            let r = try await Api.post("/api/auth/onekey", body: ["deviceId": deviceId, "agreed": agreed],
                                       as: AuthResult.self)
            if let t = r.token { token = t }
            user = r.user
            lastError = r.error ?? ""
            return r.ok == true
        } catch {
            lastError = "一键登录失败"
            return false
        }
    }

    func third(_ provider: String, agreed: Bool) async -> Bool {
        busy = true
        defer { busy = false }
        do {
            let r = try await Api.post("/api/auth/third",
                                       body: ["provider": provider, "deviceId": deviceId,
                                              "openid": provider + "_" + deviceId, "agreed": agreed],
                                       as: AuthResult.self)
            if let t = r.token { token = t }
            user = r.user
            lastError = r.error ?? ""
            return r.ok == true
        } catch {
            lastError = "第三方登录失败"
            return false
        }
    }

    @discardableResult
    func setProfile(nickname: String?, avatar: String?) async -> Bool {
        var body: [String: Any] = ["token": token]
        if let n = nickname { body["nickname"] = n }
        if let a = avatar { body["avatar"] = a }
        do {
            let r = try await Api.post("/api/auth/profile", body: body, as: AuthResult.self)
            if r.ok == true { user = r.user }
            lastError = r.error ?? ""
            return r.ok == true
        } catch {
            lastError = "保存失败"
            return false
        }
    }

    @discardableResult
    func setInterests(_ tags: [String]) async -> Bool {
        do {
            let r = try await Api.post("/api/auth/interests",
                                       body: ["token": token, "tags": tags], as: AuthResult.self)
            lastError = r.error ?? ""
            if r.ok == true, var u = user {
                u.interests = r.interests
                u.profileComplete = true
                user = u
            }
            return r.ok == true
        } catch {
            lastError = "保存兴趣失败"
            return false
        }
    }

    func logout() async {
        _ = try? await Api.post("/api/auth/logout", body: ["token": token], as: AuthResult.self)
        token = ""
        user = nil
    }
}
