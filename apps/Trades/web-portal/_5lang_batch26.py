#!/usr/bin/env python3
"""5-language batch 26: remaining A-C values"""
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

# A remaining
t("Add Psychrometric Reading", "Ajoute Lekti Psikwometrik", "Добавить психрометрическое показание", "건습계 판독 추가", "Thêm số đọc ẩm kế", "Magdagdag ng Psychrometric Reading")
t("Add a new property to your portfolio", "Ajoute yon nouvo pwopriyete nan pòtfòy ou", "Добавьте новый объект в портфель", "포트폴리오에 새 부동산을 추가하세요", "Thêm bất động sản mới vào danh mục", "Magdagdag ng bagong property sa portfolio mo")
t("Add a note about this job...", "Ajoute yon nòt sou travay sa a...", "Добавить заметку об этом заказе...", "이 작업에 대한 메모를 추가하세요...", "Thêm ghi chú về công việc này...", "Magdagdag ng note tungkol sa trabahong ito...")
t("Add an extra layer of security to your account", "Ajoute yon kouch sekirite siplemantè nan kont ou", "Добавьте дополнительный уровень безопасности", "계정에 추가 보안 계층을 추가하세요", "Thêm lớp bảo mật cho tài khoản", "Magdagdag ng karagdagang layer ng seguridad sa account mo")
t("Add customers and complete jobs to see AI-generated growth opportunities", "Ajoute kliyan ak konplete travay pou wè opòtinite kwasans AI jenere", "Добавьте клиентов и завершите заказы, чтобы увидеть возможности роста от ИИ", "고객을 추가하고 작업을 완료하여 AI 생성 성장 기회를 확인하세요", "Thêm khách hàng và hoàn thành công việc để xem cơ hội tăng trưởng do AI tạo", "Magdagdag ng customers at kumpletuhin ang mga trabaho para makita ang AI-generated growth opportunities")
t("Add employee records to manage your workforce.", "Ajoute dosye anplwaye pou jere mendèv ou.", "Добавьте записи сотрудников для управления персоналом.", "직원 기록을 추가하여 인력을 관리하세요.", "Thêm hồ sơ nhân viên để quản lý lực lượng lao động.", "Magdagdag ng employee records para pamahalaan ang workforce mo.")
t("Add materials and supplies to track your inventory", "Ajoute materyèl ak founitè pou swiv envantè ou", "Добавьте материалы и расходники для учёта на складе", "자재 및 소모품을 추가하여 재고를 추적하세요", "Thêm vật liệu và vật tư để theo dõi kho hàng", "Magdagdag ng materials at supplies para i-track ang inventory mo")
t("Add materials to track costs", "Ajoute materyèl pou swiv koût", "Добавьте материалы для учёта расходов", "비용 추적을 위한 자재를 추가하세요", "Thêm vật liệu để theo dõi chi phí", "Magdagdag ng materials para i-track ang costs")
t("Add rooms to standardize what your field crew captures.", "Ajoute chanm pou estandardize sa ekip sou teren ou kaptire.", "Добавьте комнаты для стандартизации данных полевой команды.", "현장 팀이 캡처하는 내용을 표준화하기 위해 방을 추가하세요.", "Thêm phòng để chuẩn hóa nội dung đội hiện trường ghi nhận.", "Magdagdag ng rooms para i-standardize ang kinukuha ng field crew mo.")
t("Add the people who need to sign this document.", "Ajoute moun ki bezwen siyen dokiman sa a.", "Добавьте лиц, которые должны подписать документ.", "이 문서에 서명해야 할 사람을 추가하세요.", "Thêm những người cần ký tài liệu này.", "Idagdag ang mga taong kailangang pumirma sa dokumentong ito.")
t("Add tools and equipment to track checkout/return across your team.", "Ajoute zouti ak ekipman pou swiv prete/retounen nan ekip ou.", "Добавьте инструменты и оборудование для учёта выдачи/возврата.", "도구 및 장비를 추가하여 팀 내 대출/반납을 추적하세요.", "Thêm dụng cụ và thiết bị để theo dõi mượn/trả trong nhóm.", "Magdagdag ng tools at equipment para i-track ang checkout/return sa team mo.")
t("Add warranties to track coverage for your jobs and equipment.", "Ajoute garanti pou swiv kouvèti pou travay ak ekipman ou.", "Добавьте гарантии для отслеживания покрытия работ и оборудования.", "작업 및 장비의 보증 범위를 추적하기 위해 보증을 추가하세요.", "Thêm bảo hành để theo dõi phạm vi bảo hiểm cho công việc và thiết bị.", "Magdagdag ng warranties para i-track ang coverage ng mga trabaho at equipment mo.")
t("Add your first customer to get started.", "Ajoute premye kliyan ou pou kòmanse.", "Добавьте первого клиента, чтобы начать.", "첫 번째 고객을 추가하여 시작하세요.", "Thêm khách hàng đầu tiên để bắt đầu.", "Idagdag ang unang customer mo para magsimula.")
t("Add your first item to get started", "Ajoute premye atik ou pou kòmanse", "Добавьте первую позицию, чтобы начать", "첫 번째 항목을 추가하여 시작하세요", "Thêm mục đầu tiên để bắt đầu", "Idagdag ang unang item mo para magsimula")
t("Add your first lead or adjust your filters", "Ajoute premye pwopriyetè ou oswa ajiste filt ou", "Добавьте первого лида или измените фильтры", "첫 번째 리드를 추가하거나 필터를 조정하세요", "Thêm khách hàng tiềm năng đầu tiên hoặc điều chỉnh bộ lọc", "Idagdag ang unang lead mo o i-adjust ang mga filter")
t("Add your first lead or connect a lead source.", "Ajoute premye pwopriyetè ou oswa konekte yon sous pwopriyetè.", "Добавьте первого лида или подключите источник лидов.", "첫 번째 리드를 추가하거나 리드 소스를 연결하세요.", "Thêm khách hàng tiềm năng đầu tiên hoặc kết nối nguồn khách hàng.", "Idagdag ang unang lead mo o mag-connect ng lead source.")
t("Add your first property to get started.", "Ajoute premye pwopriyete ou pou kòmanse.", "Добавьте первый объект, чтобы начать.", "첫 번째 부동산을 추가하여 시작하세요.", "Thêm bất động sản đầu tiên để bắt đầu.", "Idagdag ang unang property mo para magsimula.")
t("Add your first sub", "Ajoute premye sou-kontraktè ou", "Добавьте первого субподрядчика", "첫 번째 하도급업체를 추가하세요", "Thêm nhà thầu phụ đầu tiên", "Idagdag ang unang sub mo")
t("Additional Terms", "Tèm Adisyonèl", "Дополнительные условия", "추가 조건", "Điều khoản bổ sung", "Mga Karagdagang Tuntunin")
t("Adjusted Grand Total", "Gran Total Ajiste", "Скорректированный итог", "조정된 총합계", "Tổng cộng đã điều chỉnh", "Adjusted Grand Total")
t("Agenda", "Ajennda", "Повестка", "의제", "Chương trình", "Agenda")
t("Agreement Tracker", "Swivi Akò", "Отслеживание договоров", "계약 추적", "Theo dõi thỏa thuận", "Agreement Tracker")
t("Alerts & Action Items", "Alèt & Aksyon", "Оповещения и действия", "알림 및 조치 항목", "Cảnh báo & Hạng mục hành động", "Mga Alert & Action Item")
t("All Locations at Target", "Tout Kote nan Objektif", "Все объекты в целевых значениях", "모든 위치 목표 달성", "Tất cả vị trí đạt mục tiêu", "Lahat ng Lokasyon sa Target")
t("All caught up. No open requests match your filters.", "Tout ajou. Pa gen demand ouvè ki matche ak filt ou.", "Всё актуально. Нет открытых запросов по фильтрам.", "모두 처리 완료. 필터에 맞는 미결 요청이 없습니다.", "Đã xử lý hết. Không có yêu cầu mở nào khớp bộ lọc.", "Wala nang nakabinbing request na tugma sa mga filter mo.")
t("Allocate expenses to properties in Ledger Expenses", "Reparti depans nan pwopriyete nan Depans Kontab", "Распределите расходы по объектам в Расходах журнала", "장부 비용에서 부동산에 비용을 할당하세요", "Phân bổ chi phí cho bất động sản trong Chi phí Sổ cái", "I-allocate ang mga gastos sa properties sa Ledger Expenses")
t("Analyzing equipment data...", "Analize done ekipman...", "Анализ данных оборудования...", "장비 데이터 분석 중...", "Đang phân tích dữ liệu thiết bị...", "Sinusuri ang equipment data...")
t("Angi", "Angi", "Angi", "Angi", "Angi", "Angi")
t("Approved Additions", "Adisyon Apwouve", "Утверждённые дополнения", "승인된 추가 사항", "Bổ sung đã phê duyệt", "Mga Approved Addition")
t("Area Deployed", "Zòn Deplwaye", "Развёрнутая площадь", "배치 구역", "Khu vực triển khai", "Area na Na-deploy")
t("Assignment Not Found", "Asiyman Pa Jwenn", "Назначение не найдено", "배정을 찾을 수 없음", "Không tìm thấy phân công", "Hindi Nahanap ang Assignment")
t("Authenticator App", "Aplikasyon Otantikatè", "Приложение-аутентификатор", "인증 앱", "Ứng dụng xác thực", "Authenticator App")
t("Auto and travel", "Machin ak vwayaj", "Автомобиль и поездки", "차량 및 출장", "Xe và đi lại", "Auto at travel")
t("Auto-Pay Required", "Peman Otomatik Obligatwa", "Требуется автоплатёж", "자동 결제 필요", "Yêu cầu thanh toán tự động", "Kailangan ang Auto-Pay")
t("Auto-renew at end of term", "Renouvle otomatikman nan fen tèm", "Автопродление по окончании срока", "기간 종료 시 자동 갱신", "Tự động gia hạn khi hết hạn", "Auto-renew sa katapusan ng term")
t("Automation Details", "Detay Otomatizasyon", "Детали автоматизации", "자동화 상세", "Chi tiết tự động hóa", "Detalye ng Automation")
t("Avg Adjustment", "Mwayèn Ajisteman", "Средняя корректировка", "평균 조정", "Điều chỉnh trung bình", "Average Adjustment")
t("Avg Days to Ready", "Mwayèn Jou pou Prè", "Среднее дней до готовности", "평균 준비 일수", "Số ngày trung bình đến sẵn sàng", "Average na Araw para Maging Handa")
t("Avg Indoor Humidity", "Mwayèn Imidite Anndan", "Средняя внутренняя влажность", "평균 실내 습도", "Độ ẩm trong nhà trung bình", "Average Indoor Humidity")
t("Avg Open Rate", "Mwayèn To Ouvèti", "Средний процент открытия", "평균 열람률", "Tỷ lệ mở trung bình", "Average Open Rate")
t("Avg Projected Margin", "Mwayèn Maj Projte", "Средняя прогнозируемая маржа", "평균 예상 마진", "Biên lợi nhuận dự kiến trung bình", "Average Projected Margin")
t("Avg Rating", "Mwayèn Evalyasyon", "Средний рейтинг", "평균 평점", "Đánh giá trung bình", "Average Rating")

# B remaining
t("Balance Sheet Detail", "Detay Bilan", "Детали баланса", "대차대조표 상세", "Chi tiết bảng cân đối", "Detalye ng Balance Sheet")
t("Baseline captured", "Liy baz kaptire", "Базовый план сохранён", "기준선 캡처됨", "Đã chụp đường cơ sở", "Na-capture ang baseline")
t("Baselines", "Liy Baz", "Базовые планы", "기준선", "Đường cơ sở", "Mga Baseline")
t("Below Goal", "Anba Objektif", "Ниже цели", "목표 미달", "Dưới mục tiêu", "Nasa Ibaba ng Goal")
t("Bid Event", "Evènman Òf", "Событие заявки", "입찰 이벤트", "Sự kiện đấu thầu", "Bid Event")
t("Bid Notes", "Nòt Òf", "Заметки заявки", "입찰 메모", "Ghi chú đấu thầu", "Mga Bid Note")
t("Bid Overview", "Apèsi Òf", "Обзор заявки", "입찰 개요", "Tổng quan đấu thầu", "Pangkalahatang-tanaw ng Bid")
t("Bid Pending", "Òf An Atant", "Заявка ожидает", "입찰 대기 중", "Đấu thầu đang chờ", "Pending ang Bid")
t("Bid format", "Fòma òf", "Формат заявки", "입찰 형식", "Định dạng đấu thầu", "Format ng bid")
t("Bid not found", "Òf pa jwenn", "Заявка не найдена", "입찰을 찾을 수 없음", "Không tìm thấy đấu thầu", "Hindi nahanap ang bid")
t("Bid validity", "Validite òf", "Срок действия заявки", "입찰 유효 기간", "Hiệu lực đấu thầu", "Validity ng bid")
t("Billing Info", "Enfòmasyon Faktirasyon", "Информация об оплате", "결제 정보", "Thông tin thanh toán", "Impormasyon ng Billing")
t("Billing Settings", "Paramèt Faktirasyon", "Настройки оплаты", "결제 설정", "Cài đặt thanh toán", "Mga Setting ng Billing")
t("Billings to Date", "Faktirasyon Jiska Dat", "Выставлено на дату", "현재까지 청구", "Lập hóa đơn đến ngày", "Billings Hanggang Ngayon")
t("Block", "Bloke", "Блок", "블록", "Khối", "Block")
t("Blueprint", "Plan", "Чертёж", "블루프린트", "Bản thiết kế", "Blueprint")
t("Body", "Kò", "Тело", "본문", "Nội dung", "Nilalaman")
t("Bond", "Obligasyon", "Залог", "보증금", "Bảo lãnh", "Bond")
t("Bonded", "Asire", "Застрахован", "보증됨", "Đã bảo lãnh", "Bonded")
t("Booked", "Rezève", "Забронировано", "예약됨", "Đã đặt", "Naka-book")
t("Booking Rate", "To Rezèvasyon", "Процент бронирования", "예약률", "Tỷ lệ đặt lịch", "Booking Rate")
t("Booking Types", "Tip Rezèvasyon", "Типы бронирования", "예약 유형", "Loại đặt lịch", "Mga Uri ng Booking")
t("Branch Financials", "Finansman Branch", "Финансы филиала", "지점 재무", "Tài chính chi nhánh", "Financials ng Branch")
t("Branch Performance", "Pèfòmans Branch", "Производительность филиала", "지점 성과", "Hiệu suất chi nhánh", "Performance ng Branch")
t("Brand color for buttons and highlights", "Koulè mak pou bouton ak vèdèt", "Цвет бренда для кнопок и акцентов", "버튼 및 강조에 사용할 브랜드 색상", "Màu thương hiệu cho nút và điểm nhấn", "Brand color para sa mga button at highlight")
t("Browse available leads and place your first bid", "Navige pwopriyetè disponib epi mete premye òf ou", "Просмотрите доступных лидов и подайте первую заявку", "사용 가능한 리드를 찾아보고 첫 입찰을 제출하세요", "Duyệt khách hàng tiềm năng và đặt đấu thầu đầu tiên", "I-browse ang mga available lead at maglagay ng unang bid mo")
t("Budget:", "Bidjè:", "Бюджет:", "예산:", "Ngân sách:", "Budget:")
t("Budgeted", "Bidjete", "Бюджетировано", "예산 배정", "Đã lập ngân sách", "Na-budget")
t("Building Department", "Depatman Konstriksyon", "Строительный отдел", "건축 부서", "Sở xây dựng", "Building Department")
t("Built-in roles with default access levels. Assign roles to team members to control what they can see and do.", "Wòl entegre ak nivo aksè pa defo. Asiye wòl bay manm ekip pou kontwole sa yo ka wè ak fè.", "Встроенные роли с уровнями доступа по умолчанию. Назначайте роли для управления доступом.", "기본 접근 수준의 내장 역할입니다. 팀원에게 역할을 할당하여 접근 권한을 제어하세요.", "Vai trò tích hợp với cấp độ truy cập mặc định. Gán vai trò cho thành viên nhóm để kiểm soát quyền truy cập.", "Mga built-in role na may default access levels. Mag-assign ng roles sa team members para i-kontrol ang kanilang access.")
t("Burden", "Chaj", "Нагрузка", "부담", "Gánh nặng", "Pasanin")
t("Burdened Rate", "Tarif Chaje", "Ставка с нагрузкой", "부담 단가", "Đơn giá có phụ phí", "Burdened Rate")
t("Business Information", "Enfòmasyon Biznis", "Информация о бизнесе", "사업 정보", "Thông tin doanh nghiệp", "Impormasyon ng Negosyo")
t("Business Plan Feature", "Fonksyonalite Plan Biznis", "Функция бизнес-плана", "비즈니스 플랜 기능", "Tính năng Gói Doanh nghiệp", "Business Plan Feature")
t("Business analytics and insights", "Analiz biznis ak apèsi", "Бизнес-аналитика и аналитические данные", "비즈니스 분석 및 인사이트", "Phân tích kinh doanh và thông tin chi tiết", "Business analytics at insights")
t("Business days", "Jou ouvrab", "Рабочие дни", "영업일", "Ngày làm việc", "Business days")
t("By Prediction Type", "Pa Tip Prediksyon", "По типу прогноза", "예측 유형별", "Theo loại dự đoán", "Ayon sa Prediction Type")

# C remaining (first part)
t("CAD floor plans with trade layers, 3D view, and auto-generated estimates", "Plan etaj CAD ak kouch metye, vi 3D, ak estimasyon otomatik", "САПР-планы с профильными слоями, 3D-видом и автоматическими сметами", "공종 레이어, 3D 뷰, 자동 생성 견적이 포함된 CAD 도면", "Bản vẽ CAD với lớp chuyên ngành, chế độ xem 3D và dự toán tự động", "CAD floor plans na may trade layers, 3D view, at auto-generated estimates")
t("CC", "CC", "Копия", "참조", "CC", "CC")
t("CE Credit Tracking", "Swivi Kredi CE", "Отслеживание кредитов CE", "CE 학점 추적", "Theo dõi tín chỉ CE", "CE Credit Tracking")
t("CE Tracking", "Swivi CE", "Отслеживание CE", "CE 추적", "Theo dõi CE", "CE Tracking")
t("COGS", "COGS", "Себестоимость", "매출원가", "Giá vốn hàng bán", "COGS")
t("CPA", "CPA", "Бухгалтер", "공인 회계사", "Kế toán công", "CPA")
t("CPA Export Package", "Pakè Ekspòtasyon CPA", "Пакет экспорта для бухгалтера", "CPA 내보내기 패키지", "Gói xuất CPA", "CPA Export Package")
t("Call logs will appear here when you make or receive calls.", "Jounal apèl ap parèt isit la lè ou fè oswa resevwa apèl.", "Журнал звонков появится при совершении или получении звонков.", "전화를 걸거나 받으면 통화 기록이 여기에 표시됩니다.", "Nhật ký cuộc gọi sẽ xuất hiện ở đây khi bạn thực hiện hoặc nhận cuộc gọi.", "Lalabas dito ang mga call log kapag tumawag ka o tumanggap ng tawag.")
t("Calls will appear here once your phone system is active", "Apèl ap parèt isit la yon fwa sistèm telefòn ou aktif", "Звонки появятся здесь при активации телефонной системы", "전화 시스템이 활성화되면 통화가 여기에 표시됩니다", "Cuộc gọi sẽ xuất hiện ở đây khi hệ thống điện thoại hoạt động", "Lalabas dito ang mga tawag kapag active na ang phone system mo")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
