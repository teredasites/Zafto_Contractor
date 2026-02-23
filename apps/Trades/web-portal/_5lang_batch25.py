#!/usr/bin/env python3
"""5-language batch 25: X-Y-Z values + template strings + lowercase"""
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

# X values
t("Xact Price", "Pri Xact", "Цена Xact", "Xact 가격", "Giá Xact", "Xact Price")
t("Xactimate", "Xactimate", "Xactimate", "Xactimate", "Xactimate", "Xactimate")
t("Xactimate Total", "Total Xactimate", "Итого Xactimate", "Xactimate 합계", "Tổng Xactimate", "Kabuuang Xactimate")

# Y values
t("YTD", "YTD", "С начала года", "연초 대비", "Từ đầu năm", "YTD")
t("YTD Payments", "Peman YTD", "Платежи с начала года", "연초 대비 결제", "Thanh toán từ đầu năm", "Mga YTD Payment")
t("Yard Sign", "Pankat Lakou", "Дворовая вывеска", "야드 사인", "Biển sân vườn", "Yard Sign")
t("Year Built", "Ane Konstriksyon", "Год постройки", "건축 연도", "Năm xây dựng", "Taon ng Pagtatayo")
t("Year-End Ready", "Prè pou Fen Ane", "Готово к закрытию года", "연말 정산 준비 완료", "Sẵn sàng cuối năm", "Handa na sa Year-End")
t("Year-end close completed successfully.", "Fèmti fen ane konplete avèk siksè.", "Закрытие года выполнено успешно.", "연말 마감이 성공적으로 완료되었습니다.", "Đóng sổ cuối năm hoàn thành thành công.", "Matagumpay na nakumpleto ang year-end close.")
t("Years Experience", "Ane Eksperyans", "Лет опыта", "경력 연수", "Năm kinh nghiệm", "Taon ng Karanasan")
t("Years in Business", "Ane Nan Biznis", "Лет в бизнесе", "사업 연수", "Năm hoạt động", "Taon sa Negosyo")
t("Yelp", "Yelp", "Yelp", "Yelp", "Yelp", "Yelp")
t("You don't have permission to view this.", "Ou pa gen pèmisyon pou wè sa.", "У вас нет прав для просмотра.", "이 항목을 볼 권한이 없습니다.", "Bạn không có quyền xem mục này.", "Wala kang pahintulot na tingnan ito.")
t("Your Carrier", "Transpòtè Ou", "Ваш перевозчик", "귀하의 통신사", "Nhà mạng của bạn", "Iyong Carrier")
t("Your Numbers", "Nimewo Ou", "Ваши номера", "내 번호", "Số của bạn", "Mga Numero Mo")
t("Your active session information", "Enfòmasyon sesyon aktif ou", "Информация об активных сеансах", "활성 세션 정보", "Thông tin phiên hoạt động", "Impormasyon ng active session mo")
t("Your session has expired. Please sign in again.", "Sesyon ou ekspire. Tanpri konekte ankò.", "Ваш сеанс истёк. Войдите снова.", "세션이 만료되었습니다. 다시 로그인해 주세요.", "Phiên của bạn đã hết hạn. Vui lòng đăng nhập lại.", "Nag-expire na ang session mo. Pakimaag muli.")

# Z values
t("ZAFTO Code Database", "Baz Done Kòd ZAFTO", "База кодов ZAFTO", "ZAFTO 코드 데이터베이스", "Cơ sở dữ liệu mã ZAFTO", "ZAFTO Code Database")
t("ZAFTO Price", "Pri ZAFTO", "Цена ZAFTO", "ZAFTO 가격", "Giá ZAFTO", "ZAFTO Price")
t("ZForge", "ZForge", "ZForge", "ZForge", "ZForge", "ZForge")
t("ZIP", "ZIP", "Индекс", "우편번호", "Mã bưu chính", "ZIP")
t("ZIP Code", "Kòd Postal", "Почтовый индекс", "우편번호", "Mã bưu chính", "ZIP Code")
t("Zoning Approval", "Apwobasyon Zonaj", "Разрешение зонирования", "용도 지역 승인", "Phê duyệt quy hoạch", "Zoning Approval")

# lowercase
t("years", "ane", "лет", "년", "năm", "taon")

# Template strings with {count} / {hours}
t("{count} Overdue Invoice", "{count} Fakti Anreta", "{count} просроченный счёт", "{count}건 연체 청구서", "{count} hóa đơn quá hạn", "{count} Overdue na Invoice")
t("{count} Overdue Invoices", "{count} Fakti Anreta", "{count} просроченных счетов", "{count}건 연체 청구서", "{count} hóa đơn quá hạn", "{count} Mga Overdue na Invoice")
t("{hours} hrs remaining", "{hours} èdtan rete", "{hours} ч. осталось", "{hours}시간 남음", "Còn {hours} giờ", "{hours} oras na natitira")

# Save and apply
for loc in LOCALES:
    f = f"_{loc}_dict.json"
    with open(f, "w", encoding="utf-8") as fh:
        json.dump(dicts[loc], fh, ensure_ascii=False, indent=2)
    print(f"{loc} dict: {len(dicts[loc])} entries")
    subprocess.run(["python", "_all_langs_apply.py", loc, f])
