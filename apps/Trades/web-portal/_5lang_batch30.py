#!/usr/bin/env python3
"""5-language batch 30: remaining G + H + I values"""
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

# G values
t("Fully Compliant", "Konfòm Totalman", "Полностью соответствует", "완전 준수", "Tuân thủ hoàn toàn", "Ganap na Compliant")
t("General", "Jeneral", "Общий", "일반", "Chung", "Pangkalahatan")
t("General Contracting", "Kontra Jeneral", "Генеральный подряд", "종합 건설", "Tổng thầu", "General Contracting")
t("Generate", "Jenere", "Сгенерировать", "생성", "Tạo", "I-generate")
t("Generate Report", "Jenere Rapò", "Сгенерировать отчёт", "보고서 생성", "Tạo báo cáo", "I-generate ang Report")
t("Generating export package...", "Ap jenere pakè ekspòtasyon...", "Формирование пакета экспорта...", "내보내기 패키지 생성 중...", "Đang tạo gói xuất...", "Ginagawa ang export package...")
t("Global Checklist", "Lis Verifikasyon Global", "Глобальный чек-лист", "글로벌 체크리스트", "Danh sách kiểm tra chung", "Global na Checklist")
t("Global Custom Fields", "Chan Pèsonalize Global", "Глобальные пользовательские поля", "글로벌 사용자 정의 필드", "Trường tùy chỉnh chung", "Mga Global Custom Field")
t("Goals", "Objektif", "Цели", "목표", "Mục tiêu", "Mga Layunin")
t("Good", "Bon", "Хорошо", "양호", "Tốt", "Mabuti")
t("Google", "Google", "Google", "Google", "Google", "Google")
t("Google LSA", "Google LSA", "Google LSA", "Google LSA", "Google LSA", "Google LSA")
t("Grace Period", "Peryòd Delè", "Льготный период", "유예 기간", "Thời gian ân hạn", "Grace Period")
t("Grand Total", "Gran Total", "Общий итог", "총합계", "Tổng cộng", "Kabuuang Total")
t("Graph", "Grafik", "График", "그래프", "Biểu đồ", "Graph")
t("Grid", "Griy", "Сетка", "그리드", "Lưới", "Grid")
t("Gross Pay", "Salè Brit", "Начисленная зарплата", "총 급여", "Lương gộp", "Gross Pay")
t("Gross Profit", "Pwofi Brit", "Валовая прибыль", "매출 총이익", "Lợi nhuận gộp", "Gross Profit")
t("Group by", "Groupe pa", "Группировать по", "그룹화", "Nhóm theo", "I-group ayon sa")
t("Growth", "Kwasans", "Рост", "성장", "Tăng trưởng", "Paglago")
t("Guarantee", "Garanti", "Гарантия", "보증", "Bảo đảm", "Garantiya")

# H values
t("HR", "RH", "Кадры", "인사", "Nhân sự", "HR")
t("HVAC", "HVAC", "HVAC", "HVAC", "HVAC", "HVAC")
t("HVAC Install", "Enstalasyon HVAC", "Установка HVAC", "HVAC 설치", "Lắp đặt HVAC", "HVAC Install")
t("Hazards Found", "Danje Jwenn", "Обнаружены опасности", "위험 요소 발견", "Phát hiện nguy hiểm", "Mga Natuklasang Panganib")
t("Header", "Antèt", "Заголовок", "헤더", "Tiêu đề", "Header")
t("Help", "Èd", "Помощь", "도움말", "Trợ giúp", "Tulong")
t("High", "Wo", "Высокий", "높음", "Cao", "Mataas")
t("Hire Date", "Dat Anbochaj", "Дата найма", "입사일", "Ngày tuyển dụng", "Petsa ng Pag-hire")
t("Hiring", "Anbochaj", "Найм", "채용", "Tuyển dụng", "Pag-hire")
t("Historical Win Rate", "To Viktwa Istorik", "Исторический процент побед", "과거 수주율", "Tỷ lệ thắng lịch sử", "Historical Win Rate")
t("History", "Istwa", "История", "이력", "Lịch sử", "Kasaysayan")
t("Home", "Akèy", "Главная", "홈", "Trang chủ", "Home")
t("HomeAdvisor", "HomeAdvisor", "HomeAdvisor", "HomeAdvisor", "HomeAdvisor", "HomeAdvisor")
t("Hot", "Cho", "Горячий", "핫", "Nóng", "Mainit")
t("Hot Leads", "Pwopriyetè Cho", "Горячие лиды", "핫 리드", "Khách hàng tiềm năng nóng", "Mga Hot Lead")
t("Hourly", "Pa Èdtan", "Почасовая", "시간당", "Theo giờ", "Oras-oras")
t("Hours", "Èdtan", "Часы", "시간", "Giờ", "Mga Oras")
t("Hours Worked", "Èdtan Travay", "Отработанные часы", "근무 시간", "Giờ làm việc", "Mga Oras na Nagtrabaho")
t("Humidity", "Imidite", "Влажность", "습도", "Độ ẩm", "Halumigmig")

# I values
t("ID", "ID", "ID", "ID", "ID", "ID")
t("IICRC", "IICRC", "IICRC", "IICRC", "IICRC", "IICRC")
t("Imagery Date", "Dat Imaj", "Дата снимка", "영상 날짜", "Ngày chụp ảnh", "Petsa ng Imagery")
t("Import", "Enpòte", "Импорт", "가져오기", "Nhập", "Mag-import")
t("Import History", "Istwa Enpòtasyon", "История импорта", "가져오기 이력", "Lịch sử nhập", "History ng Pag-import")
t("Import Schedule", "Orè Enpòtasyon", "Расписание импорта", "가져오기 일정", "Lịch nhập", "Schedule ng Pag-import")
t("Import to Claim", "Enpòte nan Reklamasyon", "Импортировать в заявку", "청구로 가져오기", "Nhập vào yêu cầu", "I-import sa Claim")
t("In Stock", "An Stòk", "В наличии", "재고 있음", "Còn hàng", "May Stock")
t("Inbox", "Bwat Resepsyon", "Входящие", "수신함", "Hộp thư đến", "Inbox")
t("Income", "Revni", "Доход", "수입", "Thu nhập", "Kita")
t("Indoor Humidity", "Imidite Anndan", "Влажность внутри", "실내 습도", "Độ ẩm trong nhà", "Indoor Humidity")
t("Indoor Temp", "Tanperati Anndan", "Температура внутри", "실내 온도", "Nhiệt độ trong nhà", "Indoor Temp")
t("Info", "Enfò", "Инфо", "정보", "Thông tin", "Info")
t("Inspection Engine", "Motè Enspeksyon", "Движок инспекций", "점검 엔진", "Công cụ kiểm tra", "Inspection Engine")
t("Inspection Failed", "Enspeksyon Echwe", "Инспекция не пройдена", "점검 불합격", "Kiểm tra không đạt", "Nabigo ang Inspection")
t("Inspection Passed", "Enspeksyon Pase", "Инспекция пройдена", "점검 합격", "Kiểm tra đạt", "Pumasa ang Inspection")
t("Inspection Timeline", "Kalandriye Enspeksyon", "Хронология инспекций", "점검 타임라인", "Dòng thời gian kiểm tra", "Timeline ng Inspection")
t("Inspector", "Enspektè", "Инспектор", "점검관", "Thanh tra viên", "Inspector")
t("Instagram", "Instagram", "Instagram", "Instagram", "Instagram", "Instagram")
t("Install Date", "Dat Enstalasyon", "Дата установки", "설치일", "Ngày lắp đặt", "Petsa ng Pag-install")
t("Insurance Carrier", "Konpayi Asirans", "Страховая компания", "보험사", "Công ty bảo hiểm", "Insurance Carrier")
t("Insurance Claims", "Reklamasyon Asirans", "Страховые претензии", "보험 청구", "Yêu cầu bồi thường bảo hiểm", "Mga Insurance Claim")
t("Insurance Details", "Detay Asirans", "Детали страховки", "보험 상세", "Chi tiết bảo hiểm", "Detalye ng Insurance")
t("Insurance Verified", "Asirans Verifye", "Страховка подтверждена", "보험 확인됨", "Bảo hiểm đã xác minh", "Na-verify ang Insurance")
t("Integration", "Entegrasyon", "Интеграция", "연동", "Tích hợp", "Integration")
t("Integration Method", "Metòd Entegrasyon", "Метод интеграции", "연동 방식", "Phương thức tích hợp", "Paraan ng Integration")
t("Integrations", "Entegrasyon", "Интеграции", "연동", "Tích hợp", "Mga Integration")
t("Internal", "Entèn", "Внутренний", "내부", "Nội bộ", "Internal")
t("Internal Notes", "Nòt Entèn", "Внутренние заметки", "내부 메모", "Ghi chú nội bộ", "Mga Internal Note")
t("Inventory", "Envantè", "Инвентарь", "재고", "Kho hàng", "Imbentaryo")
t("Inventory History", "Istwa Envantè", "История инвентаря", "재고 이력", "Lịch sử kho hàng", "History ng Imbentaryo")
t("Inventory count", "Kantite envantè", "Количество инвентаря", "재고 수량", "Số lượng tồn kho", "Bilang ng imbentaryo")
t("Invoice #", "Fakti #", "Счёт #", "청구서 #", "Hóa đơn #", "Invoice #")
t("Invoice History", "Istwa Fakti", "История счетов", "청구서 이력", "Lịch sử hóa đơn", "History ng Invoice")
t("Invoice Overdue", "Fakti Anreta", "Просроченный счёт", "연체 청구서", "Hóa đơn quá hạn", "Overdue na Invoice")
t("Invoice Total", "Total Fakti", "Итого по счёту", "청구서 합계", "Tổng hóa đơn", "Kabuuang Invoice")
t("Invoice format", "Fòma fakti", "Формат счёта", "청구서 형식", "Định dạng hóa đơn", "Format ng invoice")
t("Issued", "Emèt", "Выдан", "발행됨", "Đã phát hành", "Nai-issue")
t("Issued Date", "Dat Emisyon", "Дата выдачи", "발행일", "Ngày phát hành", "Petsa ng Pag-issue")
t("Items Needing Repair", "Atik Ki Bezwen Reparasyon", "Элементы, требующие ремонта", "수리 필요 항목", "Hạng mục cần sửa chữa", "Mga Item na Kailangan ng Repair")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
