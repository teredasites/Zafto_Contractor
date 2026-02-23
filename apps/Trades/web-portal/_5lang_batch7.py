#!/usr/bin/env python3
"""5-language batch 7: H-I-J values"""
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

# H values
t("HD Price", "Pri HD", "Цена HD", "HD 가격", "Giá HD", "HD Price")
t("HTML Body", "Kò HTML", "HTML тело", "HTML 본문", "Nội dung HTML", "HTML Body")
t("Hail", "Lagrèl", "Град", "우박", "Mưa đá", "Hail")
t("High Confidence", "Gwo Konfyans", "Высокая уверенность", "높은 신뢰도", "Độ tin cậy cao", "Mataas na Kumpiyansa")
t("Highest Reading", "Lekti Pi Wo", "Наибольшее показание", "최고 판독값", "Số đọc cao nhất", "Pinakamataas na Reading")
t("Hip", "Kwoup", "Вальма", "힙", "Mái hông", "Hip")
t("Human Resources", "Resous Imen", "Человеческие ресурсы", "인사", "Nhân sự", "Human Resources")
t("I-9 Status", "Estati I-9", "Статус I-9", "I-9 상태", "Trạng thái I-9", "I-9 Status")
t("IICRC-compliant deployment tracking and billing", "Swiv deplwayman ak faktirasyon konfòm ak IICRC", "Отслеживание по стандартам IICRC", "IICRC 준수 배치 추적 및 청구", "Theo dõi triển khai và thanh toán theo IICRC", "IICRC-compliant na deployment tracking at billing")
t("Import .esx", "Enpòte .esx", "Импорт .esx", ".esx 가져오기", "Nhập .esx", "Mag-import ng .esx")
t("Import / Export", "Enpòte / Ekspòte", "Импорт / Экспорт", "가져오기/내보내기", "Nhập / Xuất", "Import / Export")
t("Import Complete", "Enpòtasyon Konplè", "Импорт завершён", "가져오기 완료", "Nhập hoàn tất", "Kumpleto na ang Import")
t("Import Xactimate Estimate", "Enpòte Estimasyon Xactimate", "Импортировать смету Xactimate", "Xactimate 견적 가져오기", "Nhập dự toán Xactimate", "Mag-import ng Xactimate Estimate")
t("Import from Recon", "Enpòte nan Rekon", "Импорт из Рекон", "정찰에서 가져오기", "Nhập từ Recon", "Mag-import mula sa Recon")
t("Importing...", "Ap enpòte...", "Импорт...", "가져오는 중...", "Đang nhập...", "Nag-i-import...")
t("In Maintenance", "An Antretyen", "На обслуживании", "유지보수 중", "Đang bảo trì", "Nasa Maintenance")
t("In Pipeline", "Nan Pipeline", "В воронке", "파이프라인 내", "Trong kênh", "Nasa Pipeline")
t("In Production", "An Pwodiksyon", "В производстве", "생산 중", "Đang sản xuất", "Nasa Production")
t("In-App", "Nan App", "В приложении", "앱 내", "Trong ứng dụng", "Sa App")
t("Indoor", "Anndan", "Внутри", "실내", "Trong nhà", "Indoor")
t("Inspection Required", "Enspeksyon Nesesè", "Требуется инспекция", "검사 필요", "Yêu cầu kiểm tra", "Kailangan ng Inspeksyon")
t("Inspection Scheduled", "Enspeksyon Planifye", "Инспекция запланирована", "검사 예정", "Đã lên lịch kiểm tra", "Naka-schedule na Inspeksyon")
t("Inspection Templates", "Modèl Enspeksyon", "Шаблоны инспекций", "검사 템플릿", "Mẫu kiểm tra", "Mga Template ng Inspeksyon")
t("Inspection not found", "Enspeksyon pa jwenn", "Инспекция не найдена", "검사를 찾을 수 없음", "Không tìm thấy kiểm tra", "Hindi nahanap ang inspeksyon")
t("Insurance Expiry", "Ekspirasyon Asirans", "Истечение страховки", "보험 만료", "Hết hạn bảo hiểm", "Pag-expire ng Insurance")
t("Insurance carriers served by this TPA", "Konpayi asirans sèvi pa TPA sa a", "Страховые компании этого ТПА", "이 TPA가 서비스하는 보험사", "Các hãng bảo hiểm được TPA này phục vụ", "Mga insurance carrier na sineserbisyuhan ng TPA na ito")
t("Interactive map showing job locations and technician positions.", "Kat entèraktif ki montre pozisyon travay ak teknisyen.", "Интерактивная карта с заказами и техниками.", "작업 위치와 기술자 위치를 보여주는 대화형 지도.", "Bản đồ tương tác hiển thị vị trí công việc và kỹ thuật viên.", "Interactive na mapa na nagpapakita ng job location at technician position.")
t("Interview Scheduled", "Entèvyou Planifye", "Собеседование запланировано", "면접 예정", "Đã lên lịch phỏng vấn", "Naka-schedule na Interview")
t("Interviews", "Entèvyou", "Собеседования", "면접", "Phỏng vấn", "Mga Interview")
t("Interviews This Week", "Entèvyou Semèn Sa a", "Собеседования на этой неделе", "이번 주 면접", "Phỏng vấn tuần này", "Mga Interview Ngayong Linggo")
t("Invalid file format.", "Fòma fichye envalid.", "Недопустимый формат файла.", "유효하지 않은 파일 형식.", "Định dạng tệp không hợp lệ.", "Hindi valid ang format ng file.")
t("Investing Activities", "Aktivite Envestisman", "Инвестиционная деятельность", "투자 활동", "Hoạt động đầu tư", "Mga Investing Activity")
t("Invitation sent", "Envitasyon voye", "Приглашение отправлено", "초대 전송됨", "Đã gửi lời mời", "Naipadala na ang imbitasyon")
t("Invitations that haven't been accepted yet", "Envitasyon ki poko aksepte", "Непринятые приглашения", "아직 수락되지 않은 초대", "Lời mời chưa được chấp nhận", "Mga imbitasyong hindi pa tinatanggap")
t("Invite Member", "Envite Manm", "Пригласить участника", "멤버 초대", "Mời thành viên", "Mag-imbita ng Miyembro")
t("Invite Team Member", "Envite Manm Ekip", "Пригласить члена команды", "팀원 초대", "Mời thành viên nhóm", "Mag-imbita ng Team Member")
t("Invoice Numbering", "Nimewo Fakti", "Нумерация счетов", "청구서 번호 체계", "Đánh số hóa đơn", "Invoice Numbering")
t("Invoice Templates", "Modèl Fakti", "Шаблоны счетов", "청구서 템플릿", "Mẫu hóa đơn", "Mga Template ng Invoice")
t("Invoice not found", "Fakti pa jwenn", "Счёт не найден", "청구서를 찾을 수 없음", "Không tìm thấy hóa đơn", "Hindi nahanap ang invoice")
t("Invoices Paid", "Fakti Peye", "Оплаченные счета", "지불된 청구서", "Hóa đơn đã thanh toán", "Mga Nabayarang Invoice")
t("Issuing Authority", "Otorite Emisyon", "Выдавший орган", "발급 기관", "Cơ quan cấp phát", "Issuing Authority")
t("Item", "Atik", "Элемент", "항목", "Mục", "Item")
t("Items Included", "Atik Enkli", "Включённые элементы", "포함 항목", "Hạng mục bao gồm", "Mga Kasamang Item")
t("entries pending approval", "antre ap tann apwobasyon", "записей ожидают утверждения", "승인 대기 항목", "mục chờ phê duyệt", "mga entry na naghihintay ng pag-apruba")
t("entries to review", "antre pou revize", "записей для проверки", "검토할 항목", "mục cần xem xét", "mga entry na kailangang i-review")
# J values
t("Job Assigned", "Travay Asiye", "Заказ назначен", "작업 배정됨", "Công việc đã phân công", "Naka-assign na Trabaho")
t("Job Context", "Kontèks Travay", "Контекст заказа", "작업 컨텍스트", "Bối cảnh công việc", "Job Context")
t("Job Cost Autopsy", "Otopsi Koût Travay", "Анализ затрат заказа", "작업 비용 분석", "Phân tích chi phí công việc", "Job Cost Autopsy")
t("Job Deadline", "Dat Limit Travay", "Крайний срок заказа", "작업 마감일", "Hạn chót công việc", "Job Deadline")
t("Job Documents", "Dokiman Travay", "Документы заказа", "작업 문서", "Tài liệu công việc", "Mga Dokumento ng Trabaho")
t("Job Growth", "Kwasans Travay", "Рост заказов", "작업 증가", "Tăng trưởng công việc", "Job Growth")
t("Job Invoices", "Fakti Travay", "Счета заказа", "작업 청구서", "Hóa đơn công việc", "Mga Invoice ng Trabaho")
t("Job Locations", "Kote Travay", "Местоположения заказов", "작업 위치", "Vị trí công việc", "Mga Lokasyon ng Trabaho")
t("Job Materials", "Materyèl Travay", "Материалы заказа", "작업 자재", "Vật liệu công việc", "Mga Materyales ng Trabaho")
t("Job Numbering", "Nimewo Travay", "Нумерация заказов", "작업 번호 체계", "Đánh số công việc", "Job Numbering")
t("Job Permits", "Pèmi Travay", "Разрешения заказа", "작업 허가", "Giấy phép công việc", "Mga Permit ng Trabaho")
t("Job Postings", "Piblikasyon Travay", "Вакансии", "채용 공고", "Tin tuyển dụng", "Mga Job Posting")
t("Job Status", "Estati Travay", "Статус заказа", "작업 상태", "Trạng thái công việc", "Status ng Trabaho")
t("Job Tasks", "Tach Travay", "Задачи заказа", "작업 태스크", "Nhiệm vụ công việc", "Mga Task ng Trabaho")
t("Job Title", "Tit Pòs", "Должность", "직위", "Chức danh", "Titulo ng Trabaho")
t("Job Type", "Tip Travay", "Тип заказа", "작업 유형", "Loại công việc", "Uri ng Trabaho")
t("Job not found", "Travay pa jwenn", "Заказ не найден", "작업을 찾을 수 없음", "Không tìm thấy công việc", "Hindi nahanap ang trabaho")
t("Job site same as customer address", "Sit travay menm ak adrès kliyan", "Адрес объекта совпадает с адресом клиента", "작업 현장이 고객 주소와 동일", "Địa điểm công việc giống với địa chỉ khách hàng", "Pareho ang job site sa address ng customer")
t("Job-level budgeting and variance reporting", "Bidjè nivo travay ak rapòtaj varyans", "Бюджетирование и отчёт об отклонениях по заказам", "작업 수준 예산 및 차이 보고", "Lập ngân sách cấp công việc và báo cáo chênh lệch", "Job-level budgeting at variance reporting")
t("Jobs Covered", "Travay Kouvri", "Покрытые заказы", "보장 작업", "Công việc được bảo hiểm", "Mga Covered na Trabaho")
t("Jobs In Progress", "Travay An Kou", "Заказы в работе", "진행 중인 작업", "Công việc đang thực hiện", "Mga Trabahong In Progress")
t("Jobs Won", "Travay Genyen", "Выигранные заказы", "수주 작업", "Công việc đã thắng", "Mga Naipanalo na Trabaho")
t("Jobs by Status", "Travay pa Estati", "Заказы по статусу", "상태별 작업", "Công việc theo trạng thái", "Mga Trabaho ayon sa Status")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
