# 🤖 AuraAI — Multi-Model AI Chat SaaS Platform

A production-ready Flutter + Firebase AI chat application with multi-model support (Claude, GPT-4, Gemini), image generation, document analysis, subscription system, and admin panel.

---

## ✨ Features

### Core Chat
- **Multi-Model Chat** — Switch between Claude 3.5 Sonnet, GPT-4o, and Gemini Pro
- **Markdown Rendering** — AI responses render with full markdown support
- **Conversation History** — All chats persisted in Firestore with search
- **Chat Folders** — Organize conversations into folders
- **Pinned Conversations** — Pin important chats to top
- **Share Conversations** — Generate shareable links

### AI Capabilities
- **Image Generation** — DALL-E 3 integration for AI art
- **Image Analysis** — Upload images for AI description/analysis
- **Document Upload** — PDF/TXT upload with AI summarization
- **Voice Input** — Speech-to-text (placeholder, integrate speech_to_text)

### Subscription System
- **Free Plan** — 10 messages/day
- **Pro Monthly** — $9.99/mo, unlimited everything
- **Pro Annual** — $79.99/yr, save 33%
- Daily message counter with auto-reset
- In-app purchase ready (integrate in_app_purchase)

### User Experience
- **Dark/Light Theme** — Toggle with persistence
- **Prompt Templates Library** — 10 pre-built templates across 7 categories
- **Onboarding Tutorial** — 4-screen animated onboarding
- **Daily AI Tips** — Rotating tips on home screen

### Admin Panel
- **Dashboard** — User stats, conversation counts, model usage analytics
- **User Management** — Upgrade/downgrade plans, reset usage, make admin
- **Subscription Analytics** — Revenue estimation, conversion rates
- **Content Management** — Seed templates, send push notifications, add templates, cleanup old data

---

## 📁 Project Structure

```
aura_ai/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── theme/
│   │   └── app_theme.dart                 # Dark/Light themes, colors, gradients
│   ├── models/
│   │   └── models.dart                    # All data models (User, Conversation, Message, etc.)
│   ├── services/
│   │   ├── auth_service.dart              # Firebase Auth + user management
│   │   ├── ai_service.dart                # Multi-model AI API service
│   │   ├── chat_service.dart              # Firestore chat/folder/template operations
│   │   └── theme_provider.dart            # Theme state management
│   └── screens/
│       ├── splash/splash_screen.dart       # Animated splash
│       ├── onboarding/onboarding_screen.dart # 4-page tutorial
│       ├── auth/
│       │   ├── login_screen.dart           # Email login + forgot password
│       │   └── signup_screen.dart          # Account creation
│       ├── home/
│       │   ├── main_shell.dart             # Bottom nav shell
│       │   └── home_screen.dart            # Dashboard with quick actions
│       ├── chat/
│       │   ├── chat_screen.dart            # Full chat with model switcher
│       │   └── chat_list_screen.dart       # Conversation history + folders
│       ├── prompt_templates/
│       │   └── templates_screen.dart       # Prompt template library
│       ├── settings/
│       │   └── settings_screen.dart        # Settings + profile
│       ├── subscription/
│       │   └── subscription_screen.dart    # Pricing plans
│       └── admin/
│           └── admin_dashboard.dart        # Full admin panel
├── firestore.rules                         # Firestore security rules
├── firestore.indexes.json                  # Composite indexes
└── pubspec.yaml                            # Dependencies
```

---

## 🚀 Setup Instructions

### 1. Create Firebase Project
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Create Firebase project at https://console.firebase.google.com
# Enable: Authentication (Email/Password), Cloud Firestore, Storage
```

### 2. Configure Firebase
```bash
flutterfire configure --project=your-project-id
```

### 3. Add API Keys
Edit `lib/services/ai_service.dart` and replace:
```dart
static const String _claudeApiKey = 'YOUR_CLAUDE_API_KEY';    // https://console.anthropic.com
static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY';    // https://platform.openai.com
static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';    // https://aistudio.google.com
```

> ⚠️ **IMPORTANT**: For production, move API keys to Firebase Remote Config or a backend proxy.
> Never ship API keys in the app binary.

### 4. Set Admin Emails
Edit `lib/services/auth_service.dart`:
```dart
static const List<String> adminEmails = [
  'your-email@example.com',
];
```

### 5. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### 6. Run the App
```bash
flutter pub get
flutter run
```

### 7. Seed Data (First Launch)
- Login with an admin email
- Go to Settings → Admin Dashboard → Content tab
- Tap "Seed Prompt Templates" to populate the template library

---

## 🎨 Design System

### Colors
| Name | Hex | Usage |
|------|-----|-------|
| Primary | `#6C63FF` | Buttons, accents, gradients |
| Secondary | `#00D4FF` | Cyan neon highlights |
| Accent | `#FF6B9D` | Pink accent, image gen |
| Claude | `#D97757` | Claude model indicator |
| GPT | `#10A37F` | GPT model indicator |
| Gemini | `#4285F4` | Gemini model indicator |
| Dark BG | `#0A0E1A` | Primary background |
| Dark Card | `#1A2236` | Card backgrounds |

### Typography
- **Headlines**: Space Mono (bold)
- **Body**: Inter (regular/medium/bold)

---

## 🔥 Firestore Collections

```
users/
  {uid}/
    email, displayName, plan, dailyMessagesUsed, lastMessageDate,
    createdAt, isAdmin, fcmToken, preferences

conversations/
  {convId}/
    userId, title, model, createdAt, updatedAt, folderId,
    isPinned, lastMessage, messageCount, isShared, shareId

messages/
  {msgId}/
    conversationId, content, isUser, type, createdAt,
    imageUrl, documentUrl, documentName, model

folders/
  {folderId}/
    userId, name, icon, chatCount, createdAt

promptTemplates/
  {templateId}/
    title, description, prompt, category, icon, isPremium

sharedConversations/
  {shareId}/
    (copy of conversation + messages)
```

---

## 📋 TODO / Future Enhancements

- [ ] Google Sign-In integration
- [ ] In-app purchase (StoreKit / Google Play Billing)
- [ ] Speech-to-text voice input
- [ ] Push notifications via Firebase Cloud Messaging
- [ ] Streaming AI responses (SSE)
- [ ] Backend proxy for API keys (Cloud Functions)
- [ ] Export conversation as PDF/Image
- [ ] Custom prompt template creation for users
- [ ] Multi-language support
- [ ] Rate limiting on backend

---

## 📱 Screenshots

_App screenshots will go here after building_

---

## 📄 License

MIT License — Built with ❤️ using Flutter + Firebase
