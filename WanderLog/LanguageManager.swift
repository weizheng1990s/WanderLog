import Foundation
import SwiftUI

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese  = "zh-Hans"
    case english            = "en"
    case japanese           = "ja"
    case korean             = "ko"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simplifiedChinese:  return "简体中文"
        case .english:            return "English"
        case .japanese:           return "日本語"
        case .korean:             return "한국어"
        case .traditionalChinese: return "繁體中文"
        }
    }
}

// MARK: - LanguageManager

class LanguageManager: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        language = AppLanguage(rawValue: saved) ?? .simplifiedChinese
    }

    var s: Strings { Strings(lang: language) }
}

// MARK: - Strings

struct Strings {
    let lang: AppLanguage

    // MARK: Common
    var cancel: String         { pick("取消",    "Cancel",      "キャンセル",        "취소",           "取消") }
    var save: String           { pick("保存",    "Save",        "保存",              "저장",           "儲存") }
    var close: String          { pick("关闭",    "Close",       "閉じる",            "닫기",           "關閉") }
    var delete: String         { pick("删除",    "Delete",      "削除",              "삭제",           "刪除") }
    var edit: String           { pick("编辑",    "Edit",        "編集",              "편집",           "編輯") }
    var all: String            { pick("全部",    "All",         "すべて",            "전체",           "全部") }
    var add: String            { pick("添加",    "Add",         "追加",              "추가",           "新增") }
    var ok: String             { pick("好",      "OK",          "OK",                "확인",           "好") }
    var city: String           { pick("城市",    "City",        "都市",              "도시",           "城市") }
    var country: String        { pick("国家",    "Country",     "国",                "국가",           "國家") }
    var cities: String         { pick("城市",    "Cities",      "都市",              "도시",           "城市") }
    var countries: String      { pick("国家",    "Countries",   "国",                "국가",           "國家") }

    // MARK: Tab Bar
    var tabHome: String        { pick("首页",    "Home",        "ホーム",            "홈",             "首頁") }
    var tabMap: String         { pick("地图",    "Map",         "マップ",            "지도",           "地圖") }
    var tabCollection: String  { pick("收藏",    "Collections", "コレクション",      "컬렉션",         "收藏") }
    var tabProfile: String     { pick("我的",    "Profile",     "プロフィール",      "프로필",         "我的") }

    // MARK: Home
    var homeCheckIns: String   { pick("打卡",    "Check-ins",   "チェックイン",      "체크인",         "打卡") }
    var homeNoEntries: String  { pick("还没有打卡记录", "No entries yet", "まだ記録なし", "기록이 없습니다", "尚無打卡記錄") }
    var homeNoEntriesHint: String { pick("点击下方 + 开始记录你的第一个探店", "Tap + below to log your first spot", "下の + をタップして最初のスポットを記録", "아래 + 버튼으로 첫 기록을 시작해보세요", "點擊下方 + 開始記錄第一個探店") }

    // MARK: Add Entry
    var newEntry: String       { pick("新建打卡",  "New Entry",      "新規記録",         "새 기록",       "新建打卡") }
    var editEntry: String      { pick("编辑打卡",  "Edit Entry",     "記録を編集",       "기록 편집",     "編輯打卡") }
    var photos: String         { pick("照片",      "Photos",         "写真",             "사진",          "照片") }
    var category: String       { pick("类型",      "Category",       "カテゴリ",         "카테고리",      "類型") }
    var location: String       { pick("位置",      "Location",       "場所",             "위치",          "位置") }
    var addressPlaceholder: String { pick("输入城市名称/粘贴Google地址", "Enter city or Google address", "都市名またはGoogle住所を入力", "도시명 또는 구글 주소 입력", "輸入城市名稱/貼上Google地址") }
    var locating: String       { pick("定位中...", "Locating...",    "位置取得中...",    "위치 확인 중...", "定位中...") }
    var autoLocate: String     { pick("自动定位",  "Auto-locate",    "自動定位",         "자동 위치",     "自動定位") }
    var coordinateObtained: String { pick("已获取坐标，将显示在地图上", "Coordinates obtained, will show on map", "座標取得済み、地図に表示されます", "좌표 확인, 지도에 표시됩니다", "已獲取座標，將顯示在地圖上") }
    var name: String           { pick("名称",      "Name",           "名前",             "이름",          "名稱") }
    var shopNamePlaceholder: String { pick("店名", "Shop name",      "店舗名",           "상호명",        "店名") }
    var visitDate: String      { pick("探访日期",  "Visit Date",     "訪問日",           "방문 날짜",     "探訪日期") }
    var rating: String         { pick("评分",      "Rating",         "評価",             "평점",          "評分") }
    var myNotes: String        { pick("我的感受",  "My Notes",       "メモ",             "메모",          "我的感受") }
    var notesPlaceholder: String { pick("写下你的感受，只给自己看...", "Write your thoughts, just for you...", "あなたの気持ちを書いてください...", "나만의 기록을 남겨보세요...", "寫下你的感受，只給自己看...") }
    var saveFailed: String     { pick("保存失败",  "Save Failed",    "保存失敗",         "저장 실패",     "儲存失敗") }

    // MARK: Entry Detail
    var deleteEntryTitle: String   { pick("删除这条打卡？", "Delete this entry?", "この記録を削除しますか？", "이 기록을 삭제하시겠습니까?", "刪除這條打卡？") }
    var deleteEntryMessage: String { pick("此操作无法撤销，照片也会一并删除。", "This action cannot be undone. Photos will also be deleted.", "この操作は取り消せません。写真も削除されます。", "이 작업은 취소할 수 없습니다. 사진도 함께 삭제됩니다.", "此操作無法撤銷，照片也會一並刪除。") }
    var myNotesLabel: String   { pick("我的笔记",  "My Notes",       "メモ",             "메모",          "我的筆記") }
    var mood: String           { pick("心情",      "Mood",           "気分",             "기분",          "心情") }

    // MARK: Collection
    var collectionTitle: String { pick("收藏",     "Collections",    "コレクション",     "컬렉션",        "收藏") }
    var byCategory: String     { pick("品类",      "Category",       "カテゴリ",         "카테고리",      "品類") }
    var byCountry: String      { pick("国家",      "Country",        "国",               "국가",          "國家") }
    var favorites: String      { pick("收藏",      "Favorites",      "お気に入り",       "즐겨찾기",      "收藏") }
    var emptyCountryHint: String { pick("打卡时填写城市/国家，就能在这里看到", "Fill in city/country when logging to see them here", "記録時に都市・国を入力するとここに表示されます", "기록할 때 도시/국가를 입력하면 여기에 표시됩니다", "打卡時填寫城市/國家，就能在這裡看到") }
    var emptyFavoritesHint: String { pick("在打卡详情页点击书签，收藏你最爱的地方", "Bookmark entries to save your favorites", "詳細画面でブックマークしてお気に入りを保存", "상세 화면에서 북마크를 탭해 즐겨찾기 저장", "在打卡詳情頁點擊書籤，收藏你最愛的地方") }
    func seeAll(_ count: Int) -> String { pick("查看全部 \(count) 条", "See all \(count)", "すべて見る (\(count))", "전체 보기 (\(count))", "查看全部 \(count) 條") }
    func entriesCount(_ count: Int) -> String { pick("\(count) 个打卡", "\(count) entries", "\(count) 件", "\(count) 개", "\(count) 個打卡") }

    // MARK: Map
    var mapTitle: String       { pick("地图",      "Map",            "マップ",           "지도",          "地圖") }
    var noMapEntries: String   { pick("暂无地图打卡", "No map entries", "地図の記録なし", "지도 기록 없음", "暫無地圖打卡") }
    var noMapEntriesHint: String { pick("打卡时开启定位，记录就会出现在地图上", "Enable location when logging to show on map", "記録時に位置情報をオンにすると地図に表示されます", "기록 시 위치를 활성화하면 지도에 표시됩니다", "打卡時開啟定位，記錄就會出現在地圖上") }

    // MARK: Profile
    var profileTitle: String   { pick("我的手账",  "My Journal",     "マイ手帳",         "나의 여행 노트", "我的手帳") }
    var profileTagline: String { pick("记录每一个值得被记住的角落", "Capture every corner worth remembering", "記憶に残る場所を記録しよう", "기억할 가치 있는 모든 공간을 기록하세요", "記錄每一個值得被記住的角落") }
    var totalCheckIns: String  { pick("打卡总数",  "Total",          "合計",             "전체",          "打卡總數") }
    var categoryBreakdown: String { pick("品类分布", "By Category",   "カテゴリ別",       "카테고리별",    "品類分佈") }
    func visitedCountries(_ count: Int) -> String { pick("去过的国家 · \(count)", "Countries · \(count)", "訪問国 · \(count)", "방문 국가 · \(count)", "去過的國家 · \(count)") }
    var storage: String        { pick("存储",       "Storage",        "ストレージ",       "저장소",        "儲存") }
    var photoStorage: String   { pick("照片占用空间", "Photo Storage", "写真のストレージ", "사진 저장소",   "照片佔用空間") }
    var privacyNote: String    { pick("所有数据仅保存在本设备，不上传任何服务器", "All data is stored on this device only", "すべてのデータはデバイスにのみ保存されます", "모든 데이터는 이 기기에만 저장됩니다", "所有數據僅保存在本設備，不上傳任何伺服器") }
    var exportBackup: String   { pick("导出备份",   "Export Backup",  "バックアップを書き出す", "백업 내보내기", "匯出備份") }
    var importBackup: String   { pick("导入备份",   "Import Backup",  "バックアップを読み込む", "백업 가져오기", "匯入備份") }
    var aboutWander: String    { pick("关于 WANDER", "About WANDER", "WANDERについて",   "WANDER 정보",   "關於 WANDER") }

    // MARK: Export
    var exportTitle: String    { pick("备份你的手账", "Backup Your Journal", "手帳をバックアップ", "여행 노트 백업", "備份你的手帳") }
    var exportDesc: String     { pick("导出 .json 文件，包含所有打卡记录\n可通过 AirDrop 或文件 App 迁移到新设备", "Export a .json file with all your entries\nTransfer via AirDrop or Files app", "すべての記録を含む.jsonファイルを書き出します\nAirDropまたはファイルAppで新しいデバイスに転送", "모든 기록이 담긴 .json 파일을 내보냅니다\nAirDrop 또는 파일 앱으로 새 기기에 전송", "匯出 .json 檔案，包含所有打卡記錄\n可透過 AirDrop 或檔案 App 遷移到新裝置") }
    func exportEntriesCount(_ count: Int) -> String { pick("\(count) 条打卡记录", "\(count) entries", "\(count) 件の記録", "\(count) 개의 기록", "\(count) 條打卡記錄") }
    func exportPhotoSize(_ size: String) -> String  { pick("照片占用 \(size)", "Photos: \(size)", "写真: \(size)", "사진: \(size)", "照片佔用 \(size)") }
    var exportButton: String   { pick("导出备份",   "Export",         "書き出す",         "내보내기",      "匯出備份") }

    // MARK: Import
    var importTitle: String    { pick("还原你的手账", "Restore Your Journal", "手帳を復元",  "여행 노트 복원", "還原你的手帳") }
    var importDesc: String     { pick("选择之前导出的 .json 备份文件\n已有记录不会重复导入", "Select a previously exported .json backup\nExisting entries won't be duplicated", "以前に書き出した.jsonバックアップを選択\n既存の記録は重複しません", "이전에 내보낸 .json 백업 파일 선택\n기존 기록은 중복되지 않습니다", "選擇之前匯出的 .json 備份檔案\n已有記錄不會重複匯入") }
    var importButton: String   { pick("导入备份",   "Import",         "読み込む",         "가져오기",      "匯入備份") }
    var importErrCannotRead: String  { pick("无法读取文件，请重试", "Cannot read file, please try again", "ファイルを読み取れません、もう一度お試しください", "파일을 읽을 수 없습니다. 다시 시도해주세요", "無法讀取檔案，請重試") }
    var importErrReadFailed: String  { pick("文件读取失败", "File read failed", "ファイル読み取り失敗", "파일 읽기 실패", "檔案讀取失敗") }
    var importErrInvalidFormat: String { pick("格式不正确，请选择 WanderLog 导出的备份文件", "Invalid format, please select a WanderLog backup", "形式が正しくありません。WanderLogのバックアップを選択してください", "올바른 형식이 아닙니다. WanderLog 백업 파일을 선택해주세요", "格式不正確，請選擇 WanderLog 匯出的備份檔案") }
    var importNoNew: String    { pick("没有新记录可导入", "No new entries to import", "新しい記録はありません", "가져올 새 기록이 없습니다", "沒有新記錄可匯入") }
    func importSuccess(_ count: Int) -> String { pick("成功导入 \(count) 条记录", "Successfully imported \(count) entries", "\(count) 件の記録を読み込みました", "\(count) 개의 기록을 가져왔습니다", "成功匯入 \(count) 條記錄") }

    // MARK: About
    var appSubtitle: String    { pick("全球探店电子手账", "Global Shop Diary", "グローバル探店ダイアリー", "글로벌 탐방 다이어리", "全球探店電子手帳") }
    func version(_ v: String) -> String { pick("版本 \(v)", "Version \(v)", "バージョン \(v)", "버전 \(v)", "版本 \(v)") }
    var aboutPrivacy1: String  { pick("所有数据仅保存在你的设备", "All data stays on your device", "すべてのデータはデバイスに保存", "모든 데이터는 기기에 저장", "所有數據僅保存在你的裝置") }
    var aboutPrivacy2: String  { pick("完全离线可用", "Works fully offline", "完全オフライン対応", "완전 오프라인 지원", "完全離線可用") }
    var aboutPrivacy3: String  { pick("无账号，无追踪，无广告", "No account, no tracking, no ads", "アカウント不要、追跡なし、広告なし", "계정 없음, 추적 없음, 광고 없음", "無帳號，無追蹤，無廣告") }
    var about: String          { pick("关于",       "About",          "について",         "정보",          "關於") }

    // MARK: Helper
    private func pick(_ zh: String, _ en: String, _ ja: String, _ ko: String, _ zht: String) -> String {
        switch lang {
        case .simplifiedChinese:  return zh
        case .english:            return en
        case .japanese:           return ja
        case .korean:             return ko
        case .traditionalChinese: return zht
        }
    }
}

// MARK: - PlaceCategory Localization

extension PlaceCategory {
    func localizedName(lang: AppLanguage) -> String {
        switch lang {
        case .simplifiedChinese: return rawValue
        case .english:
            switch self {
            case .cafe: return "Café"; case .museum: return "Museum"; case .bookstore: return "Bookstore"
            case .bar: return "Bar"; case .gallery: return "Gallery"; case .selectShop: return "Select Shop"
            case .restaurant: return "Restaurant"; case .other: return "Other"
            }
        case .japanese:
            switch self {
            case .cafe: return "カフェ"; case .museum: return "博物館"; case .bookstore: return "本屋"
            case .bar: return "バー"; case .gallery: return "ギャラリー"; case .selectShop: return "セレクトショップ"
            case .restaurant: return "レストラン"; case .other: return "その他"
            }
        case .korean:
            switch self {
            case .cafe: return "카페"; case .museum: return "박물관"; case .bookstore: return "서점"
            case .bar: return "바"; case .gallery: return "갤러리"; case .selectShop: return "셀렉샵"
            case .restaurant: return "레스토랑"; case .other: return "기타"
            }
        case .traditionalChinese:
            switch self {
            case .cafe: return "咖啡館"; case .museum: return "博物館"; case .bookstore: return "書店"
            case .bar: return "酒吧"; case .gallery: return "展覽 / 美術館"; case .selectShop: return "買手店"
            case .restaurant: return "餐廳"; case .other: return "其他"
            }
        }
    }
}

// MARK: - Mood Localization

extension Mood {
    func localizedLabel(lang: AppLanguage) -> String {
        switch lang {
        case .simplifiedChinese: return label
        case .english:
            switch self {
            case .loved: return "Loved"; case .relaxed: return "Relaxed"; case .amazed: return "Amazed"
            case .neutral: return "Neutral"; case .tired: return "Tired"
            }
        case .japanese:
            switch self {
            case .loved: return "大好き"; case .relaxed: return "癒し"; case .amazed: return "感動"
            case .neutral: return "普通"; case .tired: return "疲れた"
            }
        case .korean:
            switch self {
            case .loved: return "사랑해"; case .relaxed: return "힐링"; case .amazed: return "감동"
            case .neutral: return "보통"; case .tired: return "피곤"
            }
        case .traditionalChinese:
            switch self {
            case .loved: return "很愛"; case .relaxed: return "療癒"; case .amazed: return "震撼"
            case .neutral: return "一般"; case .tired: return "疲憊"
            }
        }
    }
}
