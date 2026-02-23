#!/usr/bin/env python3
"""5-language batch 23: U values"""
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

t("Unable to Join", "Pa Kapab Rejwenn", "Не удаётся присоединиться", "참여 불가", "Không thể tham gia", "Hindi Makapag-join")
t("Unassign", "Dezasiye", "Снять назначение", "배정 해제", "Hủy phân công", "I-unassign")
t("Unassigned Jobs", "Travay San Asiyman", "Неназначенные заказы", "미배정 작업", "Công việc chưa phân công", "Mga Walang Assignment na Trabaho")
t("Unavailable", "Pa Disponib", "Недоступен", "불가", "Không khả dụng", "Hindi Available")
t("Uncategorized", "San Kategori", "Без категории", "미분류", "Chưa phân loại", "Walang Kategorya")
t("Under Review", "An Revizyon", "На рассмотрении", "검토 중", "Đang xem xét", "Nasa Review")
t("Under Warranty", "Anba Garanti", "На гарантии", "보증 기간 중", "Đang bảo hành", "Nasa Warranty")
t("Unflag", "Retire Drapo", "Снять отметку", "플래그 해제", "Bỏ đánh dấu", "I-unflag")
t("Unfollow", "Pa Swiv", "Отписаться", "팔로우 해제", "Bỏ theo dõi", "I-unfollow")
t("Uniform Size", "Gwosè Inifòm", "Размер формы", "유니폼 사이즈", "Cỡ đồng phục", "Laki ng Uniporme")
t("Unit", "Inite", "Юнит", "유닛", "Đơn vị", "Unit")
t("Unit $", "Inite $", "Юнит $", "단가 $", "Đơn vị $", "Unit $")
t("Unit / Property", "Inite / Pwopriyete", "Юнит / Объект", "유닛 / 부동산", "Đơn vị / Bất động sản", "Unit / Property")
t("Unit Assets", "Aktif Inite", "Активы юнита", "유닛 자산", "Tài sản đơn vị", "Mga Asset ng Unit")
t("Unit Cost", "Koût Inite", "Стоимость за единицу", "단가", "Chi phí đơn vị", "Gastos ng Unit")
t("Unit Details", "Detay Inite", "Детали юнита", "유닛 상세", "Chi tiết đơn vị", "Detalye ng Unit")
t("Unit ID", "ID Inite", "ID юнита", "유닛 ID", "Mã đơn vị", "Unit ID")
t("Unit Price", "Pri Inite", "Цена за единицу", "단가", "Đơn giá", "Presyo ng Unit")
t("Unit Turns", "Tounen Inite", "Обороты юнита", "유닛 턴오버", "Luân chuyển đơn vị", "Unit Turns")
t("Unit not found", "Inite pa jwenn", "Юнит не найден", "유닛을 찾을 수 없음", "Không tìm thấy đơn vị", "Hindi nahanap ang unit")
t("Units", "Inite", "Юниты", "유닛", "Đơn vị", "Mga Unit")
t("Unknown", "Enkoni", "Неизвестно", "알 수 없음", "Không xác định", "Hindi Alam")
t("Unlink", "Dekonekte", "Отвязать", "연결 해제", "Hủy liên kết", "I-unlink")
t("Unmute", "Rann Son", "Включить звук", "음소거 해제", "Bật tiếng", "I-unmute")
t("Unpaid", "Pa Peye", "Неоплаченный", "미지급", "Chưa thanh toán", "Hindi Nabayaran")
t("Unpaid Bills", "Biy Pa Peye", "Неоплаченные счета", "미지급 청구서", "Hóa đơn chưa thanh toán", "Mga Hindi Nabayarang Bill")
t("Unpin", "Depingle", "Открепить", "고정 해제", "Bỏ ghim", "I-unpin")
t("Unpublish", "Depbliye", "Снять с публикации", "게시 취소", "Hủy xuất bản", "I-unpublish")
t("Unreconciled Accounts", "Kont Pa Rekonsilye", "Несверенные счета", "미조정 계정", "Tài khoản chưa đối chiếu", "Mga Hindi Na-reconcile na Account")
t("Unreviewed Transactions", "Tranzaksyon Pa Revize", "Непроверенные транзакции", "미검토 거래", "Giao dịch chưa xem xét", "Mga Hindi Na-review na Transaksyon")
t("Unstar", "Retire Zetwal", "Убрать звезду", "별표 해제", "Bỏ gắn sao", "I-unstar")
t("Unverified", "Pa Verifye", "Неподтверждённый", "미인증", "Chưa xác minh", "Hindi Na-verify")
t("Upcoming Inspections", "Enspeksyon k Ap Vini", "Предстоящие инспекции", "예정 검사", "Kiểm tra sắp tới", "Mga Paparating na Inspection")
t("Upcoming Schedule", "Orè k Ap Vini", "Предстоящее расписание", "예정 일정", "Lịch sắp tới", "Paparating na Schedule")
t("Upcoming Services", "Sèvis k Ap Vini", "Предстоящие услуги", "예정 서비스", "Dịch vụ sắp tới", "Mga Paparating na Serbisyo")
t("Update Status", "Mete Ajou Estati", "Обновить статус", "상태 업데이트", "Cập nhật trạng thái", "I-update ang Status")
t("Update your password", "Mete ajou modpas ou", "Обновите пароль", "비밀번호를 업데이트하세요", "Cập nhật mật khẩu", "I-update ang password mo")
t("Update your personal details", "Mete ajou detay pèsonèl ou", "Обновите личные данные", "개인 정보를 업데이트하세요", "Cập nhật thông tin cá nhân", "I-update ang personal details mo")
t("Upgrade", "Amelyore", "Улучшить", "업그레이드", "Nâng cấp", "Mag-upgrade")
t("Upgrade Items", "Atik Amelyorasyon", "Элементы улучшения", "업그레이드 항목", "Mục nâng cấp", "Mga Upgrade Item")
t("Upgrade Plan", "Plan Amelyorasyon", "Улучшить план", "요금제 업그레이드", "Nâng cấp gói", "Mag-upgrade ng Plan")
t("Upload Document", "Chaje Dokiman", "Загрузить документ", "문서 업로드", "Tải lên tài liệu", "Mag-upload ng Document")
t("Upload Photos", "Chaje Foto", "Загрузить фото", "사진 업로드", "Tải lên ảnh", "Mag-upload ng Photos")
t("Upload Xactimate PDF", "Chaje PDF Xactimate", "Загрузить PDF Xactimate", "Xactimate PDF 업로드", "Tải lên PDF Xactimate", "Mag-upload ng Xactimate PDF")
t("Upload an Xactimate PDF export to import line items", "Chaje yon ekspòtasyon PDF Xactimate pou enpòte eleman liy", "Загрузите PDF-экспорт Xactimate для импорта позиций", "Xactimate PDF 내보내기를 업로드하여 항목을 가져오세요", "Tải lên bản xuất PDF Xactimate để nhập các mục", "Mag-upload ng Xactimate PDF export para mag-import ng line items")
t("Upload contracts, permits, and other project documents.", "Chaje kontra, pèmi, ak lòt dokiman pwojè.", "Загрузите контракты, разрешения и другие документы проекта.", "계약서, 허가증 및 기타 프로젝트 문서를 업로드하세요.", "Tải lên hợp đồng, giấy phép và các tài liệu dự án khác.", "Mag-upload ng contracts, permits, at iba pang project documents.")
t("Upload failed. Please try again.", "Chajman pa reyisi. Tanpri eseye ankò.", "Загрузка не удалась. Попробуйте снова.", "업로드 실패. 다시 시도해 주세요.", "Tải lên thất bại. Vui lòng thử lại.", "Nabigo ang pag-upload. Pakisubukang muli.")
t("Upload photos to document this job.", "Chaje foto pou dokimante travay sa a.", "Загрузите фото для документирования заказа.", "이 작업을 기록할 사진을 업로드하세요.", "Tải ảnh lên để ghi nhận công việc này.", "Mag-upload ng photos para i-document ang trabahong ito.")
t("Uploaded", "Chaje", "Загружено", "업로드됨", "Đã tải lên", "Na-upload")
t("Urgency", "Ijan", "Срочность", "긴급도", "Mức độ khẩn cấp", "Pagkaapurahan")
t("Urgency:", "Ijan:", "Срочность:", "긴급도:", "Mức độ khẩn cấp:", "Pagkaapurahan:")
t("Usage", "Itilizasyon", "Использование", "사용량", "Sử dụng", "Paggamit")
t("Use an app like Google Authenticator or Authy", "Itilize yon aplikasyon tankou Google Authenticator oswa Authy", "Используйте приложение вроде Google Authenticator или Authy", "Google Authenticator 또는 Authy와 같은 앱을 사용하세요", "Sử dụng ứng dụng như Google Authenticator hoặc Authy", "Gumamit ng app tulad ng Google Authenticator o Authy")
t("Use customer address", "Itilize adrès kliyan", "Использовать адрес клиента", "고객 주소 사용", "Sử dụng địa chỉ khách hàng", "Gamitin ang address ng customer")
t("Used on job", "Itilize sou travay", "Использовано на заказе", "작업에 사용됨", "Đã dùng cho công việc", "Ginamit sa trabaho")
t("User", "Itilizatè", "Пользователь", "사용자", "Người dùng", "User")
t("Utilities", "Sèvis Piblik", "Коммунальные услуги", "유틸리티", "Tiện ích", "Mga Utility")
# lowercase
t("units occupied", "inite okipe", "юнитов заселено", "유닛 점유", "đơn vị đã có người", "mga unit na occupied")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
