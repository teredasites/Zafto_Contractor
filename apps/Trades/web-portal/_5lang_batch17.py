#!/usr/bin/env python3
"""5-language batch 17: R values (first half)"""
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

t("RCV", "VRS", "ВВС", "대체 비용 가치", "Giá trị thay thế", "RCV")
t("RECALL", "RAPÈL", "ОТЗЫВ", "리콜", "THU HỒI", "RECALL")
t("REPS Hour Tracker", "Swivi Èdtan REPS", "Трекер часов REPS", "REPS 시간 추적", "Theo dõi giờ REPS", "REPS Hour Tracker")
t("REPS Qualified", "REPS Kalifye", "REPS квалифицирован", "REPS 자격 충족", "REPS đủ điều kiện", "REPS Qualified")
t("RFI", "RFI", "Запрос информации", "정보 요청", "Yêu cầu thông tin", "RFI")
t("Rake", "Rak", "Фронтон", "박공", "Diềm mái", "Rake")
t("Rating", "Evalyasyon", "Рейтинг", "평점", "Đánh giá", "Rating")
t("Rating Breakdown", "Dekoupaj Evalyasyon", "Разбивка рейтинга", "평점 분석", "Phân tích đánh giá", "Rating Breakdown")
t("Reading", "Lekti", "Показание", "판독값", "Số đọc", "Reading")
t("Reading Date", "Dat Lekti", "Дата показания", "판독 날짜", "Ngày đọc", "Petsa ng Reading")
t("Reading History", "Istwa Lekti", "История показаний", "판독 이력", "Lịch sử đọc", "Kasaysayan ng Reading")
t("Reading Location", "Kote Lekti", "Место показания", "판독 위치", "Vị trí đọc", "Lokasyon ng Reading")
t("Readings are added from the mobile app during on-site monitoring.", "Lekti ajoute nan aplikasyon mobil pandan siveyans sou plas.", "Показания добавляются из мобильного приложения при мониторинге.", "판독값은 현장 모니터링 중 모바일 앱에서 추가됩니다.", "Số đọc được thêm từ ứng dụng di động trong quá trình giám sát tại chỗ.", "Ang mga reading ay idinaragdag mula sa mobile app habang nasa on-site monitoring.")
t("Real-time Data Access", "Aksè Done An Tan Reyèl", "Доступ к данным в реальном времени", "실시간 데이터 접근", "Truy cập dữ liệu thời gian thực", "Real-time na Data Access")
t("Reason", "Rezon", "Причина", "사유", "Lý do", "Dahilan")
t("Receipt", "Resi", "Квитанция", "영수증", "Biên lai", "Resibo")
t("Received", "Resevwa", "Получено", "수신됨", "Đã nhận", "Natanggap")
t("Received Value", "Valè Resevwa", "Полученная стоимость", "수신 금액", "Giá trị nhận được", "Natanggap na Halaga")
t("Receiving History", "Istwa Resepsyon", "История получения", "수신 이력", "Lịch sử nhận", "Kasaysayan ng Pagtanggap")
t("Recent Activity", "Aktivite Resan", "Последняя активность", "최근 활동", "Hoạt động gần đây", "Kamakailang Aktibidad")
t("Recent Claims", "Reklamasyon Resan", "Последние заявки", "최근 청구", "Yêu cầu bồi thường gần đây", "Mga Kamakailang Claim")
t("Recent Estimates", "Estimasyon Resan", "Последние сметы", "최근 견적", "Dự toán gần đây", "Mga Kamakailang Estimate")
t("Recent Invoices", "Fakti Resan", "Последние счета", "최근 청구서", "Hóa đơn gần đây", "Mga Kamakailang Invoice")
t("Recent Job Autopsies", "Otopsi Travay Resan", "Последние анализы заказов", "최근 작업 분석", "Phân tích công việc gần đây", "Mga Kamakailang Job Autopsy")
t("Recent Jobs", "Travay Resan", "Последние заказы", "최근 작업", "Công việc gần đây", "Mga Kamakailang Trabaho")
t("Recent Outreach", "Kontakte Resan", "Последние обращения", "최근 아웃리치", "Tiếp cận gần đây", "Mga Kamakailang Outreach")
t("Recent Suggestions", "Sijesyon Resan", "Последние предложения", "최근 제안", "Đề xuất gần đây", "Mga Kamakailang Suhestiyon")
t("Recent Transactions", "Tranzaksyon Resan", "Последние транзакции", "최근 거래", "Giao dịch gần đây", "Mga Kamakailang Transaksyon")
t("Recipient", "Destinatè", "Получатель", "수신자", "Người nhận", "Tatanggap")
t("Recipients", "Destinatè", "Получатели", "수신자", "Người nhận", "Mga Tatanggap")
t("Recommendation", "Rekòmandasyon", "Рекомендация", "권장 사항", "Đề xuất", "Rekomendasyon")
t("Recommended", "Rekòmande", "Рекомендовано", "권장", "Được đề xuất", "Inirerekomenda")
t("Recon", "Rekon", "Разведка", "정찰", "Trinh sát", "Recon")
t("Recon Import", "Enpòtasyon Rekon", "Импорт разведки", "정찰 가져오기", "Nhập trinh sát", "Recon Import")
t("Reconciliation", "Rekonsilyasyon", "Сверка", "조정", "Đối chiếu", "Reconciliation")
t("Reconciliation History", "Istwa Rekonsilyasyon", "История сверок", "조정 이력", "Lịch sử đối chiếu", "Kasaysayan ng Reconciliation")
t("Reconstruction Pipeline", "Pipeline Rekonstriksyon", "Воронка реконструкции", "재건 파이프라인", "Kênh tái xây dựng", "Reconstruction Pipeline")
t("Record Payment", "Anrejistre Peman", "Записать платёж", "결제 기록", "Ghi nhận thanh toán", "I-record ang Bayad")
t("Record a video from any job page", "Anrejistre yon videyo nan nenpòt paj travay", "Запишите видео со страницы заказа", "모든 작업 페이지에서 비디오를 녹화하세요", "Ghi video từ bất kỳ trang công việc nào", "Mag-record ng video mula sa kahit anong job page")
t("Record your first expense to start tracking costs", "Anrejistre premye depans ou pou kòmanse swiv koût", "Запишите первый расход для отслеживания", "첫 번째 지출을 기록하여 비용 추적을 시작하세요", "Ghi nhận chi phí đầu tiên để bắt đầu theo dõi", "I-record ang unang gastos mo para simulang i-track ang cost")
t("Recurring Transactions", "Tranzaksyon Regilye", "Повторяющиеся транзакции", "반복 거래", "Giao dịch định kỳ", "Mga Recurring Transaction")
t("Ref Std", "Ref Std", "Ссылочный стандарт", "참조 기준", "Tiêu chuẩn tham chiếu", "Ref Std")
t("Reference", "Referans", "Справка", "참조", "Tham chiếu", "Sanggunian")
t("Reference / Memo", "Referans / Nòt", "Справка / Памятка", "참조 / 메모", "Tham chiếu / Ghi chú", "Sanggunian / Memo")
t("Reference Check", "Verifikasyon Referans", "Проверка рекомендаций", "레퍼런스 체크", "Kiểm tra tham chiếu", "Reference Check")
t("Reference Numbers", "Nimewo Referans", "Справочные номера", "참조 번호", "Số tham chiếu", "Mga Reference Number")
t("Referral", "Referans", "Направление", "추천", "Giới thiệu", "Referral")
t("Referral Fee Type", "Tip Frè Referans", "Тип реферальной комиссии", "추천 수수료 유형", "Loại phí giới thiệu", "Uri ng Referral Fee")
t("Referral Source", "Sous Referans", "Источник направления", "추천 소스", "Nguồn giới thiệu", "Pinagmulan ng Referral")
t("Reg Hrs", "È Regilye", "Обыч. часы", "정규 시간", "Giờ thường", "Reg Hrs")
t("Region", "Rejyon", "Регион", "지역", "Khu vực", "Rehiyon")
t("Reinspection needed", "Bezwen repenspeksyon", "Требуется повторная инспекция", "재검사 필요", "Cần kiểm tra lại", "Kailangan ng reinspection")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
