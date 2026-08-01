import Foundation
import SwiftUI

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Identifiable {
    case english            = "en"
    case spanish            = "es"
    case french             = "fr"
    case simplifiedChinese  = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese           = "ja"
    case korean             = "ko"
    case arabic             = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:            return "English"
        case .spanish:            return "Español"
        case .french:             return "Français"
        case .simplifiedChinese:  return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese:           return "日本語"
        case .korean:             return "한국어"
        case .arabic:             return "العربية"
        }
    }
}

// MARK: - LanguageManager

class LanguageManager: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
            Self.syncAppleLanguages(language)
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        let lang = AppLanguage(rawValue: saved) ?? Self.preferredSystemLanguage()
        language = lang
        Self.syncAppleLanguages(lang)
    }

    var s: Strings { Strings(lang: language) }

    /// 让 MapKit 瓦片语言跟随 app 语言（AppleLanguages 是 MapKit 确定瓦片语言的依据）
    private static func syncAppleLanguages(_ lang: AppLanguage) {
        let code: String
        switch lang {
        case .english:            code = "en"
        case .spanish:            code = "es"
        case .french:             code = "fr"
        case .simplifiedChinese:  code = "zh-Hans"
        case .traditionalChinese: code = "zh-Hant"
        case .japanese:           code = "ja"
        case .korean:             code = "ko"
        case .arabic:             code = "ar"
        }
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
    }

    private static func preferredSystemLanguage() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalized.hasPrefix("zh-hans") || normalized == "zh-cn" || normalized == "zh-sg" {
                return .simplifiedChinese
            }
            if normalized.hasPrefix("zh-hant") || normalized == "zh-tw" || normalized == "zh-hk" || normalized == "zh-mo" {
                return .traditionalChinese
            }
            if let languageCode = normalized.split(separator: "-").first,
               let language = AppLanguage(rawValue: String(languageCode)) {
                return language
            }
        }
        return .english
    }
}

// MARK: - Strings

struct Strings {
    let lang: AppLanguage

    // MARK: Common
    var cancel: String         { pick("取消",    "Cancel",      "キャンセル",        "취소",           "取消", "Cancelar", "Annuler", "إلغاء") }
    var save: String           { pick("保存",    "Save",        "保存",              "저장",           "儲存", "Guardar", "Enregistrer", "حفظ") }
    var close: String          { pick("关闭",    "Close",       "閉じる",            "닫기",           "關閉", "Cerrar", "Fermer", "إغلاق") }
    var delete: String         { pick("删除",    "Delete",      "削除",              "삭제",           "刪除", "Eliminar", "Supprimer", "حذف") }
    var edit: String           { pick("编辑",    "Edit",        "編集",              "편집",           "編輯", "Editar", "Modifier", "تعديل") }
    var all: String            { pick("全部",    "All",         "すべて",            "전체",           "全部", "Todo", "Tout", "الكل") }
    var add: String            { pick("添加",    "Add",         "追加",              "추가",           "新增", "Añadir", "Ajouter", "إضافة") }
    var ok: String             { pick("好",      "OK",          "OK",                "확인",           "好") }
    var city: String           { pick("城市",    "City",        "都市",              "도시",           "城市", "Ciudad", "Ville", "المدينة") }
    var country: String        { pick("国家",    "Country",     "国",                "국가",           "國家", "País", "Pays", "البلد") }
    var cities: String         { pick("城市",    "Cities",      "都市",              "도시",           "城市", "Ciudades", "Villes", "المدن") }
    var countries: String      { pick("国家",    "Countries",   "国",                "국가",           "國家", "Países", "Pays", "البلدان") }

    // MARK: Tab Bar
    var tabHome: String        { pick("首页",    "Home",        "ホーム",            "홈",             "首頁", "Inicio", "Accueil", "الرئيسية") }
    var tabMap: String         { pick("地图",    "Map",         "マップ",            "지도",           "地圖", "Mapa", "Carte", "الخريطة") }
    var tabCollection: String  { pick("收藏",    "Collections", "コレクション",      "컬렉션",         "收藏", "Colecciones", "Collections", "المجموعات") }
    var tabProfile: String     { pick("我的",    "Profile",     "プロフィール",      "프로필",         "我的", "Perfil", "Profil", "الملف") }

    // MARK: Home
    var homeCheckIns: String   { pick("打卡",    "Check-ins",   "チェックイン",      "체크인",         "打卡", "Registros", "Visites", "تسجيلات") }
    var homeNoEntries: String  { pick("还没有打卡记录", "No entries yet", "まだ記録なし", "기록이 없습니다", "尚無打卡記錄", "Aún no hay entradas", "Aucune entrée pour le moment", "لا توجد إدخالات بعد") }
    var homeNoEntriesHint: String { pick("点击下方 + 开始记录你的第一个探店", "Tap + below to log your first spot", "下の + をタップして最初のスポットを記録", "아래 + 버튼으로 첫 기록을 시작해보세요", "點擊下方 + 開始記錄第一個探店", "Toca + abajo para registrar tu primer lugar", "Touchez + ci-dessous pour enregistrer votre premier lieu", "اضغط + في الأسفل لتسجيل أول مكان") }
    var firstCheckInStart: String { pick("从这里开始第一条打卡", "Start your first check-in here", "ここから最初の記録を始めましょう", "여기서 첫 기록을 시작하세요", "從這裡開始第一條打卡", "Empieza tu primer registro aquí", "Commencez votre première entrée ici", "ابدأ أول تسجيل من هنا") }
    var firstCheckInAddPhoto: String { pick("先添加一张照片", "Add a photo first", "まず写真を追加", "먼저 사진을 추가하세요", "先新增一張照片", "Añade una foto primero", "Ajoutez d'abord une photo", "أضف صورة أولًا") }
    var firstCheckInAutoLocate: String { pick("用自动定位填写城市和国家", "Use auto-locate for city and country", "自動定位で都市と国を入力", "자동 위치로 도시와 국가를 채우세요", "用自動定位填寫城市和國家", "Usa ubicación automática para ciudad y país", "Utilisez la localisation pour la ville et le pays", "استخدم التحديد التلقائي للمدينة والبلد") }
    var firstCheckInNamePlace: String { pick("给这个地方起个名字", "Name this place", "この場所に名前を付けましょう", "이 장소의 이름을 입력하세요", "給這個地方起個名字", "Ponle nombre a este lugar", "Nommez ce lieu", "سم هذا المكان") }
    var firstCheckInSave: String { pick("保存第一条打卡", "Save your first check-in", "最初の記録を保存", "첫 기록 저장", "儲存第一條打卡", "Guarda tu primer registro", "Enregistrez votre première entrée", "احفظ أول تسجيل") }

    // MARK: Add Entry
    var newEntry: String       { pick("新建打卡",  "New Entry",      "新規記録",         "새 기록",       "新建打卡", "Nueva entrada", "Nouvelle entrée", "إدخال جديد") }
    var editEntry: String      { pick("编辑打卡",  "Edit Entry",     "記録を編集",       "기록 편집",     "編輯打卡", "Editar entrada", "Modifier l'entrée", "تعديل الإدخال") }
    var photos: String         { pick("照片",      "Photos",         "写真",             "사진",          "照片", "Fotos", "Photos", "الصور") }
    var category: String       { pick("类型",      "Category",       "カテゴリ",         "카테고리",      "類型", "Categoría", "Catégorie", "الفئة") }
    var location: String       { pick("位置",      "Location",       "場所",             "위치",          "位置", "Ubicación", "Lieu", "الموقع") }
    var addressPlaceholder: String { pick("粘贴Google地址，搜索定位", "Paste Google address, search to locate", "Google住所を貼り付けて検索", "구글 주소를 붙여넣어 검색", "貼上Google地址，搜尋定位", "Pega una dirección de Google para buscar", "Collez une adresse Google pour rechercher", "الصق عنوان Google للبحث") }
    var locating: String       { pick("定位中...", "Locating...",    "位置取得中...",    "위치 확인 중...", "定位中...", "Ubicando...", "Localisation...", "جار تحديد الموقع...") }
    var autoLocate: String     { pick("自动定位",  "Auto-locate",    "自動定位",         "자동 위치",     "自動定位", "Ubicación automática", "Localiser automatiquement", "تحديد تلقائي") }
    var coordinateObtained: String { pick("已获取坐标，将显示在地图上", "Coordinates obtained, will show on map", "座標取得済み、地図に表示されます", "좌표 확인, 지도에 표시됩니다", "已獲取座標，將顯示在地圖上", "Coordenadas obtenidas, aparecerán en el mapa", "Coordonnées obtenues, affichage sur la carte", "تم الحصول على الإحداثيات وستظهر على الخريطة") }
    var name: String           { pick("名称",      "Name",           "名前",             "이름",          "名稱", "Nombre", "Nom", "الاسم") }
    var shopNamePlaceholder: String { pick("店名", "Shop name",      "店舗名",           "상호명",        "店名", "Nombre del lugar", "Nom du lieu", "اسم المكان") }
    var visitDate: String      { pick("探访日期",  "Visit Date",     "訪問日",           "방문 날짜",     "探訪日期", "Fecha de visita", "Date de visite", "تاريخ الزيارة") }
    var rating: String         { pick("评分",      "Rating",         "評価",             "평점",          "評分", "Valoración", "Note", "التقييم") }
    var myNotes: String        { pick("我的感受",  "My Notes",       "メモ",             "메모",          "我的感受", "Mis notas", "Mes notes", "ملاحظاتي") }
    var notesPlaceholder: String { pick("写下你的感受，只给自己看...", "Write your thoughts, just for you...", "あなたの気持ちを書いてください...", "나만의 기록을 남겨보세요...", "寫下你的感受，只給自己看...", "Escribe tus impresiones, solo para ti...", "Écrivez vos impressions, rien que pour vous...", "اكتب انطباعاتك لنفسك فقط...") }
    var saveFailed: String     { pick("保存失败",  "Save Failed",    "保存失敗",         "저장 실패",     "儲存失敗", "Error al guardar", "Échec de l'enregistrement", "فشل الحفظ") }

    // MARK: Entry Detail
    var deleteEntryTitle: String   { pick("删除这条打卡？", "Delete this entry?", "この記録を削除しますか？", "이 기록을 삭제하시겠습니까?", "刪除這條打卡？", "¿Eliminar esta entrada?", "Supprimer cette entrée ?", "حذف هذا الإدخال؟") }
    var deleteEntryMessage: String { pick("此操作无法撤销，照片也会一并删除。", "This action cannot be undone. Photos will also be deleted.", "この操作は取り消せません。写真も削除されます。", "이 작업은 취소할 수 없습니다. 사진도 함께 삭제됩니다.", "此操作無法撤銷，照片也會一並刪除。", "Esta acción no se puede deshacer. Las fotos también se eliminarán.", "Cette action est irréversible. Les photos seront aussi supprimées.", "لا يمكن التراجع عن هذا الإجراء. سيتم حذف الصور أيضًا.") }
    var myNotesLabel: String   { pick("我的笔记",  "My Notes",       "メモ",             "메모",          "我的筆記", "Mis notas", "Mes notes", "ملاحظاتي") }
    var mood: String           { pick("心情",      "Mood",           "気分",             "기분",          "心情", "Ánimo", "Humeur", "المزاج") }

    // MARK: Collection
    var collectionTitle: String { pick("收藏",     "Collections",    "コレクション",     "컬렉션",        "收藏", "Colecciones", "Collections", "المجموعات") }
    var byCategory: String     { pick("品类",      "Category",       "カテゴリ",         "카테고리",      "品類", "Categoría", "Catégorie", "الفئة") }
    var byCountry: String      { pick("国家",      "Country",        "国",               "국가",          "國家", "País", "Pays", "البلد") }
    var favorites: String      { pick("收藏",      "Favorites",      "お気に入り",       "즐겨찾기",      "收藏", "Favoritos", "Favoris", "المفضلة") }
    var emptyCountryHint: String { pick("打卡时填写城市/国家，就能在这里看到", "Fill in city/country when logging to see them here", "記録時に都市・国を入力するとここに表示されます", "기록할 때 도시/국가를 입력하면 여기에 표시됩니다", "打卡時填寫城市/國家，就能在這裡看到", "Añade ciudad/país al registrar para verlo aquí", "Ajoutez une ville/un pays à vos entrées pour les voir ici", "أضف المدينة/البلد عند التسجيل لعرضها هنا") }
    var emptyFavoritesHint: String { pick("在打卡详情页点击书签，收藏你最爱的地方", "Bookmark entries to save your favorites", "詳細画面でブックマークしてお気に入りを保存", "상세 화면에서 북마크를 탭해 즐겨찾기 저장", "在打卡詳情頁點擊書籤，收藏你最愛的地方", "Marca entradas para guardar tus lugares favoritos", "Ajoutez des entrées aux favoris pour garder vos lieux préférés", "ضع علامة مرجعية لحفظ أماكنك المفضلة") }
    func seeAll(_ count: Int) -> String { pick("查看全部 \(count) 条", "See all \(count)", "すべて見る (\(count))", "전체 보기 (\(count))", "查看全部 \(count) 條", "Ver todo (\(count))", "Tout voir (\(count))", "عرض الكل (\(count))") }
    func entriesCount(_ count: Int) -> String { pick("\(count) 个打卡", "\(count) entries", "\(count) 件", "\(count) 개", "\(count) 個打卡", "\(count) entradas", "\(count) entrées", "\(count) إدخال") }

    // MARK: Map
    var mapTitle: String       { pick("地图",      "Map",            "マップ",           "지도",          "地圖", "Mapa", "Carte", "الخريطة") }
    var noMapEntries: String   { pick("暂无地图打卡", "No map entries", "地図の記録なし", "지도 기록 없음", "暫無地圖打卡", "No hay entradas en el mapa", "Aucune entrée sur la carte", "لا توجد إدخالات على الخريطة") }
    var noMapEntriesHint: String { pick("打卡时开启定位，记录就会出现在地图上", "Enable location when logging to show on map", "記録時に位置情報をオンにすると地図に表示されます", "기록 시 위치를 활성화하면 지도에 표시됩니다", "打卡時開啟定位，記錄就會出現在地圖上", "Activa la ubicación al registrar para verlo en el mapa", "Activez la localisation lors de l'ajout pour l'afficher sur la carte", "فعّل الموقع عند التسجيل ليظهر على الخريطة") }

    // MARK: Profile
    var profileTitle: String   { pick("我的手账",  "My Journal",     "マイ手帳",         "나의 여행 노트", "我的手帳", "Mi diario", "Mon carnet", "دفتري") }
    var profileTagline: String { pick("记录每一个值得被记住的角落", "Capture every corner worth remembering", "記憶に残る場所を記録しよう", "기억할 가치 있는 모든 공간을 기록하세요", "記錄每一個值得被記住的角落", "Guarda cada rincón que merece recordarse", "Capturez chaque lieu qui mérite d'être retenu", "سجّل كل زاوية تستحق التذكر") }
    var totalCheckIns: String  { pick("打卡总数",  "Total",          "合計",             "전체",          "打卡總數", "Total", "Total", "الإجمالي") }
    var categoryBreakdown: String { pick("品类分布", "By Category",   "カテゴリ別",       "카테고리별",    "品類分佈", "Por categoría", "Par catégorie", "حسب الفئة") }
    func visitedCountries(_ count: Int) -> String { pick("去过的国家 · \(count)", "Countries · \(count)", "訪問国 · \(count)", "방문 국가 · \(count)", "去過的國家 · \(count)", "Países · \(count)", "Pays · \(count)", "البلدان · \(count)") }
    var storage: String        { pick("存储",       "Storage",        "ストレージ",       "저장소",        "儲存", "Almacenamiento", "Stockage", "التخزين") }
    var photoStorage: String   { pick("照片占用空间", "Photo Storage", "写真のストレージ", "사진 저장소",   "照片佔用空間", "Fotos", "Stockage photos", "تخزين الصور") }
    var privacyNote: String    { pick("所有数据仅保存在本设备，不上传任何服务器", "All data is stored on this device only", "すべてのデータはデバイスにのみ保存されます", "모든 데이터는 이 기기에만 저장됩니다", "所有數據僅保存在本設備，不上傳任何伺服器", "Todos los datos se guardan solo en este dispositivo", "Toutes les données restent uniquement sur cet appareil", "تُحفظ كل البيانات على هذا الجهاز فقط") }
    var exportBackup: String   { pick("导出备份",   "Export Backup",  "バックアップを書き出す", "백업 내보내기", "匯出備份", "Exportar copia", "Exporter la sauvegarde", "تصدير نسخة احتياطية") }
    var importBackup: String   { pick("导入备份",   "Import Backup",  "バックアップを読み込む", "백업 가져오기", "匯入備份", "Importar copia", "Importer une sauvegarde", "استيراد نسخة احتياطية") }
    var copyDeviceID: String   { pick("复制设备 ID", "Copy Device ID", "デバイスIDをコピー", "기기 ID 복사", "複製設備 ID", "Copiar ID del dispositivo", "Copier l'ID de l'appareil", "نسخ معرّف الجهاز") }
    var deviceIDCopied: String { pick("设备 ID 已复制", "Device ID copied", "デバイスIDをコピーしました", "기기 ID가 복사되었습니다", "設備 ID 已複製", "ID del dispositivo copiado", "ID de l'appareil copié", "تم نسخ معرّف الجهاز") }
    var aboutWander: String    { pick("关于 Kiro Book", "About Kiro Book", "Kiro Bookについて", "Kiro Book 정보", "關於 Kiro Book", "Acerca de Kiro Book", "À propos de Kiro Book", "حول Kiro Book") }

    // MARK: Subscription
    var subUpgradeTitle: String { pick("升级你的手账空间", "Upgrade Your Journal", "手帳スペースをアップグレード", "여행 노트 공간 업그레이드", "升級你的手帳空間", "Mejora tu diario", "Améliorer votre carnet", "ترقية دفتر يومياتك") }
    var subUpgradeDesc: String { pick("免费版可记录有限条打卡。升级后可以继续保存更多旅行灵感和地点。", "The free plan includes a limited number of entries. Upgrade to keep saving more places and travel notes.", "無料版で記録できる件数には上限があります。アップグレードすると、さらに多くの場所を保存できます。", "무료 플랜은 기록 수가 제한됩니다. 업그레이드하면 더 많은 장소와 여행 노트를 저장할 수 있습니다.", "免費版可記錄有限條打卡。升級後可以繼續保存更多旅行靈感和地點。", "El plan gratuito incluye un número limitado de entradas. Mejora para guardar más lugares y notas de viaje.", "Le forfait gratuit limite le nombre d'entrées. Passez à une offre supérieure pour enregistrer plus de lieux et de notes.", "تتضمن الخطة المجانية عددًا محدودًا من الإدخالات. قم بالترقية لحفظ المزيد من الأماكن والملاحظات.") }
    var subCurrentPlan: String { pick("当前方案", "Current Plan", "現在のプラン", "현재 플랜", "目前方案", "Plan actual", "Forfait actuel", "الخطة الحالية") }
    var subFreePlan: String { pick("免费版", "Free Plan", "無料プラン", "무료 플랜", "免費版", "Plan gratuito", "Forfait gratuit", "الخطة المجانية") }
    var subAutoUpgrade: String { pick("推荐", "Recommended", "おすすめ", "추천", "推薦", "Recomendado", "Recommandé", "موصى به") }
    var subPriceMonthly: String { pick("/月", "/month", "/月", "/월", "/月", "/mes", "/mois", "/شهر") }
    var subRestore: String { pick("恢复购买", "Restore Purchases", "購入を復元", "구매 복원", "恢復購買", "Restaurar compras", "Restaurer les achats", "استعادة المشتريات") }
    var subManageSubscription: String { pick("订阅", "Subscription", "サブスクリプション", "구독", "訂閱", "Suscripción", "Abonnement", "الاشتراك") }
    var subViewPlans: String { pick("查看订阅方案", "View Subscription Plans", "サブスクリプションプランを見る", "구독 플랜 보기", "查看訂閱方案", "Ver planes de suscripción", "Voir les abonnements", "عرض خطط الاشتراك") }
    var subViewPlansDesc: String { pick("升级后可记录更多打卡", "Upgrade to save more entries", "アップグレードすると、より多くの記録を保存できます", "업그레이드하면 더 많은 기록을 저장할 수 있습니다", "升級後可記錄更多打卡", "Mejora para guardar más entradas", "Passez à une offre supérieure pour enregistrer plus d'entrées", "قم بالترقية لحفظ المزيد من الإدخالات") }
    var subLengthMonthly: String { pick("月度自动续订订阅", "Monthly auto-renewable subscription", "月額自動更新サブスクリプション", "월간 자동 갱신 구독", "月度自動續訂訂閱", "Suscripción mensual renovable automáticamente", "Abonnement mensuel à renouvellement automatique", "اشتراك شهري يتجدد تلقائيًا") }
    var subPrivacyPolicy: String { pick("隐私政策", "Privacy Policy", "プライバシーポリシー", "개인정보 처리방침", "隱私政策", "Política de privacidad", "Politique de confidentialité", "سياسة الخصوصية") }
    var subTermsOfUse: String { pick("使用条款（EULA）", "Terms of Use (EULA)", "利用規約（EULA）", "이용 약관(EULA)", "使用條款（EULA）", "Términos de uso (EULA)", "Conditions d'utilisation (EULA)", "شروط الاستخدام (EULA)") }
    var subManageApple: String { pick("管理 Apple 订阅", "Manage Apple Subscription", "Appleサブスクリプションを管理", "Apple 구독 관리", "管理 Apple 訂閱", "Gestionar suscripción de Apple", "Gérer l'abonnement Apple", "إدارة اشتراك Apple") }
    var subManageAppleDesc: String { pick("在 App Store 中取消或更改订阅", "Cancel or change your subscription in the App Store", "App Storeで解約または変更できます", "App Store에서 구독을 취소하거나 변경할 수 있습니다", "在 App Store 中取消或更改訂閱", "Cancela o cambia tu suscripción en App Store", "Annulez ou modifiez votre abonnement dans l'App Store", "يمكنك إلغاء الاشتراك أو تغييره في App Store") }
    var subAppleActive: String { pick("Apple 订阅已生效", "Apple subscription active", "Appleサブスクリプション有効", "Apple 구독 활성화됨", "Apple 訂閱已生效", "Suscripción de Apple activa", "Abonnement Apple actif", "اشتراك Apple نشط") }
    var subWhitelistActive: String { pick("内测白名单已生效", "Beta whitelist active", "ベータ許可リスト有効", "베타 허용 목록 활성화됨", "內測白名單已生效", "Lista beta activa", "Liste bêta active", "قائمة بيتا مفعلة") }
    func subEntriesUsed(_ used: Int, _ max: Int) -> String {
        if max == Int.max {
            return pick("已用 \(used) 条 · 不限量", "\(used) used · unlimited", "\(used) 件使用中 · 無制限", "\(used)개 사용 · 무제한", "已用 \(used) 條 · 不限量", "\(used) usadas · ilimitado", "\(used) utilisées · illimité", "\(used) مستخدم · غير محدود")
        }
        return pick("已用 \(used) / \(max) 条", "\(used) / \(max) entries used", "\(used) / \(max) 件使用中", "\(used) / \(max)개 사용", "已用 \(used) / \(max) 條", "\(used) / \(max) entradas usadas", "\(used) / \(max) entrées utilisées", "\(used) / \(max) إدخال مستخدم")
    }

    // MARK: Export
    var exportTitle: String    { pick("备份你的手账", "Backup Your Journal", "手帳をバックアップ", "여행 노트 백업", "備份你的手帳", "Copia de tu diario", "Sauvegarder votre carnet", "نسخ دفتر يومياتك احتياطيًا") }
    var exportDesc: String     { pick("导出 .json 文件，包含所有打卡记录\n可通过 AirDrop 或文件 App 迁移到新设备", "Export a .json file with all your entries\nTransfer via AirDrop or Files app", "すべての記録を含む.jsonファイルを書き出します\nAirDropまたはファイルAppで新しいデバイスに転送", "모든 기록이 담긴 .json 파일을 내보냅니다\nAirDrop 또는 파일 앱으로 새 기기에 전송", "匯出 .json 檔案，包含所有打卡記錄\n可透過 AirDrop 或檔案 App 遷移到新裝置", "Exporta un archivo .json con todas tus entradas\nTransfiérelo por AirDrop o Archivos", "Exportez un fichier .json avec toutes vos entrées\nTransférez-le via AirDrop ou Fichiers", "صدّر ملف .json يحتوي على كل الإدخالات\nانقله عبر AirDrop أو تطبيق الملفات") }
    func exportEntriesCount(_ count: Int) -> String { pick("\(count) 条打卡记录", "\(count) entries", "\(count) 件の記録", "\(count) 개의 기록", "\(count) 條打卡記錄", "\(count) entradas", "\(count) entrées", "\(count) إدخال") }
    func exportPhotoSize(_ size: String) -> String  { pick("照片占用 \(size)", "Photos: \(size)", "写真: \(size)", "사진: \(size)", "照片佔用 \(size)", "Fotos: \(size)", "Photos : \(size)", "الصور: \(size)") }
    var exportButton: String   { pick("导出备份",   "Export",         "書き出す",         "내보내기",      "匯出備份", "Exportar", "Exporter", "تصدير") }

    // MARK: Import
    var importTitle: String    { pick("还原你的手账", "Restore Your Journal", "手帳を復元",  "여행 노트 복원", "還原你的手帳", "Restaurar tu diario", "Restaurer votre carnet", "استعادة دفتر يومياتك") }
    var importDesc: String     { pick("选择之前导出的 .json 备份文件\n已有记录不会重复导入", "Select a previously exported .json backup\nExisting entries won't be duplicated", "以前に書き出した.jsonバックアップを選択\n既存の記録は重複しません", "이전에 내보낸 .json 백업 파일 선택\n기존 기록은 중복되지 않습니다", "選擇之前匯出的 .json 備份檔案\n已有記錄不會重複匯入", "Selecciona una copia .json exportada\nLas entradas existentes no se duplicarán", "Sélectionnez une sauvegarde .json exportée\nLes entrées existantes ne seront pas dupliquées", "اختر نسخة .json تم تصديرها\nلن تتكرر الإدخالات الموجودة") }
    var importButton: String   { pick("导入备份",   "Import",         "読み込む",         "가져오기",      "匯入備份", "Importar", "Importer", "استيراد") }
    var importErrCannotRead: String  { pick("无法读取文件，请重试", "Cannot read file, please try again", "ファイルを読み取れません、もう一度お試しください", "파일을 읽을 수 없습니다. 다시 시도해주세요", "無法讀取檔案，請重試", "No se puede leer el archivo. Inténtalo de nuevo", "Impossible de lire le fichier. Réessayez", "تعذرت قراءة الملف، حاول مرة أخرى") }
    var importErrReadFailed: String  { pick("文件读取失败", "File read failed", "ファイル読み取り失敗", "파일 읽기 실패", "檔案讀取失敗", "Error al leer el archivo", "Échec de lecture du fichier", "فشلت قراءة الملف") }
    var importErrInvalidFormat: String { pick("格式不正确，请选择 KiroBook 导出的备份文件", "Invalid format, please select a KiroBook backup", "形式が正しくありません。KiroBookのバックアップを選択してください", "올바른 형식이 아닙니다. KiroBook 백업 파일을 선택해주세요", "格式不正確，請選擇 KiroBook 匯出的備份檔案", "Formato no válido. Selecciona una copia de KiroBook", "Format invalide. Sélectionnez une sauvegarde KiroBook", "تنسيق غير صالح، اختر نسخة احتياطية من KiroBook") }
    var importNoNew: String    { pick("没有新记录可导入", "No new entries to import", "新しい記録はありません", "가져올 새 기록이 없습니다", "沒有新記錄可匯入", "No hay entradas nuevas para importar", "Aucune nouvelle entrée à importer", "لا توجد إدخالات جديدة للاستيراد") }
    func importSuccess(_ count: Int) -> String { pick("成功导入 \(count) 条记录", "Successfully imported \(count) entries", "\(count) 件の記録を読み込みました", "\(count) 개의 기록을 가져왔습니다", "成功匯入 \(count) 條記錄", "\(count) entradas importadas correctamente", "\(count) entrées importées", "تم استيراد \(count) إدخال بنجاح") }

    // MARK: About
    var appSubtitle: String    { pick("全球探店电子手账", "Global Shop Diary", "グローバル探店ダイアリー", "글로벌 탐방 다이어리", "全球探店電子手帳", "Diario global de lugares", "Carnet mondial de lieux", "دفتر عالمي للأماكن") }
    func version(_ v: String) -> String { pick("版本 \(v)", "Version \(v)", "バージョン \(v)", "버전 \(v)", "版本 \(v)", "Versión \(v)", "Version \(v)", "الإصدار \(v)") }
    var aboutPrivacy1: String  { pick("所有数据仅保存在你的设备", "All data stays on your device", "すべてのデータはデバイスに保存", "모든 데이터는 기기에 저장", "所有數據僅保存在你的裝置", "Todos los datos permanecen en tu dispositivo", "Toutes les données restent sur votre appareil", "تبقى كل البيانات على جهازك") }
    var aboutPrivacy2: String  { pick("非打卡定位时，完全离线可用", "Fully offline except when locating check-ins", "チェックイン位置情報の取得時以外は完全オフライン対応", "체크인 위치 확인 시를 제외하고 완전 오프라인 지원", "非打卡定位時，完全離線可用", "Funciona sin conexión salvo al ubicar registros", "Fonctionne hors ligne sauf pour localiser les entrées", "يعمل دون اتصال إلا عند تحديد مواقع الإدخالات") }
    var aboutPrivacy3: String  { pick("无账号，无追踪，无广告", "No account, no tracking, no ads", "アカウント不要、追跡なし、広告なし", "계정 없음, 추적 없음, 광고 없음", "無帳號，無追蹤，無廣告", "Sin cuenta, sin seguimiento, sin anuncios", "Sans compte, sans suivi, sans publicité", "بدون حساب أو تتبع أو إعلانات") }
    var creatorStory: String   { pick("创作者故事", "Creator Story", "クリエイターのストーリー", "크리에이터 스토리", "創作者故事", "Historia del creador", "Histoire du créateur", "قصة المصمم") }
    var about: String          { pick("关于",       "About",          "について",         "정보",          "關於", "Acerca de", "À propos", "حول") }

    // MARK: Icon Picker / Category Editor
    var addCategory: String    { pick("新增类型",   "Add Category",   "カテゴリを追加",   "카테고리 추가",  "新增類型", "Añadir categoría", "Ajouter une catégorie", "إضافة فئة") }
    var editCategory: String   { pick("编辑类型",   "Edit Category",  "カテゴリを編集",   "카테고리 편집",  "編輯類型", "Editar categoría", "Modifier la catégorie", "تعديل الفئة") }
    var categoryNameLabel: String { pick("类型名称", "Category Name",  "カテゴリ名",       "카테고리 이름", "類型名稱", "Nombre de categoría", "Nom de catégorie", "اسم الفئة") }
    var categoryNamePlaceholder: String { pick("输入类型名称", "Enter category name", "カテゴリ名を入力", "카테고리 이름 입력", "輸入類型名稱", "Introduce el nombre", "Saisir le nom", "أدخل اسم الفئة") }
    var preview: String        { pick("预览",       "Preview",        "プレビュー",       "미리보기",       "預覽", "Vista previa", "Aperçu", "معاينة") }
    var selectIcon: String     { pick("选择图标",   "Select Icon",    "アイコンを選択",   "아이콘 선택",    "選擇圖示", "Seleccionar icono", "Choisir une icône", "اختيار أيقونة") }
    var fullscreenView: String  { pick("全屏查看",   "Full Screen",    "全画面",           "전체 화면",      "全螢幕", "Pantalla completa", "Plein écran", "ملء الشاشة") }
    var dragToSort: String      { pick("长按拖拽可排序", "Hold to reorder", "長押しで並べ替え", "길게 눌러 정렬", "長按拖曳可排序", "Mantén pulsado para reordenar", "Appuyez longuement pour réordonner", "اضغط مطولًا لإعادة الترتيب") }

    // MARK: Icon Group Names
    var iconGroupFood: String    { pick("餐饮",  "Food & Drink", "飲食",       "식음료",  "餐飲", "Comida y bebida", "Restauration", "طعام وشراب") }
    var iconGroupCulture: String { pick("文化",  "Culture",      "文化",       "문화",    "文化", "Cultura", "Culture", "ثقافة") }
    var iconGroupShopping: String { pick("购物", "Shopping",     "ショッピング", "쇼핑",   "購物", "Compras", "Shopping", "تسوق") }
    var iconGroupLeisure: String { pick("休闲",  "Leisure",      "レジャー",   "여가",    "休閒", "Ocio", "Loisirs", "ترفيه") }
    var iconGroupPlaces: String  { pick("场所",  "Places",       "場所",       "장소",    "場所", "Lugares", "Lieux", "أماكن") }
    var iconGroupOther: String   { pick("其他",  "Other",        "その他",     "기타",    "其他", "Otros", "Autre", "أخرى") }

    // MARK: Calendar
    var weekdayAbbreviations: [String] {
        switch lang {
        case .simplifiedChinese, .traditionalChinese:
            return ["日","一","二","三","四","五","六"]
        case .english, .spanish, .french:
            return ["Su","Mo","Tu","We","Th","Fr","Sa"]
        case .japanese:
            return ["日","月","火","水","木","金","土"]
        case .korean:
            return ["일","월","화","수","목","금","토"]
        case .arabic:
            return ["ح","ن","ث","ر","خ","ج","س"]
        }
    }

    func calendarLocale() -> Locale {
        switch lang {
        case .simplifiedChinese:  return Locale(identifier: "zh_Hans")
        case .traditionalChinese: return Locale(identifier: "zh_Hant")
        case .english:            return Locale(identifier: "en")
        case .spanish:            return Locale(identifier: "es")
        case .french:             return Locale(identifier: "fr")
        case .japanese:           return Locale(identifier: "ja")
        case .korean:             return Locale(identifier: "ko")
        case .arabic:             return Locale(identifier: "ar")
        }
    }

    // MARK: Helper
    private func pick(_ zh: String, _ en: String, _ ja: String, _ ko: String, _ zht: String, _ es: String? = nil, _ fr: String? = nil, _ ar: String? = nil) -> String {
        switch lang {
        case .simplifiedChinese:  return zh
        case .english:            return en
        case .spanish:            return es ?? en
        case .french:             return fr ?? en
        case .japanese:           return ja
        case .korean:             return ko
        case .traditionalChinese: return zht
        case .arabic:             return ar ?? en
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
        case .spanish:
            switch self {
            case .cafe: return "Café"; case .museum: return "Museo"; case .bookstore: return "Librería"
            case .bar: return "Bar"; case .gallery: return "Galería"; case .selectShop: return "Tienda selecta"
            case .restaurant: return "Restaurante"; case .other: return "Otro"
            }
        case .french:
            switch self {
            case .cafe: return "Café"; case .museum: return "Musée"; case .bookstore: return "Librairie"
            case .bar: return "Bar"; case .gallery: return "Galerie"; case .selectShop: return "Boutique sélectionnée"
            case .restaurant: return "Restaurant"; case .other: return "Autre"
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
        case .arabic:
            switch self {
            case .cafe: return "مقهى"; case .museum: return "متحف"; case .bookstore: return "مكتبة"
            case .bar: return "بار"; case .gallery: return "معرض"; case .selectShop: return "متجر مختار"
            case .restaurant: return "مطعم"; case .other: return "أخرى"
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
        case .spanish:
            switch self {
            case .loved: return "Me encantó"; case .relaxed: return "Relajado"; case .amazed: return "Asombrado"
            case .neutral: return "Neutral"; case .tired: return "Cansado"
            }
        case .french:
            switch self {
            case .loved: return "Adoré"; case .relaxed: return "Détendu"; case .amazed: return "Émerveillé"
            case .neutral: return "Neutre"; case .tired: return "Fatigué"
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
        case .arabic:
            switch self {
            case .loved: return "أحببته"; case .relaxed: return "مرتاح"; case .amazed: return "مندهش"
            case .neutral: return "محايد"; case .tired: return "متعب"
            }
        }
    }
}
