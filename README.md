# Santex-Express

Santex Express uchun POS, omborxona, CRM va xodimlar boshqaruv tizimi (ERP). Bitta `index.html` fayl ko'rinishidagi PWA, ma'lumotlar Supabase bulutida saqlanadi.

## Xavfsizlik: ishga tushirishdan oldin (MUHIM)

Ushbu branch login tizimini haqiqiy autentifikatsiyaga (Supabase Auth, email+parol, admin/kassir rollari) o'tkazdi. Productionga (main branch) merge qilishdan **oldin** quyidagi qadamlarni bajarishingiz shart, aks holda hech kim tizimga kira olmaydi:

1. **`supabase-security-setup.sql` faylini** Supabase Dashboard → SQL Editor'da to'liq ishga tushiring (1 marta, jadval va RLS siyosatlarini o'rnatadi).
2. Supabase Dashboard → Authentication → Users → **Add user** orqali o'zingiz uchun (va har bir xodim uchun) email+parol bilan hisob yarating. **"Auto Confirm User"**ni belgilang.
3. SQL Editor'da o'zingizning hisobingizni **admin** qilib belgilang (fayl ichidagi 3-bo'limga qarang). Boshqa xodimlar avtomatik ravishda **kassir** bo'lib ochiladi.
4. Shundan keyin tizimga email+parol bilan kirish mumkin bo'ladi.

Rollar: **Admin** — hammasi (narx, mahsulot, xodimlar, marketing, hisobotlar, zaxira). **Kassir** — faqat Boshqaruv paneli (ko'rish), Sotish (POS), Omborxona (ko'rish), Mijozlar (qo'shish + to'lov qabul qilish).

Diqqat: bu — interfeys darajasidagi (client-side) rol nazorati + Supabase RLS orqali "faqat login qilganlar kira oladi" darajasidagi himoya. To'liq maydon-bo'yicha (masalan, kassir hech qachon narxni o'zgartira olmasligini serverda ham majburlash) himoya keyingi bosqichda (ma'lumotlar bazasini alohida jadvallarga bo'lish) qo'shiladi.
