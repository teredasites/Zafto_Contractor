#!/usr/bin/env python3
"""5-language batch 24: V + W values + lowercase"""
import json, subprocess, os

LOCALES = ['ht', 'ru', 'ko', 'vi', 'tl']
dicts = {}
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    if os.path.exists(f):
        with open(f, "r", encoding="utf-8") as fh: dicts[loc] = json.load(fh)
    else: dicts[loc] = {}

def t(en, ht_v, ru_v, ko_v, vi_v, tl_v):
    dicts['ht'][en]=ht_v; dicts['ru'][en]=ru_v; dicts['ko'][en]=ko_v; dicts['vi'][en]=vi_v; dicts['tl'][en]=tl_v

# V values
t("VIN", "VIN", "VIN", "VIN", "VIN", "VIN")
t("VIP", "VIP", "VIP", "VIP", "VIP", "VIP")
t("Vacant", "Vid", "Вакантный", "공실", "Trống", "Bakante")
t("Valid", "Valab", "Действителен", "유효", "Hợp lệ", "Valid")
t("Valid Until", "Valab Jiska", "Действителен до", "유효 기간", "Có hiệu lực đến", "Valid Hanggang")
t("Valley", "Vale", "Ендова", "골", "Máng nước", "Valley")
t("Value", "Valè", "Значение", "값", "Giá trị", "Halaga")
t("Variables will be populated from linked entity data.", "Varyab ap ranpli ak done antite lye.", "Переменные будут заполнены из данных связанных объектов.", "변수는 연결된 엔티티 데이터에서 채워집니다.", "Biến sẽ được điền từ dữ liệu thực thể liên kết.", "Ang mga variable ay mapupunan mula sa linked entity data.")
t("Variance", "Varyans", "Отклонение", "차이", "Chênh lệch", "Variance")
t("Variance Analysis", "Analiz Varyans", "Анализ отклонений", "차이 분석", "Phân tích chênh lệch", "Variance Analysis")
t("Variance Report", "Rapò Varyans", "Отчёт об отклонениях", "차이 보고서", "Báo cáo chênh lệch", "Variance Report")
t("Vehicle", "Machin", "Транспорт", "차량", "Phương tiện", "Sasakyan")
t("Vehicle Assignment", "Asiyman Machin", "Назначение транспорта", "차량 배정", "Phân công phương tiện", "Vehicle Assignment")
t("Vendor Name", "Non Vandè", "Название поставщика", "거래처명", "Tên nhà cung cấp", "Pangalan ng Vendor")
t("Vendor Payments", "Peman Vandè", "Платежи поставщикам", "거래처 결제", "Thanh toán nhà cung cấp", "Mga Bayad sa Vendor")
t("Vendors", "Vandè", "Поставщики", "거래처", "Nhà cung cấp", "Mga Vendor")
t("Verification Status", "Estati Verifikasyon", "Статус проверки", "인증 상태", "Trạng thái xác minh", "Status ng Verification")
t("Verify", "Verifye", "Проверить", "확인", "Xác minh", "I-verify")
t("Version", "Vèsyon", "Версия", "버전", "Phiên bản", "Bersyon")
t("Video", "Videyo", "Видео", "비디오", "Video", "Video")
t("View All", "Wè Tout", "Смотреть все", "모두 보기", "Xem tất cả", "Tingnan Lahat")
t("View Calendar", "Wè Kalandriye", "Посмотреть календарь", "캘린더 보기", "Xem lịch", "Tingnan ang Calendar")
t("View Claims", "Wè Reklamasyon", "Посмотреть заявки", "청구 보기", "Xem yêu cầu bồi thường", "Tingnan ang mga Claim")
t("View Details", "Wè Detay", "Подробнее", "상세 보기", "Xem chi tiết", "Tingnan ang Detalye")
t("View Invoices", "Wè Fakti", "Посмотреть счета", "청구서 보기", "Xem hóa đơn", "Tingnan ang mga Invoice")
t("View Warranties", "Wè Garanti", "Посмотреть гарантии", "보증 보기", "Xem bảo hành", "Tingnan ang mga Warranty")
t("View and manage all units across your properties", "Wè ak jere tout inite nan pwopriyete ou yo", "Просмотр и управление юнитами по всем объектам", "모든 부동산의 유닛을 조회 및 관리하세요", "Xem và quản lý tất cả đơn vị trên các bất động sản", "Tingnan at pamahalaan ang lahat ng units sa iyong mga property")
t("View and manage your schedule", "Wè ak jere orè ou", "Просмотр и управление расписанием", "일정을 조회 및 관리하세요", "Xem và quản lý lịch trình", "Tingnan at pamahalaan ang schedule mo")
t("Violation", "Vyolasyon", "Нарушение", "위반", "Vi phạm", "Paglabag")
t("Visibility", "Vizibilite", "Видимость", "가시성", "Khả năng hiển thị", "Visibility")
t("Visible Mold Types", "Tip Mwazi Vizib", "Видимые виды плесени", "가시적 곰팡이 유형", "Loại nấm mốc nhìn thấy", "Mga Nakikitang Uri ng Mold")
t("Voicemail", "Mesaj Vokal", "Голосовая почта", "음성 메일", "Thư thoại", "Voicemail")
t("Void Expense", "Anile Depans", "Аннулировать расход", "비용 무효화", "Hủy chi phí", "I-void ang Expense")
t("Void Invoice", "Anile Fakti", "Аннулировать счёт", "청구서 무효화", "Hủy hóa đơn", "I-void ang Invoice")
t("Volume", "Volim", "Объём", "볼륨", "Thể tích", "Volume")

# W values
t("W-4 Info", "Enfòmasyon W-4", "Информация W-4", "W-4 정보", "Thông tin W-4", "Impormasyon ng W-4")
t("W/ Waste", "Ak Gaspiyaj", "С отходами", "폐기물 포함", "Có phế liệu", "May Waste")
t("WIP Report", "Rapò WIP", "Отчёт WIP", "WIP 보고서", "Báo cáo WIP", "WIP Report")
t("WME", "WME", "WME", "WME", "WME", "WME")
t("Waiver", "Renonsyasyon", "Отказ от прав", "포기서", "Giấy từ bỏ", "Waiver")
t("Walkthrough Details", "Detay Vizit", "Детали обхода", "현장 조사 상세", "Chi tiết khảo sát", "Detalye ng Walkthrough")
t("Walkthrough Summary", "Rezime Vizit", "Сводка обхода", "현장 조사 요약", "Tóm tắt khảo sát", "Buod ng Walkthrough")
t("Walkthrough Type", "Tip Vizit", "Тип обхода", "현장 조사 유형", "Loại khảo sát", "Uri ng Walkthrough")
t("Walkthrough Workflows", "Pwosesis Vizit", "Рабочие процессы обхода", "현장 조사 워크플로", "Quy trình khảo sát", "Mga Walkthrough Workflow")
t("Walkthrough not found", "Vizit pa jwenn", "Обход не найден", "현장 조사를 찾을 수 없음", "Không tìm thấy khảo sát", "Hindi nahanap ang walkthrough")
t("Walkthroughs", "Vizit", "Обходы", "현장 조사", "Khảo sát", "Mga Walkthrough")
t("Walls", "Mi", "Стены", "벽", "Tường", "Mga Dingding")
t("Warm", "Cho", "Тёплый", "따뜻한", "Ấm", "Mainit")
t("Warm Leads", "Pwopriyetè Cho", "Тёплые лиды", "따뜻한 리드", "Khách hàng tiềm năng ấm", "Mga Warm Lead")
t("Warranties", "Garanti", "Гарантии", "보증", "Bảo hành", "Mga Warranty")
t("Warranty #", "Garanti #", "Гарантия #", "보증 #", "Bảo hành #", "Warranty #")
t("Warranty Callbacks", "Rapèl Garanti", "Гарантийные обращения", "보증 콜백", "Phản hồi bảo hành", "Mga Warranty Callback")
t("Warranty Coverage", "Kouvèti Garanti", "Гарантийное покрытие", "보증 범위", "Phạm vi bảo hành", "Saklaw ng Warranty")
t("Warranty Details", "Detay Garanti", "Детали гарантии", "보증 상세", "Chi tiết bảo hành", "Detalye ng Warranty")
t("Warranty Expiration", "Ekspirasyon Garanti", "Истечение гарантии", "보증 만료", "Hết hạn bảo hành", "Pag-expire ng Warranty")
t("Warranty Expired", "Garanti Ekspire", "Гарантия истекла", "보증 만료됨", "Bảo hành đã hết", "Nag-expire na ang Warranty")
t("Warranty Expiry", "Ekspirasyon Garanti", "Срок гарантии", "보증 만료일", "Ngày hết hạn bảo hành", "Pag-expire ng Warranty")
t("Warranty Intel", "Entèlijans Garanti", "Гарантийная аналитика", "보증 인텔", "Thông tin bảo hành", "Warranty Intel")
t("Warranty Intelligence", "Entèlijans Garanti", "Гарантийная аналитика", "보증 인텔리전스", "Phân tích bảo hành", "Warranty Intelligence")
t("Warranty Network", "Rezo Garanti", "Гарантийная сеть", "보증 네트워크", "Mạng lưới bảo hành", "Warranty Network")
t("Warranty Start", "Kòmansman Garanti", "Начало гарантии", "보증 시작", "Bắt đầu bảo hành", "Simula ng Warranty")
t("Warranty Tracker", "Swivi Garanti", "Отслеживание гарантий", "보증 추적", "Theo dõi bảo hành", "Warranty Tracker")
t("Warranty Type", "Tip Garanti", "Тип гарантии", "보증 유형", "Loại bảo hành", "Uri ng Warranty")
t("Warranty dispatches from your partner companies will appear here.", "Ekspedisyon garanti nan konpayi patnè ou ap parèt isit la.", "Гарантийные направления от партнёров появятся здесь.", "파트너 회사의 보증 배정이 여기에 표시됩니다.", "Các phân công bảo hành từ công ty đối tác sẽ xuất hiện ở đây.", "Ang mga warranty dispatch mula sa partner companies mo ay lalabas dito.")
t("Warranty:", "Garanti:", "Гарантия:", "보증:", "Bảo hành:", "Warranty:")
t("Waste", "Gaspiyaj", "Отходы", "폐기물", "Phế liệu", "Waste")
t("Waste %", "Gaspiyaj %", "Отходы %", "폐기물 %", "Phế liệu %", "Waste %")
t("Waste Factor", "Faktè Gaspiyaj", "Коэффициент отходов", "폐기물 계수", "Hệ số phế liệu", "Waste Factor")
t("Water Damage Assessment", "Evalyasyon Domaj Dlo", "Оценка ущерба от воды", "수해 평가", "Đánh giá thiệt hại do nước", "Water Damage Assessment")
t("Water Suppression", "Sipresyon Dlo", "Подавление воды", "수해 억제", "Ức chế nước", "Water Suppression")
t("Webhooks", "Webhooks", "Вебхуки", "웹훅", "Webhooks", "Mga Webhook")
t("Website", "Sit Wèb", "Веб-сайт", "웹사이트", "Trang web", "Website")
t("Week", "Semèn", "Неделя", "주", "Tuần", "Linggo")
t("Week Starting", "Semèn Kòmanse", "Начало недели", "주 시작", "Tuần bắt đầu", "Simula ng Linggo")
t("Weekly", "Chak Semèn", "Еженедельно", "주간", "Hàng tuần", "Lingguhan")
t("Weekly Report", "Rapò Chak Semèn", "Еженедельный отчёт", "주간 보고서", "Báo cáo hàng tuần", "Lingguhang Ulat")
t("Welcome back. Here's what's happening today.", "Byenvini ankò. Men sa k ap pase jodi a.", "С возвращением. Вот что происходит сегодня.", "다시 오신 것을 환영합니다. 오늘 현황입니다.", "Chào mừng trở lại. Đây là những gì đang diễn ra hôm nay.", "Welcome back. Ito ang mga nangyayari ngayon.")
t("Wet Standard", "Estanda Mouye", "Стандарт влажности", "습윤 표준", "Tiêu chuẩn ướt", "Wet Standard")
t("What each role can access", "Kisa chak wòl ka gen aksè", "Доступ для каждой роли", "각 역할의 접근 권한", "Mỗi vai trò có thể truy cập gì", "Ano ang maa-access ng bawat role")
t("When this happens...", "Lè sa rive...", "Когда это происходит...", "이 일이 발생하면...", "Khi điều này xảy ra...", "Kapag nangyari ito...")
t("Win Probability", "Pwobabilite Viktwa", "Вероятность выигрыша", "수주 확률", "Xác suất thắng", "Tsansa ng Panalo")
t("Win Rate", "To Viktwa", "Процент побед", "수주율", "Tỷ lệ thắng", "Win Rate")
t("Wind", "Van", "Ветер", "바람", "Gió", "Hangin")
t("Wire", "Transfè Fil", "Банковский перевод", "송금", "Chuyển khoản", "Wire")
t("Withdraw Bid", "Retire Òf", "Отозвать заявку", "입찰 철회", "Rút đấu thầu", "Bawiin ang Bid")
t("Withdrawal", "Retrè", "Снятие", "출금", "Rút tiền", "Withdrawal")
t("Won Bids", "Òf Genyen", "Выигранные заявки", "수주 입찰", "Đấu thầu thắng", "Mga Nanalong Bid")
t("Won This Month", "Genyen Mwa Sa a", "Выиграно в этом месяце", "이번 달 수주", "Thắng tháng này", "Nanalo Ngayong Buwan")
t("Workflow", "Pwosesis", "Рабочий процесс", "워크플로", "Quy trình", "Workflow")
# lowercase
t("win rate", "to viktwa", "процент побед", "수주율", "tỷ lệ thắng", "win rate")
t("with", "ak", "с", "와(과)", "với", "na may")
t("with GPS", "ak GPS", "с GPS", "GPS 포함", "với GPS", "na may GPS")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
