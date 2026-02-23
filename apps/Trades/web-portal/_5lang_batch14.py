#!/usr/bin/env python3
"""5-language batch 14: O values"""
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

t("O&P", "O&P", "НР и прибыль", "간접비 및 이윤", "Chi phí chung & Lợi nhuận", "O&P")
t("OK", "OK", "ОК", "확인", "OK", "OK")
t("OSHA Standards", "Estanda OSHA", "Стандарты OSHA", "OSHA 기준", "Tiêu chuẩn OSHA", "Mga Pamantayan ng OSHA")
t("OT Hours", "Èdtan Siplemantè", "Сверхурочные часы", "초과 근무 시간", "Giờ tăng ca", "OT Hours")
t("OT Hrs", "È Sip", "Сверхч.", "초과근무", "Giờ TC", "OT Hrs")
t("Observation", "Obsèvasyon", "Наблюдение", "관찰", "Quan sát", "Obserbasyon")
t("Occupancy", "Okipasyon", "Заполняемость", "점유율", "Tỷ lệ lấp đầy", "Occupancy")
t("Occupancy Rate", "To Okipasyon", "Процент заполняемости", "점유율", "Tỷ lệ lấp đầy", "Rate ng Occupancy")
t("Occupied", "Okipe", "Занято", "점유중", "Đã có người", "Occupied")
t("Odometer", "Odomèt", "Одометр", "주행계", "Công tơ mét", "Odometer")
t("Offer Accepted", "Òf Aksepte", "Предложение принято", "제안 수락됨", "Đề nghị được chấp nhận", "Tinanggap ang Alok")
t("Offer Extended", "Òf Pwolonje", "Предложение продлено", "제안 연장됨", "Đề nghị đã mở rộng", "Inextend ang Alok")
t("Office", "Biwo", "Офис", "사무실", "Văn phòng", "Opisina")
t("Office Manager", "Manadjè Biwo", "Офис-менеджер", "사무 관리자", "Quản lý văn phòng", "Office Manager")
t("On Hold", "An Atant", "На удержании", "보류 중", "Tạm giữ", "Naka-hold")
t("On Job", "Sou Travay", "На заказе", "작업 중", "Đang làm việc", "Nasa Trabaho")
t("On Leave", "An Konje", "В отпуске", "휴가 중", "Đang nghỉ phép", "Naka-leave")
t("On The Clock Now", "Sou Orè Kounye a", "На работе сейчас", "현재 근무 중", "Đang chấm công", "Naka-clock In Ngayon")
t("On Track", "Sou Tras", "В графике", "정상 진행", "Đúng tiến độ", "On Track")
t("On location", "Sou plas", "На месте", "현장에", "Tại hiện trường", "Nasa lokasyon")
t("On-Time Rate", "To Alè", "Процент своевременности", "정시율", "Tỷ lệ đúng giờ", "On-Time Rate")
t("Onboarding", "Onbòding", "Адаптация", "온보딩", "Nhập môn", "Onboarding")
t("Onboarding Checklists", "Lis Tchèk Onbòding", "Чек-листы адаптации", "온보딩 체크리스트", "Danh sách kiểm tra nhập môn", "Mga Onboarding Checklist")
t("Online Now", "Anliy Kounye a", "Онлайн сейчас", "현재 온라인", "Đang trực tuyến", "Online Ngayon")
t("Online Portal", "Pòtay Anliy", "Онлайн-портал", "온라인 포털", "Cổng trực tuyến", "Online Portal")
t("Onsite", "Sou Plas", "На объекте", "현장", "Tại chỗ", "Nasa Site")
t("Open Balance", "Balans Ouvè", "Открытый баланс", "미결 잔액", "Số dư mở", "Open Balance")
t("Open Claims", "Reklamasyon Ouvè", "Открытые заявки", "진행 중 청구", "Yêu cầu bồi thường mở", "Mga Open Claim")
t("Open Maintenance", "Antretyen Ouvè", "Открытое обслуживание", "진행 중 유지보수", "Bảo trì đang mở", "Open Maintenance")
t("Open Opportunities", "Opòtinite Ouvè", "Открытые возможности", "진행 중 기회", "Cơ hội đang mở", "Mga Open Opportunity")
t("Open Orders", "Kòmann Ouvè", "Открытые заказы", "미결 주문", "Đơn hàng đang mở", "Mga Open Order")
t("Open Positions", "Pòs Ouvè", "Открытые вакансии", "공석", "Vị trí đang mở", "Mga Open Position")
t("Open Rate", "To Ouvèti", "Процент открытия", "열람률", "Tỷ lệ mở", "Open Rate")
t("Operating Activities", "Aktivite Fonksyonnman", "Операционная деятельность", "영업 활동", "Hoạt động kinh doanh", "Mga Operating Activity")
t("Operating Expenses", "Depans Fonksyonnman", "Операционные расходы", "영업 비용", "Chi phí hoạt động", "Mga Operating Expense")
t("Optimize Price", "Optimize Pri", "Оптимизировать цену", "가격 최적화", "Tối ưu hóa giá", "I-optimize ang Presyo")
t("Option Breakdown", "Dekoupaj Opsyon", "Разбивка по вариантам", "옵션 분석", "Phân tích tùy chọn", "Option Breakdown")
t("Option Total", "Total Opsyon", "Итого по варианту", "옵션 합계", "Tổng tùy chọn", "Kabuuang Option")
t("Optional", "Opsyonèl", "Необязательно", "선택사항", "Tùy chọn", "Opsyonal")
t("Optional Add-Ons", "Opsyon Adisyonèl", "Дополнительные опции", "선택 추가 사항", "Tiện ích bổ sung", "Mga Opsyonal na Add-On")
t("Order materials and track deliveries", "Kòmande materyèl epi swiv livrezon", "Заказ материалов и отслеживание доставок", "자재 주문 및 배송 추적", "Đặt hàng vật liệu và theo dõi giao hàng", "Mag-order ng materyales at i-track ang delivery")
t("Organization", "Òganizasyon", "Организация", "조직", "Tổ chức", "Organisasyon")
t("Origin", "Orijin", "Происхождение", "기원", "Xuất xứ", "Pinagmulan")
t("Original Amount", "Montan Orijinal", "Первоначальная сумма", "원래 금액", "Số tiền ban đầu", "Orihinal na Halaga")
t("Original Margin", "Maj Orijinal", "Первоначальная маржа", "원래 마진", "Biên lợi nhuận ban đầu", "Orihinal na Margin")
t("Other expenses", "Lòt depans", "Прочие расходы", "기타 비용", "Chi phí khác", "Iba pang gastos")
t("Other interest", "Lòt enterè", "Прочие проценты", "기타 이자", "Lãi suất khác", "Iba pang interes")
t("Out", "Deyò", "Ушёл", "외근", "Ra ngoài", "Nasa Labas")
t("Out of Balance", "Pa Balanse", "Не сбалансировано", "잔액 불일치", "Mất cân đối", "Hindi Balanse")
t("Out of Stock", "Epwize", "Нет в наличии", "품절", "Hết hàng", "Walang Stock")
t("Outcome", "Rezilta", "Результат", "결과", "Kết quả", "Resulta")
t("Outdoor", "Deyò", "Снаружи", "실외", "Ngoài trời", "Outdoor")
t("Outdoor Humidity", "Imidite Deyò", "Наружная влажность", "실외 습도", "Độ ẩm ngoài trời", "Outdoor Humidity")
t("Outdoor Temp", "Tanperati Deyò", "Наружная температура", "실외 온도", "Nhiệt độ ngoài trời", "Outdoor Temp")
t("Outreach Pipeline", "Pipeline Kontakte", "Воронка обращений", "아웃리치 파이프라인", "Kênh tiếp cận", "Outreach Pipeline")
t("Outstanding", "Anreta", "Неоплаченные", "미결제", "Chưa thanh toán", "Outstanding")
t("Outstanding Balance", "Balans Anreta", "Непогашенный баланс", "미결 잔액", "Số dư chưa thanh toán", "Outstanding Balance")
t("Outstanding Invoices", "Fakti Anreta", "Неоплаченные счета", "미결 청구서", "Hóa đơn chưa thanh toán", "Mga Outstanding Invoice")
t("Over/Under", "Sou/Sipli", "Больше/Меньше", "초과/미달", "Trên/Dưới", "Over/Under")
t("Overall Compliance", "Konformite Jeneral", "Общее соответствие", "전체 규정 준수", "Tuân thủ tổng thể", "Pangkalahatang Compliance")
t("Overall Health Score", "Pwen Sante Jeneral", "Общая оценка состояния", "전체 건강 점수", "Điểm sức khỏe tổng thể", "Pangkalahatang Health Score")
t("Overall Margin", "Maj Jeneral", "Общая маржа", "전체 마진", "Biên lợi nhuận tổng thể", "Pangkalahatang Margin")
t("Overdue Amount", "Montan Anreta", "Просроченная сумма", "연체 금액", "Số tiền quá hạn", "Overdue na Halaga")
t("Overdue Invoices", "Fakti Anreta", "Просроченные счета", "연체 청구서", "Hóa đơn quá hạn", "Mga Overdue na Invoice")
t("Overhead", "Frè Jeneral", "Накладные расходы", "간접비", "Chi phí chung", "Overhead")
t("Overhead & Profit", "Frè Jeneral & Pwofi", "Накладные расходы и прибыль", "간접비 및 이윤", "Chi phí chung & Lợi nhuận", "Overhead & Profit")
t("Overridden", "Ranplase", "Переопределено", "재정의됨", "Đã ghi đè", "Na-override")
t("Overstock", "Sipli Estòk", "Избыток на складе", "과잉 재고", "Tồn kho dư", "Overstock")
t("Overtime Hours", "Èdtan Siplemantè", "Сверхурочные часы", "초과 근무 시간", "Giờ tăng ca", "Overtime Hours")
t("Overtime Rate", "Tarif Siplemantè", "Сверхурочная ставка", "초과 근무 단가", "Đơn giá tăng ca", "Overtime Rate")
t("Own", "Posede", "Владелец", "소유", "Sở hữu", "Pag-aari")
t("Owner", "Pwopriyetè", "Владелец", "소유자", "Chủ sở hữu", "May-ari")
# lowercase items
t("of", "de", "из", "의", "của", "ng")
t("of {hours} hours", "de {hours} èdtan", "из {hours} часов", "{hours}시간 중", "trên {hours} giờ", "sa {hours} oras")
t("or", "oswa", "или", "또는", "hoặc", "o")
t("outstanding", "anreta", "неоплаченные", "미결제", "chưa thanh toán", "outstanding")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
