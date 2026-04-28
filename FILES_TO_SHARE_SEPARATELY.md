# 📦 ملفات ترسلينها لزميلاتك منفصل (ما ترفع على GitHub)

## ⚠️ هذي الملفات **كبيرة جداً** للـ GitHub - لازم ترسلينها عبر Google Drive أو OneDrive

---

## 1️⃣ CSRNet Model File (الأهم!)

### الملف:
```
csrnet_epoch_81.pth
```

### المكان الحالي:
```
C:\Users\Hayaa\Downloads\crowd-count-main - Copy1 - finalInProject - Copy\saved_models\csrnet_epoch_81.pth
```

### الحجم:
حوالي **50-100 MB**

### وين يحطونه:
```
csrnet_server/saved_models/csrnet_epoch_81.pth
```

### طريقة المشاركة:
1. **Google Drive:**
   - ارفع الملف على Google Drive
   - Share → Get link → Anyone with the link can view
   - أرسل الرابط للفريق

2. **OneDrive:**
   - ارفع الملف على OneDrive
   - Share → Anyone with the link
   - أرسل الرابط

3. **WeTransfer:**
   - روح https://wetransfer.com
   - ارفع الملف
   - أدخل email زميلاتك
   - Send

---

## 2️⃣ Unity Library (اختياري - بس إذا يبون AR)

### المجلد:
```
android/unityLibrary/
```

### المكان الحالي:
```
C:\Users\Hayaa\OneDrive\Desktop\sahalat_v3\sahalat31-main\sahalat\android\unityLibrary\
```

### الحجم:
حوالي **200-500 MB** 😱 (كبير جداً!)

### البديل الأفضل:
**ما تحتاج ترسله!** بدل كذا:

#### خيار 1: يعيدون generate من Unity
- عندهم Unity project
- يسوون Export للـ Android Library
- يحطونه في `android/unityLibrary`

#### خيار 2: ترسل Unity Project نفسه
- ارفع Unity project على GitHub repo منفصل
- أو شارك المجلد عبر OneDrive/Google Drive
- هم يفتحونه في Unity ويسوون export

---

## 3️⃣ APK Files (للتجربة السريعة)

### الملف:
```
app-debug.apk
```

### المكان:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### الحجم:
حوالي **50-100 MB**

### الفائدة:
- يقدرون يجربون التطبيق مباشرة
- بدون ما يبنون المشروع
- مفيد للديمو السريع

### طريقة المشاركة:
نفس طريقة الموديل - Google Drive/OneDrive/WeTransfer

---

## 📋 Checklist - تأكد من مشاركة هذي:

### ✅ الملفات الضرورية:
- [ ] **csrnet_epoch_81.pth** - الموديل (ضروري للـ AI)
- [ ] **Link للـ GitHub repo** - الكود

### ✅ اختياري (حسب الحاجة):
- [ ] **app-debug.apk** - للتجربة السريعة
- [ ] **Unity project** - إذا يبون يعدلون AR
- [ ] **android/unityLibrary** - بديل للـ Unity project

### ✅ معلومات إضافية:
- [ ] **IP Address للـ AI Server** - وين السيرفر شغال
- [ ] **Network credentials** - إذا في WiFi خاص
- [ ] **Test accounts** - إذا في login في التطبيق

---

## 📧 رسالة جاهزة ترسلينها:

```
Subject: Sahalat Project Files 📦

Hi Team! 👋

I've uploaded the code to GitHub, but some files are too large to push.
Please download them separately:

🔗 GitHub Repo: https://github.com/YOUR_USERNAME/sahalat

📥 Large Files (Google Drive):
1. CSRNet Model: [LINK_HERE] (csrnet_epoch_81.pth)
   - Place in: csrnet_server/saved_models/

2. Debug APK (optional): [LINK_HERE]
   - For quick testing without building

3. Unity Library (if needed): [LINK_HERE]
   - Place in: android/unityLibrary/

📚 Read First:
- README.md - Project overview
- SETUP_GUIDE.md - Complete setup (Arabic)
- GITHUB_CHECKLIST.md - GitHub best practices

⚙️ Setup Steps:
1. Clone the repo: git clone [REPO_URL]
2. Download the model file from Drive link above
3. Follow SETUP_GUIDE.md step by step
4. Update IP in lib/core/crowd_detection_service.dart

🌐 AI Server Info:
- Current IP: 172.20.17.229:5000
- Update this in crowd_detection_service.dart to your IP

Let me know if you need help! 🚀

Best,
[Your Name]
```

---

## 🎯 ملخص سريع:

| الملف | الحجم | ضروري؟ | طريقة المشاركة |
|------|-------|--------|----------------|
| **csrnet_epoch_81.pth** | ~100MB | ✅ نعم | Google Drive |
| **android/unityLibrary** | ~300MB | ❌ لا (يقدرون يولدونه) | OneDrive أو repo منفصل |
| **app-debug.apk** | ~70MB | 🤔 اختياري | Google Drive |
| **Unity Project** | ~1-2GB | 🤔 إذا يبون AR | Google Drive/OneDrive |

---

## 💡 نصيحة:

بدل ما ترسلين `unityLibrary` الكاملة، أفضل:
1. وثقي خطوات الـ Unity export في `SETUP_GUIDE.md` ✅ (موجود)
2. شارك Unity project نفسه (أخف من unityLibrary)
3. خليهم يسوون export بأنفسهم

هذا أفضل عشان:
- ✅ أخف في الحجم
- ✅ يتعلمون الـ workflow
- ✅ يقدرون يعدلون Unity scene إذا احتاجوا

---

**ملاحظة مهمة:**
لا تنسين تغيرين الـ IP address في الكود قبل ما يشتغلون عندهم!
```
lib/core/crowd_detection_service.dart
Line 87: static String _apiBaseUrl = 'http://172.20.17.229:5000';
```

كل واحدة تحط IP الكمبيوتر حقها 🖥️
