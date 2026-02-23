#!/usr/bin/env python3
"""5-language batch 15: P values (first half)"""
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

t("P&L Detail", "Detay P&L", "Детали P&L", "손익 상세", "Chi tiết Lãi & Lỗ", "Detalye ng P&L")
t("PRIMARY", "PRENSIPAL", "ОСНОВНОЙ", "기본", "CHÍNH", "PANGUNAHIN")
t("Packed", "Pake", "Упакован", "포장됨", "Đã đóng gói", "Naka-pack")
t("Packet Name", "Non Pakè", "Название пакета", "패킷 이름", "Tên gói", "Pangalan ng Packet")
t("Page", "Paj", "Страница", "페이지", "Trang", "Pahina")
t("Paid This Month", "Peye Mwa Sa a", "Оплачено в этом месяце", "이번 달 지급", "Đã thanh toán tháng này", "Nabayaran Ngayong Buwan")
t("Painting", "Pentire", "Покраска", "도장", "Sơn", "Pagpipinta")
t("Panel", "Panno", "Панель", "패널", "Bảng điều khiển", "Panel")
t("Parse Summary", "Rezime Analiz", "Сводка разбора", "파싱 요약", "Tóm tắt phân tích", "Buod ng Parse")
t("Part-Time", "Tan Pasyèl", "Неполный рабочий день", "파트타임", "Bán thời gian", "Part-Time")
t("Partial", "Pasyèl", "Частично", "부분", "Một phần", "Bahagya")
t("Partial Payments", "Peman Pasyèl", "Частичные платежи", "부분 결제", "Thanh toán một phần", "Mga Partial Payment")
t("Parts Coverage", "Kouvèti Pyès", "Покрытие запчастей", "부품 보장", "Bảo hiểm linh kiện", "Saklaw ng Parts")
t("Parts Duration", "Dire Pyès", "Срок действия запчастей", "부품 기간", "Thời hạn linh kiện", "Tagal ng Parts")
t("Parts to Stock", "Pyès pou Estoke", "Запчасти на склад", "재고 부품", "Linh kiện nhập kho", "Parts para i-stock")
t("Pass", "Pase", "Пройдено", "통과", "Đạt", "Passed")
t("Pass Rate", "To Pase", "Процент прохождения", "통과율", "Tỷ lệ đạt", "Pass Rate")
t("Password", "Modpas", "Пароль", "비밀번호", "Mật khẩu", "Password")
t("Password changed successfully", "Modpas chanje avèk siksè", "Пароль успешно изменён", "비밀번호가 성공적으로 변경되었습니다", "Đã đổi mật khẩu thành công", "Matagumpay na napalitan ang password")
t("Past / Completed", "Pase / Konplè", "Прошедшие / Завершённые", "과거 / 완료", "Đã qua / Hoàn thành", "Nakaraan / Kumpleto")
t("Past Due", "Anreta", "Просрочено", "기한 초과", "Quá hạn", "Past Due")
t("Pay Rate", "Tarif Salè", "Ставка оплаты", "급여율", "Đơn giá lương", "Pay Rate")
t("Payment Due", "Peman Dwe", "Срок оплаты", "결제 기한", "Đến hạn thanh toán", "Payment Due")
t("Payment History", "Istwa Peman", "История платежей", "결제 이력", "Lịch sử thanh toán", "Kasaysayan ng Bayad")
t("Payment Method", "Metòd Peman", "Способ оплаты", "결제 방법", "Phương thức thanh toán", "Paraan ng Pagbabayad")
t("Payment Preferences", "Preferans Peman", "Настройки оплаты", "결제 환경설정", "Tùy chọn thanh toán", "Mga Kagustuhan sa Pagbabayad")
t("Payment Received", "Peman Resevwa", "Платёж получен", "결제 수신됨", "Đã nhận thanh toán", "Natanggap ang Bayad")
t("Payment Reminder", "Rapèl Peman", "Напоминание об оплате", "결제 알림", "Nhắc thanh toán", "Paalala sa Bayad")
t("Payment Terms", "Tèm Peman", "Условия оплаты", "결제 조건", "Điều khoản thanh toán", "Mga Tuntunin ng Bayad")
t("Payment history is available in the Rent Roll", "Istwa peman disponib nan Lis Lwaye", "История платежей в реестре аренды", "결제 이력은 임대료 목록에서 확인 가능", "Lịch sử thanh toán có trong Sổ thuê", "Ang kasaysayan ng bayad ay makikita sa Rent Roll")
t("Payments Count", "Kantite Peman", "Количество платежей", "결제 건수", "Số lần thanh toán", "Bilang ng Bayad")
t("Payouts", "Peman Soti", "Выплаты", "지급", "Chi trả", "Mga Payout")
t("Penalty", "Penalite", "Штраф", "벌금", "Phạt", "Multa")
t("Pending Approval", "An Atant Apwobasyon", "Ожидает утверждения", "승인 대기", "Chờ phê duyệt", "Naghihintay ng Pag-apruba")
t("Pending Claims", "Reklamasyon An Atant", "Ожидающие заявки", "대기 중 청구", "Yêu cầu bồi thường đang chờ", "Mga Pending Claim")
t("Pending Invites", "Envitasyon An Atant", "Ожидающие приглашения", "대기 중 초대", "Lời mời đang chờ", "Mga Pending Invite")
t("Pending Leads", "Pwopriyetè An Atant", "Ожидающие лиды", "대기 중 리드", "Khách hàng tiềm năng đang chờ", "Mga Pending Lead")
t("Pending Renewal", "Renouvèlman An Atant", "Ожидает продления", "갱신 대기", "Chờ gia hạn", "Pending Renewal")
t("Pending Review", "Revizyon An Atant", "Ожидает проверки", "검토 대기", "Chờ xem xét", "Pending Review")
t("Pending Reviews", "Revizyon An Atant", "Ожидающие проверки", "검토 대기", "Đánh giá đang chờ", "Mga Pending Review")
t("Pending Signatures", "Siyati An Atant", "Ожидающие подписи", "서명 대기", "Chữ ký đang chờ", "Mga Pending Signature")
t("Pending Value", "Valè An Atant", "Ожидаемая сумма", "대기 금액", "Giá trị đang chờ", "Pending na Halaga")
t("Pending WDI", "WDI An Atant", "Ожидающие WDI", "WDI 대기", "WDI đang chờ", "Pending WDI")
t("Per Unit", "Pa Inite", "За единицу", "유닛당", "Mỗi đơn vị", "Bawat Unit")
t("Percentage", "Pousantaj", "Процент", "백분율", "Phần trăm", "Porsiyento")
t("Performance Reviews", "Evalyasyon Pèfòmans", "Обзоры производительности", "성과 리뷰", "Đánh giá hiệu suất", "Mga Performance Review")
t("Period", "Peryòd", "Период", "기간", "Kỳ", "Period")
t("Period Audit Log", "Jounal Odit Peryòd", "Журнал аудита периода", "기간 감사 로그", "Nhật ký kiểm toán kỳ", "Period Audit Log")
t("Period End", "Fen Peryòd", "Конец периода", "기간 종료", "Cuối kỳ", "Katapusan ng Period")
t("Period Start", "Kòmansman Peryòd", "Начало периода", "기간 시작", "Đầu kỳ", "Simula ng Period")
t("Permission", "Pèmisyon", "Разрешение", "권한", "Quyền", "Pahintulot")
t("Permissions", "Pèmisyon", "Разрешения", "권한", "Quyền", "Mga Pahintulot")
t("Permit #", "Pèmi #", "Разрешение #", "허가 #", "Giấy phép #", "Permit #")
t("Permit Details", "Detay Pèmi", "Детали разрешения", "허가 상세", "Chi tiết giấy phép", "Detalye ng Permit")
t("Permit Fee", "Frè Pèmi", "Стоимость разрешения", "허가 수수료", "Phí giấy phép", "Permit Fee")
t("Permit Jurisdictions", "Jiridiksyon Pèmi", "Юрисдикции разрешений", "허가 관할구역", "Khu vực pháp lý giấy phép", "Mga Hurisdiksiyon ng Permit")
t("Permit Status", "Estati Pèmi", "Статус разрешения", "허가 상태", "Trạng thái giấy phép", "Status ng Permit")
t("Permit Tracker", "Swivi Pèmi", "Отслеживание разрешений", "허가 추적", "Theo dõi giấy phép", "Permit Tracker")
t("Permit Type", "Tip Pèmi", "Тип разрешения", "허가 유형", "Loại giấy phép", "Uri ng Permit")
t("Personality & Voice", "Pèsonalite & Vwa", "Личность и голос", "성격 및 음성", "Tính cách & Giọng nói", "Personalidad & Boses")
t("Pest Control", "Kontwòl Parazit", "Борьба с вредителями", "방역", "Kiểm soát sâu bệnh", "Pest Control")
t("Phase", "Faz", "Фаза", "단계", "Giai đoạn", "Phase")
t("Phone Call", "Apèl Telefòn", "Телефонный звонок", "전화 통화", "Cuộc gọi điện thoại", "Tawag sa Telepono")
t("Phone Number", "Nimewo Telefòn", "Номер телефона", "전화번호", "Số điện thoại", "Numero ng Telepono")
t("Phone System Configuration", "Konfigirasyon Sistèm Telefòn", "Настройка телефонной системы", "전화 시스템 설정", "Cấu hình hệ thống điện thoại", "Configuration ng Phone System")
t("Photo", "Foto", "Фото", "사진", "Ảnh", "Litrato")
t("Photo on fail", "Foto sou echèk", "Фото при неудаче", "실패 시 사진", "Ảnh khi không đạt", "Litrato kapag hindi pumasa")
t("Photos & Attachments", "Foto & Atachman", "Фото и вложения", "사진 및 첨부파일", "Ảnh & Tệp đính kèm", "Mga Litrato & Attachment")
t("Photos are taken during the walkthrough on the mobile app", "Foto pran pandan vizit sou aplikasyon mobil la", "Фото делаются во время обхода в мобильном приложении", "사진은 모바일 앱에서 현장 조사 중 촬영됩니다", "Ảnh được chụp trong quá trình khảo sát trên ứng dụng di động", "Ang mga litrato ay kinukuha habang nasa walkthrough sa mobile app")
t("Pipeline", "Pipeline", "Воронка", "파이프라인", "Kênh", "Pipeline")
t("Pipeline Value", "Valè Pipeline", "Стоимость воронки", "파이프라인 금액", "Giá trị kênh", "Halaga ng Pipeline")
t("Place your first bid", "Mete premye òf ou", "Подайте первую заявку", "첫 입찰을 제출하세요", "Đặt đấu thầu đầu tiên", "Maglagay ng unang bid mo")
t("Plain Text Body", "Kò Tèks Senp", "Текстовое тело", "일반 텍스트 본문", "Nội dung văn bản thuần", "Plain Text Body")
t("Plan Features", "Fonksyonalite Plan", "Функции плана", "요금제 기능", "Tính năng gói", "Mga Feature ng Plan")
t("Plan/Drawing", "Plan/Desen", "План/Чертёж", "도면/설계도", "Bản vẽ/Thiết kế", "Plan/Drawing")
t("Plumbing", "Plonbri", "Сантехника", "배관", "Hệ thống ống nước", "Plumbing")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
