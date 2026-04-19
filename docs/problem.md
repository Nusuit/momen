# Problem Tracking - Camera, Navigation, Data Sync

## 1) Da hoan thanh

### UI/UX
- Camera post-capture flow da co preview sau khi chup.
- Caption da duoc dua len tren anh (overlay) thay vi panel rieng ben duoi.
- Khung preview/chup duoc bo goc va them border/shadow de dep hon.
- Co button chup lai va dang bai trong state sau khi chup.
- Co toggle trong Settings de an/hien o nhap so tien:
  - ON: hien o so tien.
  - OFF: an o so tien, giu anh gan full man hinh.

### Navigation
- Mac dinh vao app se vao tab Camera.
- Da bo header o cac page chinh (Feed/Memories/Dashboard/Profile).
- Da sap xep lai tab:
  - Memories
  - Social (gop Feed + Money/Dashboard trong 1 man)
  - Profile
- Camera giu vai tro tao post nhanh tu FAB.

### Data hardcode
- Da bo hardcode data lon o:
  - Feed page
  - Memories page
  - Dashboard page
- Cac page nay hien tai chuyen sang empty state huong DB-first.

### Profile
- Da them section Friends trong Profile voi o tim kiem friend.
- Da them them options trong Settings (notification/privacy placeholder).

### Test
- Da cap nhat test theo navigator/UI moi.
- Trang thai hien tai: tat ca test pass.

## 2) Dang lam tiep (can tiep tuc)

### Business flow backend
- Dang bai tu Camera hien tai moi la luong UI.
- Chua save post that su xuong Supabase.
- Chua co truy van de Memories va Dashboard doc data tu DB.

### Friend search
- UI friend search da co, nhung chua noi backend query.

## 3) Chua hoan thanh

### Dong bo so tien vao Memories + Dashboard (E2E)
Can them data pipeline day du:
1. Camera submit -> insert post vao DB (caption, amount, image_url, created_at, owner_id).
2. Memories -> query danh sach post theo user/thang.
3. Dashboard -> query tong chi tieu theo ngay/tuan/thang va category.
4. Realtime update (optional) de dashboard/memories cap nhat nhanh.

## 4) Nen setup gi voi Supabase truoc (uu tien cao)

### 4.1 Auth
- Bat Supabase Auth (email/password hoac OTP).
- Bat Row Level Security (RLS) cho tat ca bang user data.

### 4.2 Storage
- Tao bucket: post_images
- Policy:
  - User dang nhap duoc upload vao folder cua chinh ho.
  - Public read neu feed la public, hoac signed URL neu private.

### 4.3 Database schema de chay duoc flow hien tai

Bang: profiles
- id uuid pk references auth.users(id)
- username text unique
- display_name text
- avatar_url text
- created_at timestamptz default now()

Bang: posts
- id uuid pk default gen_random_uuid()
- user_id uuid references profiles(id)
- image_path text not null
- caption text
- amount_vnd bigint null
- category text null
- visibility text default 'friends'
- created_at timestamptz default now()

Bang: friendships
- id uuid pk default gen_random_uuid()
- requester_id uuid references profiles(id)
- addressee_id uuid references profiles(id)
- status text check (status in ('pending','accepted','blocked'))
- created_at timestamptz default now()
- unique(requester_id, addressee_id)

Bang: app_settings (tuong lai, neu muon sync setting qua cloud)
- user_id uuid pk references profiles(id)
- show_amount_input boolean default true
- updated_at timestamptz default now()

### 4.4 SQL view cho Dashboard
View: v_user_spending_daily
- user_id
- date(created_at) as day
- sum(amount_vnd) as total_vnd

View: v_user_spending_monthly
- user_id
- date_trunc('month', created_at)
- sum(amount_vnd)

### 4.5 RPC/Query cho Memories
- Query posts theo user + month range + order by created_at desc.
- Co pagination (limit/offset hoac keyset theo created_at).

## 5) Nen setup gi voi Firebase truoc

### Bat buoc truoc
- Tao Firebase project.
- Add Android app + iOS app.
- Add file config vao project:
  - android/app/google-services.json
  - ios/Runner/GoogleService-Info.plist

### Dung Firebase cho gi
- Crashlytics: theo doi crash camera, upload, parser.
- Analytics (optional): theo doi conversion flow chup -> dang bai.

### Goi y event nen track
- camera_opened
- camera_captured
- post_submitted
- amount_input_enabled_toggle
- friend_search_used

## 6) Kien truc dong bo amount vao Memories va Dashboard

1. UI layer (Camera)
- User chup anh, nhap caption.
- Neu showAmountInput = true thi cho nhap amount.
- Neu amount rong, parser tu caption co the suggest amount.

2. Domain layer
- UseCase: CreatePostUseCase
  - Input: image file, caption, amount_vnd?
  - Validate amount_vnd >= 0

3. Data layer
- Upload image len Supabase Storage -> lay image_path/public_url.
- Insert record vao posts.

4. Read layer
- Memories page doc posts theo thang.
- Dashboard page doc aggregation views.

5. Cache/local fallback (optional)
- Isar luu cache recent posts de offline read.

## 7) Ke hoach implementation tiep theo

### Phase 1: Supabase core (nen lam ngay)
- Tao profiles, posts, friendships + RLS.
- Tao bucket post_images + policy upload/read.
- Tao views spending daily/monthly.

### Phase 2: Flutter data integration
- Tao feature post data source/repository/usecase.
- Camera submit goi usecase that su.
- Memories va Dashboard query DB that su.

### Phase 3: Friend search
- Profile search query profiles by username/display_name.
- Add friend request flow + accepted list.

### Phase 4: Analytics/Crash
- Bat Firebase Crashlytics va event analytics.

## 8) Rui ro ky thuat can theo doi
- Upload image fail tren mang yeu.
- amount parser nham don vi (k/m/tr).
- RLS policy sai gay khong doc duoc data.
- Denormalization dashboard neu data lon can index ky.

## 9) Dinh nghia Done cho request nay
- Camera UX theo mockup da dat.
- Co toggle amount input trong settings.
- App vao camera mac dinh.
- Header da bo o cac page chinh.
- Feed + Money gop chung UI.
- Hardcode data lon da bo.
- Co file tracking van de va roadmap tiep theo (file nay).
