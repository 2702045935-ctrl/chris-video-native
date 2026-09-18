//  LoginView.swift
//  抖音那套注册/登录：手机号+验证码（未注册自动注册）→ 设置昵称 → 选兴趣 → 进首页

import SwiftUI

struct LoginView: View {
    @ObservedObject var auth = Auth.shared
    @Binding var finished: Bool
    @State private var step = 0            // 0 登录 1 昵称 2 兴趣
    @State private var phone = ""
    @State private var code = ""
    @State private var agreed = false
    @State private var canResend = false
    @State private var countdown = 0
    @State private var showAgreement = false
    @State private var shake = false
    @State private var nickname = ""
    @State private var picked: Set<String> = []
    @FocusState private var focus: Int?

    private var phoneOK: Bool {
        phone.count == 11 && phone.hasPrefix("1") && Int(phone) != nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch step {
            case 0: loginStep
            case 1: nicknameStep
            default: interestStep
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await auth.loadConfig()
            nickname = ""
        }
        .sheet(isPresented: $showAgreement) {
            AgreementSheet(version: auth.config?.agreementVersion ?? "v1")
        }
    }

    /* MARK: - 第 1 步：登录 */

    private var loginStep: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    auth.guest = true
                    finished = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("登录后可以")
                    .font(pf(26, .bold))
                    .foregroundColor(.white)
                Text("点赞、评论、关注，还能把你的喜好告诉推荐算法")
                    .font(pf(14))
                    .foregroundColor(Color(white: 0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 10)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("+86")
                        .font(pf(17, .medium))
                        .foregroundColor(.white)
                    TextField("", text: $phone)
                        .placeholder(when: phone.isEmpty) {
                            Text("请输入手机号").foregroundColor(Color(white: 0.4))
                        }
                        .font(pf(17))
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .focused($focus, equals: 0)
                        .onChange(of: phone) { v in
                            phone = String(v.filter { $0.isNumber }.prefix(11))
                            if phone.count == 11 { focus = 1 }
                        }
                }
                .frame(height: 56)
                Divider().background(Color(white: 0.16))
                HStack(spacing: 10) {
                    TextField("", text: $code)
                        .placeholder(when: code.isEmpty) {
                            Text("请输入验证码").foregroundColor(Color(white: 0.4))
                        }
                        .font(pf(17))
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .focused($focus, equals: 1)
                        .onChange(of: code) { v in
                            code = String(v.filter { $0.isNumber }.prefix(6))
                            if code.count == 6 { submit() }          // 输满 6 位自动登录（抖音就是这样）
                        }
                    Button {
                        sendCode()
                    } label: {
                        Text(canResend ? "重新获取" : (countdown > 0 ? "\(countdown)s" : "获取验证码"))
                            .font(pf(14, .medium))
                            .foregroundColor(phoneOK ? Theme.primary : Color(white: 0.35))
                    }
                    .disabled(!phoneOK || countdown > 0)
                }
                .frame(height: 56)
            }
            .padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.1)))
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .offset(x: shake ? -8 : 0)
            .animation(.default, value: shake)

            Button {
                if !agreed {
                    shake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { shake = false }
                    auth.lastError = "请先阅读并同意《用户协议》和《隐私政策》"
                    return
                }
                submit()
            } label: {
                Text(auth.busy ? "登录中…" : "登录 / 注册")
                    .font(pf(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Theme.primary))
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            Button {
                oneKey()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "iphone")
                    Text("本机号码一键登录")
                }
                .font(pf(15, .medium))
                .foregroundColor(Color(white: 0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 23).fill(Color(white: 0.16)))
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            if !auth.lastError.isEmpty {
                Text(auth.lastError)
                    .font(pf(12.5))
                    .foregroundColor(Color(red: 1, green: 0.35, blue: 0.4))
                    .padding(.top, 10)
            }

            Spacer()

            HStack(spacing: 26) {
                thirdButton("wechat", "微信", "message.fill")
                thirdButton("qq", "QQ", "bubble.left.fill")
                thirdButton("weibo", "微博", "globe.asia.australia.fill")
                thirdButton("apple", "Apple", "apple.logo")
            }
            .padding(.bottom, 12)

            HStack(spacing: 4) {
                Button {
                    agreed.toggle()
                } label: {
                    Image(systemName: agreed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundColor(agreed ? Theme.primary : Color(white: 0.4))
                }
                Text("我已阅读并同意")
                    .font(pf(11.5))
                    .foregroundColor(Color(white: 0.45))
                Button { showAgreement = true } label: {
                    Text("《用户协议》《隐私政策》")
                        .font(pf(11.5))
                        .foregroundColor(Theme.primary)
                }
            }
            .padding(.bottom, 26)
        }
    }

    private func thirdButton(_ provider: String, _ name: String, _ icon: String) -> some View {
        Button {
            if !agreed {
                auth.lastError = "请先阅读并同意《用户协议》和《隐私政策》"
                return
            }
            auth.guest = false
            Task { if await auth.third(provider, agreed: agreed) { afterLogin() } }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(white: 0.8))
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color(white: 0.13)))
                Text(name)
                    .font(pf(11))
                    .foregroundColor(Color(white: 0.5))
            }
        }
    }

    /* MARK: - 第 2 步：设置昵称 */

    private var nicknameStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("设置你的昵称")
                .font(pf(24, .bold))
                .foregroundColor(.white)
            Text("抖音号：" + (auth.user?.douyinId ?? ""))
                .font(pf(13))
                .foregroundColor(Color(white: 0.5))

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(white: 0.16)).frame(width: 72, height: 72)
                    AvatarView(name: auth.user?.avatar ?? "")
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                }
                TextField("", text: $nickname)
                    .placeholder(when: nickname.isEmpty) {
                        Text("起个名字").foregroundColor(Color(white: 0.4))
                    }
                    .font(pf(17))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
            }
            .padding(.top, 6)

            Text("昵称和头像后面可以在「我 → 编辑资料」里改")
                .font(pf(12.5))
                .foregroundColor(Color(white: 0.45))

            Spacer()

            Button {
                Task {
                    if await auth.setProfile(nickname: nickname.isEmpty ? auth.user?.name : nickname, avatar: nil) {
                        step = 2
                    } else {
                        step = 2   // 保存失败也让进，别卡住用户
                    }
                }
            } label: {
                Text("进入下一步")
                    .font(pf(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Theme.primary))
            }
        }
        .padding(24)
    }

    /* MARK: - 第 3 步：选兴趣（推荐冷启动） */

    private var interestStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("选择你感兴趣的")
                .font(pf(24, .bold))
                .foregroundColor(.white)
            Text("至少选 3 个，用来给你推荐内容（后面根据你的行为自动调整）")
                .font(pf(13))
                .foregroundColor(Color(white: 0.5))

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 10)], spacing: 10) {
                    ForEach(auth.config?.interestTags ?? ["美食", "旅行", "搞笑", "萌宠", "生活", "音乐", "游戏", "影视"], id: \.self) { tag in
                        let on = picked.contains(tag)
                        Button {
                            if on { picked.remove(tag) } else { picked.insert(tag) }
                        } label: {
                            Text(tag)
                                .font(pf(14, on ? .semibold : .regular))
                                .foregroundColor(on ? .white : Color(white: 0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(on ? Theme.primary : Color(white: 0.12)))
                        }
                    }
                }
                .padding(.top, 6)
            }

            Button {
                Task {
                    _ = await auth.setInterests(Array(picked))
                    finished = true
                }
            } label: {
                Text(picked.count >= 3 ? "完成，开始刷视频" : "再选 \(3 - picked.count) 个")
                    .font(pf(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 24)
                        .fill(picked.count >= 3 ? Theme.primary : Color(white: 0.2)))
            }
            .disabled(picked.count < 3)

            Button {
                finished = true
            } label: {
                Text("跳过")
                    .font(pf(13.5))
                    .foregroundColor(Color(white: 0.45))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
    }

    /* MARK: - 动作 */

    private func sendCode() {
        guard phoneOK else { return }
        Task {
            if let r = await auth.sendCode(phone) {
                guard r.ok == true else { return }
                focus = 1
                countdown = 60
                canResend = false
                // 本地自用：没有短信通道，验证码直接提示出来
                if let c = r.code { auth.lastError = "验证码：" + c + "（本地自用，真实项目会发短信）" }
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
                    Task { @MainActor in
                        countdown -= 1
                        if countdown <= 0 { t.invalidate(); canResend = true }
                    }
                }
            }
        }
    }

    private func submit() {
        guard phoneOK, code.count == 6, !auth.busy else { return }
        Task {
            if await auth.login(phone: phone, code: code, agreed: agreed) {
                afterLogin()
            }
        }
    }

    private func oneKey() {
        if !agreed {
            auth.lastError = "请先阅读并同意《用户协议》和《隐私政策》"
            return
        }
        Task {
            if await auth.oneKey(agreed: agreed) { afterLogin() }
        }
    }

    private func afterLogin() {
        auth.guest = false
        let new = auth.user?.isNew == true || auth.user?.profileComplete == false
        step = new ? 1 : 3
        if !new { finished = true }
    }
}

/// 协议正文（简版）
struct AgreementSheet: View {
    let version: String
    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("用户协议与隐私政策")
                        .font(pf(18, .semibold))
                        .foregroundColor(.white)
                    Text("版本 " + version)
                        .font(pf(12))
                        .foregroundColor(Color(white: 0.45))
                    ForEach(paragraphs, id: \.self) { p in
                        Text(p)
                            .font(pf(13.5))
                            .foregroundColor(Color(white: 0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var paragraphs: [String] {
        [
            "1. 这是本地自用的演示服务，账号数据只存在你自己电脑上的 data/users.json 里，不会上传到任何第三方。",
            "2. 登录用手机号 + 验证码；本机没有短信通道，验证码会直接显示在页面上（也固定接受 123456）。",
            "3. 未注册的手机号在验证通过后会自动创建账号，这与抖音的逻辑一致。",
            "4. 我们会记录你的浏览、点赞、评论、关注等行为，用于给你做个性化推荐；这些数据同样只存在本地。",
            "5. 你可以随时在「我」里退出登录；后台「数据清理」可以清空账号、行为、推荐数据。",
            "6. 头像、昵称、兴趣标签都可以随时修改。"
        ]
    }
}
