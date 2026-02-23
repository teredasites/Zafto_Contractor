#!/usr/bin/env python3
"""5-language batch 13: 'No ...' strings part 3 + remaining N values"""
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

t("No review requests found", "Pa gen demann revizyon jwenn", "Запросы на отзыв не найдены", "리뷰 요청을 찾을 수 없음", "Không tìm thấy yêu cầu đánh giá", "Walang nahanap na review request")
t("No reviews yet", "Pa gen revizyon ankò", "Нет отзывов", "아직 리뷰 없음", "Chưa có đánh giá", "Wala pang review")
t("No rooms defined", "Pa gen pyès defini", "Нет определённых комнат", "정의된 방 없음", "Chưa định nghĩa phòng", "Walang nakatakdang room")
t("No rooms or line items yet", "Pa gen pyès oswa atik liy ankò", "Нет комнат или позиций", "아직 방 또는 항목 없음", "Chưa có phòng hoặc mục hàng", "Wala pang room o line item")
t("No rooms recorded", "Pa gen pyès anrejistre", "Нет записанных комнат", "기록된 방 없음", "Chưa ghi nhận phòng", "Walang nairecord na room")
t("No samples collected", "Pa gen echantiyon kolekte", "Нет собранных образцов", "수집된 샘플 없음", "Chưa thu thập mẫu", "Walang nakolektang sample")
t("No schedules yet", "Pa gen orè ankò", "Нет расписаний", "아직 일정 없음", "Chưa có lịch trình", "Wala pang schedule")
t("No scorecards yet", "Pa gen fich pwen ankò", "Нет карточек показателей", "아직 스코어카드 없음", "Chưa có bảng điểm", "Wala pang scorecard")
t("No sent emails found", "Pa gen imèl voye jwenn", "Отправленные письма не найдены", "전송된 이메일을 찾을 수 없음", "Không tìm thấy email đã gửi", "Walang nahanap na naipadala na email")
t("No service agreements found", "Pa gen akò sèvis jwenn", "Договоры обслуживания не найдены", "서비스 계약을 찾을 수 없음", "Không tìm thấy thỏa thuận dịch vụ", "Walang nahanap na service agreement")
t("No service data yet. Tag your jobs to see service breakdowns.", "Pa gen done sèvis ankò. Make travay ou pou wè dekoupaj sèvis.", "Нет данных об услугах. Тегируйте заказы для разбивки.", "아직 서비스 데이터 없음. 작업에 태그를 지정하여 서비스 분석을 확인하세요.", "Chưa có dữ liệu dịch vụ. Gắn thẻ công việc để xem phân tích dịch vụ.", "Wala pang service data. I-tag ang mga trabaho para makita ang service breakdown.")
t("No service records", "Pa gen dosye sèvis", "Нет записей обслуживания", "서비스 기록 없음", "Không có hồ sơ dịch vụ", "Walang service record")
t("No signature requests found", "Pa gen demann siyati jwenn", "Запросы подписи не найдены", "서명 요청을 찾을 수 없음", "Không tìm thấy yêu cầu chữ ký", "Walang nahanap na signature request")
t("No site surveys found", "Pa gen sondaj sit jwenn", "Обследования площадки не найдены", "현장 조사를 찾을 수 없음", "Không tìm thấy khảo sát hiện trường", "Walang nahanap na site survey")
t("No sketches yet", "Pa gen eskis ankò", "Нет эскизов", "아직 스케치 없음", "Chưa có bản phác thảo", "Wala pang sketch")
t("No sources", "Pa gen sous", "Нет источников", "소스 없음", "Không có nguồn", "Walang source")
t("No standards found", "Pa gen estanda jwenn", "Стандарты не найдены", "기준을 찾을 수 없음", "Không tìm thấy tiêu chuẩn", "Walang nahanap na standard")
t("No subcontractors found", "Pa gen sou-kontraktè jwenn", "Субподрядчики не найдены", "하도급업체를 찾을 수 없음", "Không tìm thấy nhà thầu phụ", "Walang nahanap na subcontractor")
t("No surveys yet. Create one to start documenting site conditions.", "Pa gen sondaj ankò. Kreye youn pou kòmanse dokimante kondisyon sit.", "Нет обследований. Создайте для документирования условий.", "아직 조사 없음. 현장 상태 문서화를 시작하려면 하나를 생성하세요.", "Chưa có khảo sát. Tạo một khảo sát để bắt đầu ghi nhận điều kiện hiện trường.", "Wala pang survey. Gumawa ng isa para simulang i-dokumento ang site condition.")
t("No tags", "Pa gen etikèt", "Нет тегов", "태그 없음", "Không có thẻ", "Walang tag")
t("No tags added", "Pa gen etikèt ajoute", "Теги не добавлены", "추가된 태그 없음", "Chưa thêm thẻ", "Walang idinagdag na tag")
t("No tasks added yet", "Pa gen travay ajoute ankò", "Задачи ещё не добавлены", "아직 추가된 작업 없음", "Chưa thêm nhiệm vụ", "Wala pang idinagdag na task")
t("No tasks scheduled", "Pa gen travay planifye", "Нет запланированных задач", "예정된 작업 없음", "Chưa lên lịch nhiệm vụ", "Walang naka-schedule na task")
t("No tasks yet", "Pa gen travay ankò", "Задач ещё нет", "아직 작업 없음", "Chưa có nhiệm vụ", "Wala pang task")
t("No team data available", "Pa gen done ekip disponib", "Нет данных о команде", "팀 데이터 없음", "Không có dữ liệu nhóm", "Walang available na team data")
t("No team members assigned", "Pa gen manm ekip asiye", "Нет назначенных сотрудников", "배정된 팀원 없음", "Chưa phân công thành viên nhóm", "Walang naka-assign na team member")
t("No team members found", "Pa gen manm ekip jwenn", "Члены команды не найдены", "팀원을 찾을 수 없음", "Không tìm thấy thành viên nhóm", "Walang nahanap na team member")
t("No team members yet", "Pa gen manm ekip ankò", "Нет членов команды", "아직 팀원 없음", "Chưa có thành viên nhóm", "Wala pang team member")
t("No technicians with GPS data", "Pa gen teknisyen ak done GPS", "Нет техников с GPS-данными", "GPS 데이터가 있는 기술자 없음", "Không có kỹ thuật viên có dữ liệu GPS", "Walang technician na may GPS data")
t("No techs available", "Pa gen teknisyen disponib", "Нет доступных техников", "가용 기술자 없음", "Không có kỹ thuật viên sẵn sàng", "Walang available na tech")
t("No templates created yet", "Pa gen modèl kreye ankò", "Шаблоны ещё не созданы", "아직 생성된 템플릿 없음", "Chưa tạo mẫu", "Wala pang nagawang template")
t("No templates found", "Pa gen modèl jwenn", "Шаблоны не найдены", "템플릿을 찾을 수 없음", "Không tìm thấy mẫu", "Walang nahanap na template")
t("No templates found. Create one to get started.", "Pa gen modèl jwenn. Kreye youn pou kòmanse.", "Шаблоны не найдены. Создайте первый.", "템플릿을 찾을 수 없음. 시작하려면 하나를 생성하세요.", "Không tìm thấy mẫu. Tạo một mẫu để bắt đầu.", "Walang nahanap na template. Gumawa ng isa para magsimula.")
t("No templates saved yet", "Pa gen modèl sove ankò", "Шаблоны ещё не сохранены", "아직 저장된 템플릿 없음", "Chưa lưu mẫu", "Wala pang nai-save na template")
t("No tenants", "Pa gen lokatè", "Нет арендаторов", "세입자 없음", "Không có người thuê", "Walang tenant")
t("No tenants found", "Pa gen lokatè jwenn", "Арендаторы не найдены", "세입자를 찾을 수 없음", "Không tìm thấy người thuê", "Walang nahanap na tenant")
t("No time entries for this week", "Pa gen antre tan pou semèn sa a", "Нет записей за эту неделю", "이번 주 시간 기록 없음", "Không có mục thời gian cho tuần này", "Walang time entry para sa linggong ito")
t("No time entries yet", "Pa gen antre tan ankò", "Нет записей времени", "아직 시간 기록 없음", "Chưa có mục thời gian", "Wala pang time entry")
t("No tools found", "Pa gen zouti jwenn", "Инструменты не найдены", "도구를 찾을 수 없음", "Không tìm thấy dụng cụ", "Walang nahanap na tool")
t("No trade data found for this property scan.", "Pa gen done metye jwenn pou eskanè pwopriyete sa a.", "Нет данных о специальностях для этого скана.", "이 부동산 스캔의 공종 데이터 없음.", "Không tìm thấy dữ liệu ngành cho bản quét bất động sản này.", "Walang nahanap na trade data para sa property scan na ito.")
t("No training records found", "Pa gen dosye fòmasyon jwenn", "Записи об обучении не найдены", "교육 기록을 찾을 수 없음", "Không tìm thấy hồ sơ đào tạo", "Walang nahanap na training record")
t("No unassigned jobs", "Pa gen travay pa asiye", "Нет неназначенных заказов", "미배정 작업 없음", "Không có công việc chưa phân công", "Walang hindi naka-assign na trabaho")
t("No units", "Pa gen inite", "Нет помещений", "유닛 없음", "Không có đơn vị", "Walang unit")
t("No units added yet", "Pa gen inite ajoute ankò", "Помещения ещё не добавлены", "아직 추가된 유닛 없음", "Chưa thêm đơn vị", "Wala pang idinagdag na unit")
t("No units found", "Pa gen inite jwenn", "Помещения не найдены", "유닛을 찾을 수 없음", "Không tìm thấy đơn vị", "Walang nahanap na unit")
t("No unsubscribes", "Pa gen dezabònman", "Нет отписок", "구독 취소 없음", "Không có hủy đăng ký", "Walang nag-unsubscribe")
t("No upcoming predictions", "Pa gen prediksyon ap vini", "Нет предстоящих прогнозов", "다가오는 예측 없음", "Không có dự đoán sắp tới", "Walang paparating na prediction")
t("No vehicles found", "Pa gen machin jwenn", "Транспорт не найден", "차량을 찾을 수 없음", "Không tìm thấy phương tiện", "Walang nahanap na sasakyan")
t("No vendors found", "Pa gen vandè jwenn", "Поставщики не найдены", "거래처를 찾을 수 없음", "Không tìm thấy nhà cung cấp", "Walang nahanap na vendor")
t("No vendors yet", "Pa gen vandè ankò", "Нет поставщиков", "아직 거래처 없음", "Chưa có nhà cung cấp", "Wala pang vendor")
t("No voicemails", "Pa gen mesaj vokal", "Нет голосовых сообщений", "음성 메시지 없음", "Không có tin nhắn thoại", "Walang voicemail")
t("No walkthroughs found", "Pa gen vizit jwenn", "Обходы не найдены", "현장 조사를 찾을 수 없음", "Không tìm thấy khảo sát", "Walang nahanap na walkthrough")
t("No walkthroughs yet", "Pa gen vizit ankò", "Нет обходов", "아직 현장 조사 없음", "Chưa có khảo sát", "Wala pang walkthrough")
t("No warranties found", "Pa gen garanti jwenn", "Гарантии не найдены", "보증을 찾을 수 없음", "Không tìm thấy bảo hành", "Walang nahanap na garantiya")
t("No warranty data available", "Pa gen done garanti disponib", "Нет данных о гарантии", "보증 데이터 없음", "Không có dữ liệu bảo hành", "Walang available na warranty data")
t("Non-Billable", "Pa Faktirab", "Невыставляемый", "비청구", "Không tính phí", "Hindi Billable")
t("None deployed", "Okenn deplwaye", "Не развёрнуто", "배치 없음", "Chưa triển khai", "Walang na-deploy")
t("Normal", "Nòmal", "Нормальный", "보통", "Bình thường", "Normal")
t("Not Connected", "Pa Konekte", "Не подключено", "연결 안됨", "Chưa kết nối", "Hindi Connected")
t("Not Started", "Pa Kòmanse", "Не начато", "시작 안됨", "Chưa bắt đầu", "Hindi pa Nasimulan")
t("Not provided", "Pa bay", "Не указано", "제공되지 않음", "Không cung cấp", "Hindi ibinigay")
t("Not recorded", "Pa anrejistre", "Не записано", "기록 안됨", "Chưa ghi nhận", "Hindi nairecord")
t("Not required", "Pa obligatwa", "Не требуется", "필수 아님", "Không bắt buộc", "Hindi kinakailangan")
t("Notarization", "Notarizasyon", "Нотариальное заверение", "공증", "Công chứng", "Notarization")
t("Notarization required", "Notarizasyon obligatwa", "Требуется нотариальное заверение", "공증 필요", "Yêu cầu công chứng", "Kailangan ng notarization")
t("Notarize", "Notarize", "Заверить нотариально", "공증하다", "Công chứng", "I-notarize")
t("Note", "Nòt", "Заметка", "메모", "Ghi chú", "Tala")
t("Notice Required", "Avi Nesesè", "Требуется уведомление", "통지 필요", "Yêu cầu thông báo", "Kailangan ng Abiso")
t("Notice of Intent required", "Avi Entansyon obligatwa", "Требуется уведомление о намерении", "의향서 필요", "Yêu cầu thông báo ý định", "Kailangan ng Notice of Intent")
t("Notice to Owner", "Avi bay Pwopriyetè", "Уведомление собственнику", "소유자 통지", "Thông báo cho chủ sở hữu", "Abiso sa May-ari")
t("Notices Sent", "Avi Voye", "Уведомления отправлены", "전송된 통지", "Thông báo đã gửi", "Mga Naipadala na Abiso")
t("Notification", "Notifikasyon", "Уведомление", "알림", "Thông báo", "Notification")
t("Notification Settings", "Paramèt Notifikasyon", "Настройки уведомлений", "알림 설정", "Cài đặt thông báo", "Mga Setting ng Notification")
t("Notify Team", "Notifye Ekip", "Уведомить команду", "팀 알림", "Thông báo nhóm", "I-notify ang Team")
t("Number", "Nimewo", "Номер", "번호", "Số", "Numero")
t("Numbering & Formatting", "Nimewo & Fòmataj", "Нумерация и форматирование", "번호 체계 및 형식", "Đánh số & Định dạng", "Numbering & Formatting")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
