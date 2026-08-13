-- ============================================================================
-- SANTEX EXPRESS — Xavfsizlik sozlamalari (1-bosqich)
-- ============================================================================
-- Bu skriptni Supabase Dashboard -> SQL Editor -> "New query" ichiga
-- to'liq nusxalab, "Run" tugmasini bosing. Bir marta ishga tushirish yetarli.
--
-- Bu skript nima qiladi:
--   1. Har bir xodim uchun "profil" (ism + rol: admin/kassir) jadvalini yaratadi
--   2. Yangi xodim qo'shilganda profilni avtomatik ochadi
--   3. Asosiy ma'lumot jadvali (app_data) ni faqat tizimga kirgan (login qilgan)
--      xodimlar uchun ochiq qiladi — login qilmagan hech kim (hattoki
--      SUPABASE_KEY'ni bilsa ham) ma'lumotni o'qiy yoki o'zgartira olmaydi.
-- ============================================================================

-- 1) PROFILLAR JADVALI ---------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  role text not null default 'kassir' check (role in ('admin','kassir')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Har bir xodim FAQAT o'z profilini (ismi, roli) ko'ra oladi.
-- Boshqasining profilini o'zgartirish yoki o'zining rolini ko'tarish
-- imkoniyati client tomondan YO'Q — buni faqat siz shu SQL Editor orqali
-- qilasiz (pastdagi 3-bo'limga qarang).
drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

-- Yangi xodim Supabase Authentication'da yaratilganda profil qatori
-- avtomatik ochilishi uchun (standart rol: kassir):
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', new.email), 'kassir')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2) ASOSIY MA'LUMOT JADVALI (app_data) ----------------------------------
-- Ilova shu jadvalga butun do'kon ma'lumotini (mahsulot, sotuv, mijoz...)
-- saqlaydi. Hozirgacha bu jadval himoyalanmagan bo'lishi mumkin edi.
alter table public.app_data enable row level security;

drop policy if exists "app_data: authenticated read" on public.app_data;
create policy "app_data: authenticated read"
  on public.app_data for select
  to authenticated
  using (true);

drop policy if exists "app_data: authenticated insert" on public.app_data;
create policy "app_data: authenticated insert"
  on public.app_data for insert
  to authenticated
  with check (true);

drop policy if exists "app_data: authenticated update" on public.app_data;
create policy "app_data: authenticated update"
  on public.app_data for update
  to authenticated
  using (true)
  with check (true);

-- Diqqat: bu policy "tizimga kirgan HAR QANDAY xodim" (admin ham, kassir
-- ham) app_data'ni o'qiy/yoza oladi, deb belgilaydi — chunki hozirgi
-- arxitekturada butun do'kon ma'lumoti bitta qatorda saqlanadi va POS
-- savdo qilish uchun kassirga ham yozish huquqi kerak. Kassir narxni
-- o'zgartira olmasligi kabi nozikroq (rol darajasidagi) cheklovlar
-- ilovaning interfeys qatlamida (index.html, "admin-only" belgilar orqali)
-- amalga oshirilgan. To'liq server darajasidagi maydon-bo'yicha nazorat
-- uchun keyingi bosqichda jadvallarni alohida-alohida qilib bo'lish kerak
-- bo'ladi (products, orders, customers... har biri o'z RLS siyosati bilan).

-- 4) REALTIME (bir qurilmadagi o'zgarish boshqasida DARHOL ko'rinishi uchun) --
-- Bo'lmasa ham tizim ishlayveradi (fon rejimida 15 soniyada bir tekshiradi),
-- lekin bu bilan o'zgarish deyarli bir zumda (soniya ichida) ko'rinadi.
alter publication supabase_realtime add table public.app_data;

-- ============================================================================
-- 5) BIRINCHI ADMIN HISOBINI YARATISH
-- ============================================================================
-- a) Supabase Dashboard -> Authentication -> Users -> "Add user"
--    - Email: o'zingizning ish emailingiz
--    - Password: kuchli parol
--    - "Auto Confirm User" belgisini albatta bosing (aks holda email
--      tasdiqlashni kutadi va kira olmaysiz)
--
-- b) Shundan keyin pastdagi so'rovni, o'sha email manzilini yozib,
--    shu yerda (SQL Editor'da) ishga tushiring:

-- update public.profiles set role = 'admin', name = 'Administrator'
-- where id = (select id from auth.users where email = 'SIZNING_EMAILINGIZ');

-- Boshqa xodimlarni ham xuddi shunday (a) qadam bilan Dashboard orqali
-- qo'shasiz. Ular avtomatik "kassir" bo'lib ochiladi (yuqoridagi trigger
-- tufayli) — agar kimgadir admin huquqi kerak bo'lsa, xuddi shu (b) qadamni
-- o'sha xodim uchun ham takrorlang.
-- ============================================================================
