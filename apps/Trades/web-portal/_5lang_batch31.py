#!/usr/bin/env python3
"""5-language batch 31: remaining J values + all scattered short/common values"""
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

# J values
t("Job #", "Travay #", "Заказ #", "작업 #", "Công việc #", "Job #")
t("Job / Customer", "Travay / Kliyan", "Заказ / Клиент", "작업 / 고객", "Công việc / Khách hàng", "Job / Customer")
t("Job Completion", "Konpletman Travay", "Завершение заказа", "작업 완료", "Hoàn thành công việc", "Pagkumpleto ng Job")
t("Job Cost", "Kou Travay", "Стоимость заказа", "작업 비용", "Chi phí công việc", "Gastos ng Job")
t("Job Cost Radar", "Rada Kou Travay", "Радар стоимости заказа", "작업 비용 레이더", "Radar chi phí công việc", "Job Cost Radar")
t("Job Details", "Detay Travay", "Детали заказа", "작업 상세", "Chi tiết công việc", "Detalye ng Job")
t("Job History", "Istwa Travay", "История заказа", "작업 이력", "Lịch sử công việc", "History ng Job")
t("Job Info", "Enfò Travay", "Информация о заказе", "작업 정보", "Thông tin công việc", "Impormasyon ng Job")
t("Job Intelligence", "Entèlijans Travay", "Аналитика заказов", "작업 인텔리전스", "Phân tích công việc", "Job Intelligence")
t("Job Name", "Non Travay", "Название заказа", "작업명", "Tên công việc", "Pangalan ng Job")
t("Job Notes", "Nòt Travay", "Заметки по заказу", "작업 메모", "Ghi chú công việc", "Mga Tala ng Job")
t("Job Overview", "Apèsi Travay", "Обзор заказа", "작업 개요", "Tổng quan công việc", "Pangkalahatang-tanaw ng Job")
t("Job Photos", "Foto Travay", "Фотографии заказа", "작업 사진", "Ảnh công việc", "Mga Larawan ng Job")
t("Job Site Address", "Adrès Chantye", "Адрес объекта", "현장 주소", "Địa chỉ công trường", "Address ng Job Site")
t("Job Status Change", "Chanjman Estati Travay", "Изменение статуса заказа", "작업 상태 변경", "Thay đổi trạng thái công việc", "Pagbabago ng Job Status")
t("Job Timeline", "Kalandriye Travay", "Хронология заказа", "작업 타임라인", "Dòng thời gian công việc", "Timeline ng Job")
t("Job-Level Breakdown", "Detay pa Travay", "Разбивка по заказам", "작업별 내역", "Phân tích theo công việc", "Breakdown ayon sa Job")
t("Job-Level Profitability", "Rentabilite pa Travay", "Рентабельность по заказам", "작업별 수익성", "Lợi nhuận theo công việc", "Profitability ayon sa Job")
t("John Smith", "John Smith", "John Smith", "John Smith", "John Smith", "John Smith")
t("Joining meeting...", "Ap antre nan reyinyon...", "Подключение к встрече...", "회의 참가 중...", "Đang tham gia cuộc họp...", "Sumasali sa meeting...")
t("Jurisdiction", "Jiridiksyon", "Юрисдикция", "관할 구역", "Khu vực pháp lý", "Hurisdiksyon")
t("Jurisdictions", "Jiridiksyon", "Юрисдикции", "관할 구역", "Khu vực pháp lý", "Mga Hurisdiksyon")

# Remaining A values
t("Actions", "Aksyon", "Действия", "작업", "Hành động", "Mga Aksyon")
t("Active Jobs", "Travay Aktif", "Активные заказы", "진행 중 작업", "Công việc đang hoạt động", "Mga Active na Job")
t("All clear", "Tout klè", "Всё в порядке", "이상 없음", "Tất cả bình thường", "Malinaw lahat")
t("Are you sure?", "Èske ou sèten?", "Вы уверены?", "정말 진행하시겠습니까?", "Bạn có chắc không?", "Sigurado ka ba?")
t("Assigned", "Asiyen", "Назначен", "배정됨", "Đã phân công", "Naka-assign")

# Remaining B values
t("Back", "Retounen", "Назад", "뒤로", "Quay lại", "Bumalik")
t("Balance", "Balans", "Баланс", "잔액", "Số dư", "Balanse")
t("Business", "Biznis", "Бизнес", "사업", "Doanh nghiệp", "Negosyo")

# Remaining C values
t("Changes saved", "Chanjman anrejistre", "Изменения сохранены", "변경 사항이 저장되었습니다", "Đã lưu thay đổi", "Na-save ang mga pagbabago")
t("Communications", "Kominikasyon", "Коммуникации", "커뮤니케이션", "Truyền thông", "Mga Komunikasyon")
t("Compliance", "Konfòmite", "Соответствие", "컴플라이언스", "Tuân thủ", "Compliance")
t("Confirm", "Konfime", "Подтвердить", "확인", "Xác nhận", "Kumpirmahin")
t("Create Estimate", "Kreye Estimasyon", "Создать смету", "견적 생성", "Tạo báo giá", "Gumawa ng Estimate")
t("Create Invoice", "Kreye Fakti", "Создать счёт", "청구서 생성", "Tạo hóa đơn", "Gumawa ng Invoice")
t("Create Job", "Kreye Travay", "Создать заказ", "작업 생성", "Tạo công việc", "Gumawa ng Job")
t("Custom", "Pèsonalize", "Пользовательский", "사용자 정의", "Tùy chỉnh", "Custom")

# Remaining D values
t("Discount", "Rabè", "Скидка", "할인", "Giảm giá", "Diskwento")
t("Dispatch", "Ekspedisyon", "Диспетчеризация", "배차", "Điều phối", "Dispatch")

# Remaining L values
t("Leads", "Pwopriyetè", "Лиды", "리드", "Khách hàng tiềm năng", "Mga Lead")
t("Loading...", "Ap chaje...", "Загрузка...", "로딩 중...", "Đang tải...", "Naglo-load...")
t("Location", "Anplasman", "Местоположение", "위치", "Vị trí", "Lokasyon")

# Remaining M values
t("Margin", "Maj", "Маржа", "마진", "Biên lợi nhuận", "Margin")

# Remaining N values
t("New", "Nouvo", "Новый", "신규", "Mới", "Bago")
t("New Estimate", "Nouvo Estimasyon", "Новая смета", "새 견적", "Báo giá mới", "Bagong Estimate")
t("No estimates found", "Pa gen estimasyon jwenn", "Сметы не найдены", "견적이 없습니다", "Không tìm thấy báo giá", "Walang nahanap na estimate")
t("No jobs found", "Pa gen travay jwenn", "Заказы не найдены", "작업이 없습니다", "Không tìm thấy công việc", "Walang nahanap na job")
t("No results found", "Pa gen rezilta jwenn", "Результаты не найдены", "결과가 없습니다", "Không tìm thấy kết quả", "Walang nahanap na resulta")

# Remaining O values
t("ON", "AKTIVE", "ВКЛ", "켜짐", "BẬT", "BUKAS")
t("Operations", "Operasyon", "Операции", "운영", "Vận hành", "Mga Operasyon")
t("Other", "Lòt", "Другое", "기타", "Khác", "Iba pa")

# Remaining P values
t("Page not found", "Paj pa jwenn", "Страница не найдена", "페이지를 찾을 수 없습니다", "Không tìm thấy trang", "Hindi nahanap ang page")
t("Profile", "Profil", "Профиль", "프로필", "Hồ sơ", "Profile")
t("Profit", "Pwofi", "Прибыль", "이익", "Lợi nhuận", "Kita")
t("Properties", "Pwopriyete", "Объекты недвижимости", "부동산", "Bất động sản", "Mga Property")

# Remaining R values
t("Refresh", "Rafrechi", "Обновить", "새로고침", "Làm mới", "I-refresh")
t("Reject", "Rejte", "Отклонить", "거부", "Từ chối", "Tanggihan")
t("Rejected", "Rejte", "Отклонён", "거부됨", "Đã từ chối", "Tinanggihan")
t("Remove", "Retire", "Удалить", "제거", "Xóa", "Alisin")
t("Reply", "Reponn", "Ответить", "답장", "Trả lời", "Sumagot")
t("Reset", "Reyinisyalize", "Сбросить", "초기화", "Đặt lại", "I-reset")

# Remaining S values
t("Saving...", "Ap anrejistre...", "Сохранение...", "저장 중...", "Đang lưu...", "Nagse-save...")
t("Search jobs...", "Chèche travay...", "Поиск заказов...", "작업 검색...", "Tìm kiếm công việc...", "Maghanap ng job...")
t("Select your preferred language. All pages will update immediately.", "Chwazi lang ou prefere. Tout paj ap mete ajou imedyatman.", "Выберите предпочтительный язык. Все страницы обновятся сразу.", "선호하는 언어를 선택하세요. 모든 페이지가 즉시 업데이트됩니다.", "Chọn ngôn ngữ ưa thích. Tất cả trang sẽ cập nhật ngay lập tức.", "Piliin ang gustong wika. Lahat ng page ay agad na mag-a-update.")
t("Sign out", "Dekonekte", "Выйти", "로그아웃", "Đăng xuất", "Mag-sign out")
t("Something went wrong", "Yon bagay mal pase", "Что-то пошло не так", "오류가 발생했습니다", "Đã xảy ra lỗi", "May nangyaring mali")
t("Something went wrong. Please try again.", "Yon bagay mal pase. Tanpri eseye ankò.", "Что-то пошло не так. Попробуйте ещё раз.", "오류가 발생했습니다. 다시 시도해 주세요.", "Đã xảy ra lỗi. Vui lòng thử lại.", "May nangyaring mali. Pakisubukan ulit.")
t("Subtotal", "Sou-total", "Промежуточный итог", "소계", "Tạm tính", "Subtotal")
t("Success", "Siksè", "Успешно", "성공", "Thành công", "Tagumpay")
t("Summary", "Rezime", "Сводка", "요약", "Tóm tắt", "Buod")

# Remaining T values
t("Tax", "Taks", "Налог", "세금", "Thuế", "Buwis")
t("Time", "Lè", "Время", "시간", "Thời gian", "Oras")
t("Today", "Jodi a", "Сегодня", "오늘", "Hôm nay", "Ngayon")
t("Tools", "Zouti", "Инструменты", "도구", "Công cụ", "Mga Tool")

# Remaining U values
t("Urgent", "Ijan", "Срочно", "긴급", "Khẩn cấp", "Apurahan")

# Remaining V values
t("Vendor", "Vandè", "Поставщик", "거래처", "Nhà cung cấp", "Vendor")
t("Verified", "Verifye", "Подтверждён", "확인됨", "Đã xác minh", "Na-verify")

# Remaining W values
t("Warning", "Avètisman", "Предупреждение", "경고", "Cảnh báo", "Babala")
t("Warranty", "Garanti", "Гарантия", "보증", "Bảo hành", "Warranty")
t("Welcome back", "Byenvini ankò", "С возвращением", "다시 오신 것을 환영합니다", "Chào mừng trở lại", "Maligayang pagbabalik")

# Remaining Y values
t("Yes", "Wi", "Да", "예", "Có", "Oo")

# Remaining lowercase
t("days", "jou", "дней", "일", "ngày", "araw")
t("for", "pou", "для", "에 대해", "cho", "para sa")
t("from", "de", "от", "에서", "từ", "mula sa")
t("items", "atik", "элементов", "개 항목", "mục", "mga item")
t("scheduled", "planifye", "запланировано", "예정됨", "đã lên lịch", "naka-schedule")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
