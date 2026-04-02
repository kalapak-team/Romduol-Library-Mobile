<h1 align="center">🌸 Romduol Library</h1>

<p align="center">
  <strong>Open-Access Khmer Digital Book Library</strong><br/>
  <em>Inspired by Cambodia's national flower — the Romduol (រំដួល)</em>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/></a>
  <a href="https://laravel.com"><img src="https://img.shields.io/badge/Laravel-11-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" alt="Laravel"/></a>
  <a href="https://www.postgresql.org"><img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/></a>
  <a href="https://redis.io"><img src="https://img.shields.io/badge/Redis-7-DC382D?style=for-the-badge&logo=redis&logoColor=white" alt="Redis"/></a>
  <a href="https://docs.docker.com/compose/"><img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/></a>
</p>

<p align="center">
  A full-stack digital library platform for discovering, reading, and sharing Khmer-language books.<br/>
  Built with <strong>Flutter</strong> on the frontend and <strong>Laravel</strong> on the backend, fully containerized with <strong>Docker</strong>.
</p>

---

## 📸 Screenshots

<p align="center">
  <strong>🔐 Authentication</strong><br/><br/>
  <img src="Demo/Romduol1.jpg" width="600" alt="Login and Register screens"/>
</p>

<p align="center">
  <strong>🏠 Home · 📚 Catalog · ⬆️ Upload</strong><br/><br/>
  <img src="Demo/Romduol2.jpg" width="700" alt="Home, Catalog, and Upload screens"/>
</p>

<p align="center">
  <strong>📖 Bookshelf · 📕 My Books · 👤 Profile</strong><br/><br/>
  <img src="Demo/Romduol3.jpg" width="700" alt="Bookshelf, My Books, and Profile screens"/>
</p>

---

## ✨ Features

#### 📱 Reader Experience

> Browse featured books & new arrivals · Search & filter by category · In-app PDF reader · Download books for offline reading · Rate & review books · Bookmark favorites · Follow other readers · Share books with friends

#### 🛡️ Admin Dashboard

> Approve / reject book submissions · Feature selected books on homepage · Manage users (ban / promote) · View platform statistics · Configure app settings

#### 🌐 Platform

> Bilingual UI — **English** & **ខ្មែរ (Khmer)** · Token-based auth (Laravel Sanctum) · Multi-step book upload wizard · User profiles with follower system · Responsive across mobile & web

#### 🏗️ Developer Experience

> Fully containerized (Docker Compose) · One-command backend setup · PostgreSQL + Redis stack · Adminer DB dashboard included · Seeded demo data for quick start

---

## 🏛️ Architecture

```
Romduol_Library/
│
├── frontend/                  # Flutter 3.22 — cross-platform client
│   ├── lib/
│   │   ├── core/              # Constants, themes, utilities
│   │   ├── data/              # Models, repositories, providers
│   │   └── presentation/      # Screens, widgets, state management
│   └── assets/                # Fonts, icons, images, translations
│
├── backend/                   # Laravel 11 — RESTful API
│   ├── app/
│   │   ├── Models/            # Eloquent models (Book, User, Category…)
│   │   ├── Http/              # Controllers, middleware, requests, resources
│   │   └── Services/          # BookService, FileUploadService
│   ├── database/              # Migrations & seeders
│   └── routes/api.php         # All API route definitions
│
└── infrastructure/            # Docker orchestration
    ├── docker-compose.yml
    └── docker/
        ├── nginx/             # Nginx web server config
        └── php/               # PHP-FPM Dockerfile & php.ini
```

---

## 🚀 Getting Started

### Prerequisites

| Tool                                                        | Version |
| :---------------------------------------------------------- | :------ |
| [Docker](https://www.docker.com/)                           | 20+     |
| [Docker Compose](https://docs.docker.com/compose/)          | 2.x     |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.22+   |

### 1️⃣ Clone the repository

```bash
git clone https://github.com/kalapak-team/Romduol-Library-Mobile.git
cd Romduol-Library-Mobile
```

### 2️⃣ Start the backend

```bash
cd infrastructure

# Copy environment file
cp ../backend/.env.example ../backend/.env        # macOS / Linux
copy ..\backend\.env.example ..\backend\.env       # Windows

# Spin up all services
docker compose up -d

# Install dependencies & bootstrap the app
docker compose exec app composer install
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate --seed
docker compose exec app php artisan storage:link
```

> ✅ API is now live at **`http://localhost:8000/api/v1`**

### 3️⃣ Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

| Platform            | Backend URL                    |
| :------------------ | :----------------------------- |
| Web / iOS / Desktop | `http://localhost:8000/api/v1` |
| Android Emulator    | `http://10.0.2.2:8000/api/v1`  |

> Base URL is configured in `frontend/lib/core/constants/api_endpoints.dart`

### 4️⃣ Access development tools

| Service          | URL                            |
| :--------------- | :----------------------------- |
| API              | `http://localhost:8000/api/v1` |
| Adminer (DB GUI) | `http://localhost:5051`        |

---

## 🔑 Default Credentials

| Role     | Email               | Password       |
| :------- | :------------------ | :------------- |
| 🔒 Admin | `admin@romduol.lib` | `Admin@1234`   |
| 👤 User  | `sokha@example.com` | `Password@123` |

> Created automatically by the database seeder.

---

## 📡 API Reference

> All endpoints are prefixed with **`/api/v1`**

<details>
<summary><strong>🔐 Authentication</strong></summary>
<br/>

| Method | Endpoint                | Auth | Description            |
| :----- | :---------------------- | :--: | :--------------------- |
| `POST` | `/auth/register`        |  —   | Create a new account   |
| `POST` | `/auth/login`           |  —   | Login → Bearer token   |
| `POST` | `/auth/forgot-password` |  —   | Request password reset |
| `POST` | `/auth/logout`          |  ✅  | Revoke current token   |
| `GET`  | `/auth/me`              |  ✅  | Get authenticated user |
| `POST` | `/auth/profile`         |  ✅  | Update profile         |
| `POST` | `/auth/change-password` |  ✅  | Change password        |

</details>

<details>
<summary><strong>📚 Books</strong></summary>
<br/>

| Method   | Endpoint               | Auth | Description            |
| :------- | :--------------------- | :--: | :--------------------- |
| `GET`    | `/books`               |  —   | Paginated book catalog |
| `GET`    | `/books/featured`      |  —   | Featured books         |
| `GET`    | `/books/new-arrivals`  |  —   | New arrivals           |
| `GET`    | `/books/search`        |  —   | Search books           |
| `GET`    | `/books/{id}`          |  —   | Book detail            |
| `GET`    | `/books/{id}/read`     |  —   | Read book (PDF)        |
| `GET`    | `/books/{id}/reviews`  |  —   | Book reviews           |
| `POST`   | `/books`               |  ✅  | Upload a new book      |
| `PATCH`  | `/books/{id}`          |  ✅  | Update book            |
| `DELETE` | `/books/{id}`          |  ✅  | Delete book            |
| `GET`    | `/books/{id}/download` |  ✅  | Download PDF           |
| `POST`   | `/books/{id}/favorite` |  ✅  | Toggle favorite        |
| `POST`   | `/books/{id}/reviews`  |  ✅  | Post a review          |

</details>

<details>
<summary><strong>👥 User & Social</strong></summary>
<br/>

| Method | Endpoint                      | Auth | Description       |
| :----- | :---------------------------- | :--: | :---------------- |
| `GET`  | `/me/books`                   |  ✅  | My uploaded books |
| `GET`  | `/me/favorites`               |  ✅  | My favorites      |
| `GET`  | `/me/reviews`                 |  ✅  | My reviews        |
| `GET`  | `/me/following`               |  ✅  | Users I follow    |
| `POST` | `/users/{id}/follow`          |  ✅  | Toggle follow     |
| `GET`  | `/users/{username}`           |  —   | Public profile    |
| `GET`  | `/users/{username}/followers` |  —   | User followers    |
| `GET`  | `/users/{username}/following` |  —   | User following    |

</details>

<details>
<summary><strong>⚙️ Admin (requires admin role)</strong></summary>
<br/>

| Method | Endpoint                    | Description              |
| :----- | :-------------------------- | :----------------------- |
| `GET`  | `/admin/dashboard`          | Platform statistics      |
| `GET`  | `/admin/books`              | Pending book submissions |
| `GET`  | `/admin/users`              | All users                |
| `GET`  | `/admin/settings`           | App settings             |
| `POST` | `/admin/books/{id}/approve` | Approve a book           |
| `POST` | `/admin/books/{id}/reject`  | Reject a book            |
| `POST` | `/admin/books/{id}/feature` | Feature a book           |
| `POST` | `/admin/users/{id}/ban`     | Ban a user               |
| `POST` | `/admin/users/{id}/unban`   | Unban a user             |
| `POST` | `/admin/users/{id}/promote` | Promote to admin         |

</details>

---

## 🛠️ Tech Stack

| Layer                | Technology                                      |
| :------------------- | :---------------------------------------------- |
| **Frontend**         | Flutter 3.22 · Riverpod 2 · GoRouter 14 · Dio 5 |
| **Backend**          | Laravel 11 · Sanctum · Eloquent ORM             |
| **Database**         | PostgreSQL 16                                   |
| **Cache**            | Redis 7                                         |
| **Storage**          | Local disk (dev) / AWS S3 (prod)                |
| **Containerization** | Docker · Docker Compose                         |
| **Web Server**       | Nginx                                           |
| **Localization**     | English · Khmer (easy_localization)             |

<details>
<summary><strong>📦 Frontend Packages</strong></summary>
<br/>

| Category         | Packages                                                          |
| :--------------- | :---------------------------------------------------------------- |
| State Management | `flutter_riverpod` · `riverpod_annotation`                        |
| Navigation       | `go_router`                                                       |
| Networking       | `dio` · `pretty_dio_logger` · `connectivity_plus`                 |
| Storage          | `flutter_secure_storage` · `shared_preferences` · `hive_flutter`  |
| PDF              | `syncfusion_flutter_pdfviewer` · `flutter_pdfview`                |
| UI               | `cached_network_image` · `shimmer` · `lottie` · `carousel_slider` |
| Files            | `file_picker` · `image_picker` · `open_filex` · `share_plus`      |

</details>

---

## 🗄️ Database Schema

```
┌──────────┐         ┌───────────┐         ┌──────────┐
│  users   │───1:N───│   books   │───N:M───│   tags   │
└──────────┘         └───────────┘         └──────────┘
                       │       │
                      1:N     1:N
                       │       │
                ┌──────┘       └──────┐
                ▼                     ▼
           ┌─────────┐         ┌───────────┐
           │ reviews │         │ downloads │
           └─────────┘         └───────────┘

  ┌────────────┐
  │ categories │── self-referencing (parent ↔ children)
  └────────────┘

  ┌──────────┐
  │ settings │── app-wide key/value config
  └──────────┘
```

---

## 📂 Docker Services

| Service     | Image         | Port   | Purpose                    |
| :---------- | :------------ | :----- | :------------------------- |
| **app**     | PHP 8.2 FPM   | —      | Laravel API runtime        |
| **nginx**   | Nginx         | `8000` | Web server / reverse proxy |
| **db**      | PostgreSQL 16 | `5433` | Primary database           |
| **redis**   | Redis 7       | `6379` | Cache & sessions           |
| **adminer** | Adminer       | `5051` | Database management UI     |

---

## 📁 Frontend Screens

| Screen            | Description                                |
| :---------------- | :----------------------------------------- |
| **Onboarding**    | Welcome / splash screen                    |
| **Auth**          | Login & registration                       |
| **Home**          | Featured books, new arrivals, carousel     |
| **Catalog**       | Browse all books with search & filters     |
| **Book Detail**   | Cover, description, reviews, download      |
| **Reader**        | In-app PDF viewer                          |
| **Upload**        | Multi-step book upload wizard              |
| **Bookshelf**     | Favorites & uploaded books                 |
| **Profile**       | User info, followers, uploaded books       |
| **Search**        | Full-text book search                      |
| **Notifications** | Activity feed                              |
| **Admin**         | Dashboard, approval queue, user management |

---

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch — `git checkout -b feature/amazing-feature`
3. **Commit** your changes — `git commit -m "Add amazing feature"`
4. **Push** to the branch — `git push origin feature/amazing-feature`
5. **Open** a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Made with ❤️ in Cambodia 🇰🇭</strong><br/>
  <em>Romduol (រំដួល) — Cambodia's national flower, symbolizing knowledge that blossoms for everyone.</em>
</p>
