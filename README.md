# BeanLedger / 小魏记账簿

BeanLedger 是一个原生 SwiftUI iOS 记账 App，用户可见中文名称为“小魏记账簿”。项目当前已完成 UI、真实本地数据逻辑、语义色系统、AppIcon 和未签名 ipa 打包流程。

内部 target、scheme 和部分文件名仍保留 `BeanLedger`，这样可以避免为了改名造成构建不稳定。

## 功能列表

- 新增记账，支持金额、备注、日期、一级类型和二级类目
- 首页快速记账，支持常用金额和常用类目预填
- AI 记账助手，支持自然语言解析单笔或多笔账单、确认后保存和手动调整
- 新增记账页备注提示，会根据历史同类目备注优先推荐
- 每笔账可选上传记录图片；未上传时自动显示可爱风格类目小图
- 一级类型：出账、入账、攒豆豆、借贷
- 首页统计：今日出账、今日入账、本月出账、本月入账、攒豆豆累计、借贷净额
- 全部记录页：月份、类型、类目、关键词、金额范围、日期范围、排序组合筛选，支持左滑删除
- 统计页：本月一级类型统计、出账/入账二级类目统计、攒豆豆和借贷净额统计、本月趋势
- 预算功能：本月总预算、出账分类预算、预算进度和超预算提示
- 定时记账：周期账单模板，到期后手动确认生成真实记录
- 收支日历：按月查看每天出账、入账和当天账目列表
- JSON 本地持久化，App 重启后数据保留
- 设置页支持导出 JSON、导出 CSV 和清空全部数据确认
- URL Scheme：`beanledger://add` 可快速打开“记一笔小账”弹窗

## UI 说明

项目采用奶油黄 / 粉色可爱风：粉白背景、大圆角卡片、胶囊按钮、轻柔小票卡片、豆豆和 SF Symbols 图标。

账目类型使用统一语义色：

- 出账：黄色，表示钱流出
- 入账：蓝色，表示钱流入
- 攒豆豆：粉紫色，表示存钱 / 储蓄
- 借贷：紫色，表示借入借出 / 负债往来

金额显示规则：

- 出账：`-¥金额`
- 入账：`+¥金额`
- 攒豆豆：`+¥金额`
- 借贷：借入、收回借款为正向；借出、还款、信用卡、花呗 / 白条为负向；其他借贷保持中性金额

## AppIcon 说明

AppIcon 使用本地提供的可爱女孩拿账本图片生成，已经处理为 iOS 适配图标：

- 标准正方形 PNG
- 无透明背景
- 不包含 App 名称文字
- 去掉外圈黄色描边框
- 人物主体约占画布宽度 74%，四周保留安全边距
- iOS 系统负责圆角裁切，图标本身不手动画圆角边框

原始图标素材备份在：

`Resources/xiaowei_app_icon_source.png`

## 数据存储

账本数据保存到 App 沙盒 Documents 目录：

`Documents/BeanLedgerRecords.json`

JSON 文件由 App 自动加载和保存。新增、删除、清空记录后会自动写入本地 JSON。如果检测到 JSON 文件损坏，App 会把原文件备份为 `.corrupt-时间戳`，不会用空数据静默覆盖损坏文件。

新增功能还会保存以下本地 JSON 文件：

- 预算：`Documents/BeanLedgerBudgets.json`
- 周期账单模板：`Documents/BeanLedgerRecurringTemplates.json`

用户上传的账目图片会压缩保存到：

`Documents/BeanLedgerRecordImages/`

账本 JSON 只保存图片文件名。未上传图片的记录不会写入图片文件，界面会按账目类型和类目自动显示可爱风格小图。

预算和周期模板与账本记录分开保存，账目图片也单独保存，不会把大图片写进 `BeanLedgerRecords.json`。

AI 设置中的 API Base URL、备用 Base URL、模型名称和主备切换偏好保存在本机 UserDefaults。API Key 优先保存到 iOS Keychain，不会写入账本 JSON、导出 JSON、README、测试数据或截图。

设置页的“清空全部数据”会同时清除账本记录、预算、周期账单模板、记录图片、AI 设置和 API Key。

## 新增功能使用

### 快速记账

首页“快速记账”卡片里选择常用金额和常用类目，再点“快速记一笔”。App 会打开现有“记一笔小账”页面，并自动填入金额、类型和类目；确认后仍保存为普通 `LedgerRecord`。

### AI 记账助手

首页“快速记账”附近新增“AI 记一笔”。进入“AI 记账助手”后，可以直接输入自然语言，例如：

- `早餐包子豆浆12`
- `午饭花了28`
- `地铁通勤6`
- `工资到账8500`
- `工资8500，午饭28，打车42.8`

点击“解析账单”后，App 会调用用户自己配置的 OpenAI 兼容接口，把自然语言解析为金额、类型、类目、备注、日期和置信度。如果一句话里包含多笔独立账单，App 会按发生顺序展示多张确认记录，例如工资入账和外卖出账会分成两笔。解析结果会先展示为确认卡片，用户必须点击“确认记账”或“确认记账 N 笔”才会写入本地 `LedgerRecord`。如果需要修改，可以点单笔记录里的“调整”进入原来的“记一笔小账”页面；点“先不记”则不会保存。

AI 会尽量把类目映射到 App 已有类目。App 仍会在本地二次校验：金额必须大于 0，类型必须是出账 / 入账 / 攒豆豆 / 借贷，类目不合法时会回退到对应“其他”类目，备注过长会截断，日期解析失败时会使用当前时间。

### AI 设置

设置页新增“AI 设置”模块：

- API Base URL 默认留空，用户需要填写自己的 OpenAI 兼容接口地址，例如 `https://api.openai.com/v1`
- 备用 Base URL 默认留空，且“主地址失败后自动使用备用地址”默认关闭
- Base URL 必须使用 `https://`，避免 API Key 和账单文本通过明文 HTTP 发送
- API Key 由用户自行填写，App 默认不内置 API Key
- 模型名称可以手动输入
- 如果接口支持 `GET /models`，可以点“拉取模型列表”后选择模型
- 如果模型列表拉取失败，页面会显示错误，并继续允许手动输入模型名
- “主地址失败后自动使用备用地址”开启时，解析请求会在主地址失败后重试一次备用地址，不会无限重试

AI 接口按 OpenAI Chat Completions 兼容格式调用：

- 解析路径：`{baseURL}/chat/completions`
- 模型列表：`{baseURL}/models`
- Header 使用用户填写的 `Authorization: Bearer <API Key>`

DEBUG 构建中有“开发 Mock 解析”开关，默认关闭，只用于没有真实 API Key 时本地验证界面流程。它不是正式 AI 功能。

### AI 隐私和安全

AI 记账会把用户输入的自然语言发送到用户配置的 API 服务。请不要在自然语言输入或备注里写身份证号、银行卡号、完整地址、密码等敏感信息。

App 默认不内置 API Key，Release 包也不包含用户 API Key。API Key 当前保存到 iOS Keychain；如果未来为了兼容性临时改为 UserDefaults，需要在文档中明确说明 UserDefaults 不适合保存高度敏感密钥，并尽快迁回 Keychain。GitHub 仓库不要提交 API Key。

### 备注提示

在“记一笔小账”页面输入备注时，下方会出现历史备注胶囊标签。推荐来自历史记录，空备注不会展示，同类目备注优先，最近使用过的备注优先，最多显示 5 个。点一下标签即可填入备注。

### 记录图片

在“记一笔小账”页面可以给这笔账上传一张图片。保存后，首页最近记录和全部记录列表会显示用户上传的图片。如果没有上传图片，App 会根据账目类型和二级类目自动显示一张奶油黄 / 粉色可爱风小图。

### 趋势统计

统计页新增“本月趋势”，可切换查看出账趋势和入账趋势。出账使用黄色，入账使用蓝色。模块下方会显示本月最高单日出账、平均每日出账和本月记账天数。

### 预算

统计页“更多小工具”进入“预算”。可以设置本月总预算，也可以给出账分类设置预算。预算只统计出账，不统计入账、攒豆豆和借贷。进度接近 80% 会提示，超过预算会用柔和红色提醒。

### 定时记账

统计页“更多小工具”进入“定时记账”。创建周期账单模板后，App 启动或回到前台会检查是否到期。到期后会显示待确认列表，只有点击“生成记录”才会新增真实账目；也可以跳过本次或关闭模板。

### 收支日历

统计页“更多小工具”进入“收支日历”。日历支持上个月 / 下个月切换，有记录的日期会显示轻量标记，并展示当天出账和入账小计。点击某一天可以查看当天账目列表。

### 高级搜索

全部记录页搜索框支持备注、类型名称、二级类目和金额搜索。还可以组合使用月份、类型、类目、金额范围、日期范围和排序。页面会显示筛选结果数量，以及筛选后的出账合计、入账合计、攒豆豆合计和借贷净额。

### JSON / CSV 导出

设置页“数据工具”里保留“导出 JSON 数据”，并新增“导出 CSV 数据”。导出文件名包含日期，例如：

- `小魏记账簿_账本导出_2026-07-05.json`
- `小魏记账簿_账本导出_2026-07-05.csv`

CSV 字段包含 `id`、`amount`、`signedAmount`、`type`、`typeName`、`category`、`note`、`date`、`createdAt`，并使用 UTF-8 with BOM，方便 Excel 打开中文。

## 打开项目

用 Xcode 打开：

```sh
open BeanLedger.xcodeproj
```

当前 scheme：

`BeanLedger`

最低支持：

`iOS 16.0`

## 修改 Bundle Identifier

当前 Bundle Identifier：

`com.henry.BeanLedger`

如需改成自己的标识，请在 Xcode 中打开 target `BeanLedger` 的 Signing & Capabilities，修改 Bundle Identifier。也可以直接修改：

`BeanLedger.xcodeproj/project.pbxproj`

搜索 `PRODUCT_BUNDLE_IDENTIFIER` 后替换为你的 Bundle ID。

## 在 Simulator 运行

可用 Xcode 直接选择 iPhone Simulator 后运行，也可以使用命令：

```sh
xcodebuild build -project BeanLedger.xcodeproj -scheme BeanLedger -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 版本发布与安装包

源码继续维护在 `main` 分支。每次功能迭代完成后，会先更新源码和文档并推送到 `main`，再创建版本 tag，例如 `v1.0.0`、`v1.1.0`、`v1.2.0`、`v1.3.0`、`v1.3.1`。

每个正式版本的安装包放在 GitHub Releases，不直接提交进源码仓库。每次上传或发版前都必须更新 `CHANGELOG.md`，记录本次版本更新内容；GitHub Release Notes 会同步写明本次更新内容和安装说明。

如果只是开发调试，可以用 Xcode 直接打开 `BeanLedger.xcodeproj` 并运行到 Simulator。

如果要安装到手机，可以下载对应 GitHub Release 附件里的 ipa。当前发布流程生成的是未签名 ipa，不能直接安装到 iPhone，需要使用你自己的自签工具重新签名后再安装。

## 打包 ipa

本项目可生成未签名 ipa，目录结构为标准 ipa：

```text
Build/
  Payload/
    BeanLedger.app
  XiaoWeiLedger-unsigned.ipa
```

阶段 4 使用的 Release 构建方式：

```sh
xcodebuild clean -project BeanLedger.xcodeproj -scheme BeanLedger -configuration Release
xcodebuild build -project BeanLedger.xcodeproj -scheme BeanLedger -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

然后将 `Release-iphoneos/BeanLedger.app` 放入 `Payload` 并压缩成 ipa。

## 自签安装

`Build/XiaoWeiLedger-unsigned.ipa` 是未签名 ipa，不能直接安装到真机。

你需要使用自己的自签工具、证书和描述文件重新签名后再安装。常见流程是：

1. 将 `Build/XiaoWeiLedger-unsigned.ipa` 导入自签工具
2. 选择自己的证书和描述文件
3. 确认 Bundle Identifier 与描述文件匹配
4. 重新签名生成可安装 ipa
5. 安装到 iPhone

如果你的自签工具更适合处理 `.app`，也可以使用 Release 构建出的 `BeanLedger.app` 作为输入。

## URL Scheme

已注册：

`beanledger://add`

用途：

- App 未启动时，通过 URL 打开 App 并弹出“记一笔小账”
- App 已启动时，也可以触发新增记账弹窗
- 可配合 iOS 快捷指令使用

Simulator 测试命令示例：

```sh
xcrun simctl openurl booted beanledger://add
```

## 角色素材与授权

项目保留 `hello_kitty_mascot` 角色素材资源位，用于显示本地 HelloKitty 图片。

独立的双花瓣资源位已移除，避免界面再出现单独的双花瓣图案。

如自行添加第三方图片，请在公开分发、上传 GitHub、商业使用或上架 App Store 前确认授权。

## 常见问题

### 未签名 ipa 能直接安装吗？

不能。未签名 ipa 需要经过自签工具重新签名后才能安装到真机。

### 构建时提示签名问题怎么办？

阶段 4 的 Release 构建使用 `CODE_SIGNING_ALLOWED=NO` 生成未签名产物。如果你要在 Xcode 里直接真机运行，需要配置自己的 Apple 开发者账号、证书和描述文件。

### 自签后打不开或安装失败怎么办？

请检查 Bundle Identifier、证书、描述文件、设备 UDID、最低 iOS 版本是否匹配。当前项目最低 iOS 版本为 16.0。

### JSON 数据会同步 iCloud 吗？

不会。当前数据只保存在 App 沙盒 Documents 目录。

### AI 为什么不能解析？

常见原因是没有填写 API Key、没有填写模型名称、API 服务不可用、模型返回的内容不是 JSON，或者用户输入里缺少金额 / 类型等关键信息。缺少金额时 App 会提示补充金额，不会保存记录。

### 为什么提示未选择模型？

AI 设置里的“模型名称”为空时会出现这个提示。可以手动输入模型名；如果接口支持 `GET /models`，也可以先点“拉取模型列表”再选择模型。

### 为什么 API 失败？

请检查 API Base URL、API Key、模型名称和网络连接。备用 Base URL 是可选项；如果填写备用地址并开启“主地址失败后自动使用备用地址”，App 会在主地址失败后重试一次备用地址。如果未填写 API Base URL，App 会提示先去 AI 设置里配置。

### 为什么 AI 不自动保存？

AI 可能识别错金额、类型、类目或日期，所以 App 不会让 AI 静默写入账本。所有 AI 解析结果都必须先展示确认卡片，用户点“确认记账”后才会保存为本地 `LedgerRecord`。

## 已知限制

- 未签名 ipa 不能直接安装到真机
- 自签需要用户自己的证书、描述文件和自签工具
- 导出 JSON 使用系统文件导出面板，不同自动化环境可能无法稳定捕捉系统面板画面
- 角色素材如果公开分发、上传 GitHub、商业使用或上架 App Store，需要自行确认授权
- 没有真实 API Key 时，正式 AI 接口无法联网验证；DEBUG Mock 只能验证本地界面和确认保存流程
