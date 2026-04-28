# 🚀 دليل التثبيت الكامل - Sahalat Project

## 📋 المتطلبات الأساسية

### 1. تثبيت Flutter
```bash
# تأكد من تثبيت Flutter
flutter doctor

# إذا لم يكن مثبت، حمله من:
# https://docs.flutter.dev/get-started/install
```

### 2. تثبيت Python 3.8+
```bash
python --version
# يجب أن يكون 3.8 أو أحدث
```

### 3. تثبيت Android Studio
- حمل من: https://developer.android.com/studio
- ثبت Android SDK
- أنشئ Android Emulator أو وصل جهاز حقيقي

---

## 📥 تحميل المشروع

### الخطوة 1: Clone المشروع
```bash
git clone https://github.com/YOUR_USERNAME/sahalat.git
cd sahalat
```

### الخطوة 2: تثبيت dependencies للـ Flutter
```bash
flutter pub get
```

---

## 🤖 إعداد AI Server (CSRNet)

### الخطوة 1: إنشاء Virtual Environment
```bash
cd csrnet_server
python -m venv venv
```

### الخطوة 2: تفعيل Virtual Environment

**Windows:**
```bash
venv\Scripts\activate
```

**macOS/Linux:**
```bash
source venv/bin/activate
```

### الخطوة 3: تثبيت المكتبات
```bash
pip install -r requirements.txt
```

### الخطوة 4: تحميل Model Weights
- حمل ملف `csrnet_epoch_81.pth`
- ضعه في `csrnet_server/saved_models/`

**رابط التحميل:** [أضف الرابط هنا]

### الخطوة 5: اختبار السيرفر
```bash
python api_server.py
```

يجب أن ترى:
```
==================================================
CSRNet Crowd Detection API Server
==================================================
Model loaded on cpu
* Running on http://0.0.0.0:5000
```

---

## 📱 تحديث IP Address في التطبيق

### الخطوة 1: معرفة IP الخاص بك

**Windows:**
```bash
ipconfig
```
ابحث عن: `IPv4 Address`

**macOS/Linux:**
```bash
ifconfig | grep "inet "
```

### الخطوة 2: تحديث الكود

افتح الملف:
```
lib/core/crowd_detection_service.dart
```

غير السطر:
```dart
static String _apiBaseUrl = 'http://192.168.100.7:5000';
```

إلى:
```dart
static String _apiBaseUrl = 'http://YOUR_IP_HERE:5000';
```

---

## 🥽 Unity AR Setup (اختياري)

### متطلبات Unity
- Unity 2021.3 أو أحدث
- AR Foundation package
- ARCore XR Plugin

### خطوات التصدير من Unity

#### 1. في Unity Editor
- افتح: **Edit → Project Settings → Player**
- اختر **Android** tab
- في **Other Settings**:
  - **Application Entry Point** → اختر **Activity** (ليس GameActivity)

#### 2. Export للـ Android
- **File → Build Settings**
- اختر **Android**
- ✅ فعل **Export Project**
- اختر المسار: `Builds/AndroidFlutterExport`
- اضغط **Export**

#### 3. نقل unityLibrary
```bash
# من مجلد Unity Project
cp -r Builds/AndroidFlutterExport/unityLibrary ../sahalat/android/

# أو في Windows
xcopy /E /I "Builds\AndroidFlutterExport\unityLibrary" "..\sahalat\android\unityLibrary"
```

#### 4. Clean & Build
```bash
cd sahalat
flutter clean
flutter build apk --debug
```
⏱️ البيلد الأول يأخذ 5-10 دقائق

---

## 🏃 تشغيل المشروع

### Terminal 1: Start AI Server
```bash
cd csrnet_server
venv\Scripts\activate  # Windows
python run_server_forever.py
```

### Terminal 2: Run Flutter App
```bash
cd sahalat
flutter run
```

أو لجهاز معين:
```bash
flutter devices
flutter run -d DEVICE_ID
```

---

## 🔧 حل المشاكل الشائعة

### مشكلة 1: libgame.so not found
**الحل:**
- تأكد أن Unity **Application Entry Point** = **Activity**
- احذف `android/unityLibrary`
- أعد export من Unity
- أعد نقل unityLibrary
- `flutter clean && flutter build apk`

### مشكلة 2: AI Server لا يستجيب
**الحل:**
- تأكد أن السيرفر شغال (تحقق من Terminal)
- تأكد من IP الصحيح في `crowd_detection_service.dart`
- تأكد أن الجهاز والكمبيوتر على نفس الشبكة
- جرب: `ping YOUR_IP` من جهاز آخر

### مشكلة 3: Model file not found
**الحل:**
- تأكد من وجود: `csrnet_server/saved_models/csrnet_epoch_81.pth`
- تأكد من الاسم صحيح
- تأكد من المسار صحيح

### مشكلة 4: Flask import error
**الحل:**
```bash
cd csrnet_server
venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

### مشكلة 5: Camera permission denied
**الحل:**
- Android: Settings → Apps → Sahalat → Permissions → Camera → Allow
- أو أعد تثبيت التطبيق

---

## 📦 Build APK للتوزيع

### Debug Build (للتجربة)
```bash
flutter build apk --debug
```
الملف في: `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build (للنشر)
```bash
flutter build apk --release
```
الملف في: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📊 اختبار الميزات

### 1. اختبار Navigation
1. افتح التطبيق
2. اذهب لـ **Navigation**
3. اختر **Start From**: My Current Location
4. اختر **Destination**: Food Court
5. اضغط **Navigate**
6. تحقق من ظهور المسار

### 2. اختبار AI Crowd Detection
1. اذهب لـ **Navigation**
2. اختر destination واضغط Navigate
3. في الـ Dialog، اختر **Scan Crowd**
4. صور منطقة فيها ناس
5. تحقق من ظهور العدد المقدر

### 3. اختبار Unity AR
1. بعد حساب المسار
2. اضغط **Send route to Unity AR**
3. يجب أن يفتح Unity AR scene
4. استخدم زر Back للعودة للتطبيق

### 4. اختبار Car Parking
1. في شاشة Navigation
2. اضغط **Save Car Location**
3. تحرك لمكان آخر
4. اضغط **Go to Car**
5. تحقق من ظهور المسار للسيارة

---

## 🌐 Network Configuration

### للتجربة على نفس الشبكة
1. كمبيوتر وجوال على نفس WiFi
2. احصل على IP الكمبيوتر
3. حدث IP في `crowd_detection_service.dart`
4. شغل السيرفر على `0.0.0.0:5000`

### للديمو/المناقشة
1. استخدم hotspot من الكمبيوتر
2. وصل الجوال على الـ hotspot
3. IP الكمبيوتر يكون عادة: `192.168.137.1`
4. أو استخدم `ipconfig` لمعرفة IP

---

## 📝 ملاحظات مهمة للفريق

### قبل Push للـ GitHub:
```bash
# تأكد من الـ .gitignore
# لا ترفع:
- android/unityLibrary/
- csrnet_server/saved_models/*.pth
- venv/
- build/
- .env
```

### قبل المناقشة:
1. شغل السيرفر قبل بساعة
2. اختبر كل الميزات
3. جهز بيانات demo (صور للزحام)
4. احتياط: حط screenshots للـ fallback

### تقسيم المهام:
- **عضو 1**: Flutter UI & Navigation Logic
- **عضو 2**: AI Integration & Python Server
- **عضو 3**: Unity AR & Testing
- **عضو 4**: Documentation & Presentation

---

## 🆘 للمساعدة

إذا واجهتك مشكلة:
1. اقرأ error message بتمعن
2. ابحث في هذا الملف
3. Google الخطأ
4. اسأل الفريق
5. راسل المشرف

---

## ✅ Checklist قبل التسليم

- [ ] كل الميزات تشتغل
- [ ] README.md كامل ومحدث
- [ ] SETUP_GUIDE.md واضح
- [ ] .gitignore صحيح
- [ ] No API keys في الكود
- [ ] Comments في الكود المهم
- [ ] Screenshots في `docs/`
- [ ] Video demo جاهز
- [ ] Presentation slides جاهزة

---

**Good Luck! 🎉**
