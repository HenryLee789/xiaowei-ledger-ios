# BeanLedger / 小魏记账簿

BeanLedger 是一个原生 SwiftUI iOS 记账 App，用户可见中文名称为“小魏记账簿”。项目当前已完成 UI、真实本地数据逻辑、语义色系统、AppIcon 和未签名 ipa 打包流程。

内部 target、scheme 和部分文件名仍保留 `BeanLedger`，这样可以避免为了改名造成构建不稳定。

## 功能列表

- 新增记账，支持金额、备注、日期、一级类型和二级类目
- 首页快速记账，支持常用金额和常用类目预填
- 新增记账页备注提示，会根据历史同类目备注优先推荐
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

项目采用奶油黄 / 粉色可爱风：粉白背景、大圆角卡片、胶囊按钮、轻柔小票卡片、蝴蝶结、豆豆和 SF Symbols 图标。

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

JSON 文件由 App 自动加载和保存。新增、删除、清空记录后会自动写入本地 JSON。

新增功能还会保存以下本地 JSON 文件：

- 预算：`Documents/BeanLedgerBudgets.json`
- 周期账单模板：`Documents/BeanLedgerRecurringTemplates.json`

预算和周期模板与账本记录分开保存，不会改变 `BeanLedgerRecords.json` 的记录结构。

## 新增功能使用

### 快速记账

首页“快速记账”卡片里选择常用金额和常用类目，再点“快速记一笔”。App 会打开现有“记一笔小账”页面，并自动填入金额、类型和类目；确认后仍保存为普通 `LedgerRecord`。

### 备注提示

在“记一笔小账”页面输入备注时，下方会出现历史备注胶囊标签。推荐来自历史记录，空备注不会展示，同类目备注优先，最近使用过的备注优先，最多显示 5 个。点一下标签即可填入备注。

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

源码继续维护在 `main` 分支。每次功能迭代完成后，会先更新源码和文档并推送到 `main`，再创建版本 tag，例如 `v1.0.0`、`v1.1.0`、`v1.2.0`。

每个正式版本的安装包放在 GitHub Releases，不直接提交进源码仓库。`CHANGELOG.md` 记录每个版本的更新内容，GitHub Release Notes 会同步写明本次更新内容和安装说明。

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

默认项目不内置 Hello Kitty 官方素材。Assets 中预留了以下资源位，方便本地自行替换：

- `hello_kitty_mascot`
- `hello_kitty_bow`
- `hello_kitty_icon`

如自行添加 Hello Kitty 图片，仅建议个人自用。公开分发、上传 GitHub、商业使用或上架 App Store 前，请自行确认授权。

## 常见问题

### 未签名 ipa 能直接安装吗？

不能。未签名 ipa 需要经过自签工具重新签名后才能安装到真机。

### 构建时提示签名问题怎么办？

阶段 4 的 Release 构建使用 `CODE_SIGNING_ALLOWED=NO` 生成未签名产物。如果你要在 Xcode 里直接真机运行，需要配置自己的 Apple 开发者账号、证书和描述文件。

### 自签后打不开或安装失败怎么办？

请检查 Bundle Identifier、证书、描述文件、设备 UDID、最低 iOS 版本是否匹配。当前项目最低 iOS 版本为 16.0。

### JSON 数据会同步 iCloud 吗？

不会。当前数据只保存在 App 沙盒 Documents 目录。

## 已知限制

- 未签名 ipa 不能直接安装到真机
- 自签需要用户自己的证书、描述文件和自签工具
- 导出 JSON 使用系统文件导出面板，不同自动化环境可能无法稳定捕捉系统面板画面
- 角色素材如果公开分发、上传 GitHub、商业使用或上架 App Store，需要自行确认授权
