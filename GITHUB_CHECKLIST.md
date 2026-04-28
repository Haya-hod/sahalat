# ✅ GitHub Push Checklist

## قبل رفع المشروع على GitHub

### 1. ✅ الملفات اللي **لازم** تكون موجودة

#### Flutter App Files
- [ ] `lib/` - كل ملفات الكود
- [ ] `pubspec.yaml` - ملف dependencies
- [ ] `pubspec.lock` - locked versions
- [ ] `android/app/` - Android configuration
- [ ] `assets/` - الصور والخطوط
- [ ] `test/` - Unit tests (إذا موجودة)
- [ ] `README.md` - الملف الرئيسي
- [ ] `SETUP_GUIDE.md` - دليل التثبيت
- [ ] `.gitignore` - ملف ignore
- [ ] `analysis_options.yaml` - Flutter linting

#### CSRNet Server Files
- [ ] `csrnet_server/api_server.py` - Flask server
- [ ] `csrnet_server/model.py` - Model definition
- [ ] `csrnet_server/run_server_forever.py` - Auto-restart script
- [ ] `csrnet_server/requirements.txt` - Python dependencies
- [ ] `csrnet_server/start_forever.bat` - Windows startup script
- [ ] `csrnet_server/README.md` - Server documentation

#### Unity Files (Optional - ممكن repo منفصل)
- [ ] Unity project structure
- [ ] Export instructions في README
- [ ] **لا ترفع** unityLibrary الكاملة (كبيرة جداً)

---

### 2. ❌ الملفات اللي **ما لازم** تكون موجودة

#### Build & Generated Files
- [ ] `build/` folder
- [ ] `.dart_tool/` folder
- [ ] `android/app/debug/`
- [ ] `android/app/release/`
- [ ] `*.apk` files
- [ ] `*.ipa` files

#### Unity Large Files
- [ ] `android/unityLibrary/` (كبيرة جداً ~200MB+)
- [ ] `*.so` files
- [ ] `*.a` files

#### Python Environment & Models
- [ ] `venv/` أو `env/` folder
- [ ] `__pycache__/` folders
- [ ] `*.pyc` files
- [ ] `csrnet_server/saved_models/*.pth` (الموديل كبير جداً)
- [ ] `*.pkl` files

#### Sensitive Data
- [ ] `.env` files
- [ ] API keys
- [ ] Passwords
- [ ] Personal data

#### IDE & System Files
- [ ] `.idea/` (IntelliJ)
- [ ] `.vscode/settings.json` (شخصي)
- [ ] `.DS_Store` (macOS)
- [ ] `Thumbs.db` (Windows)

---

### 3. 🔧 الإعدادات اللي لازم تتحقق منها

#### .gitignore File
```bash
# تأكد من وجود هذه السطور في .gitignore:
/build/
.dart_tool/
/android/unityLibrary/
venv/
__pycache__/
*.pth
*.pkl
saved_models/
*.apk
.env
*.log
```

#### Remove Hardcoded Values
- [ ] IP addresses → استخدم environment variables أو config file
- [ ] API keys → استخدم `.env` file (not in git)
- [ ] Passwords → استخدم secure storage
- [ ] Personal info → استخدم placeholders

---

### 4. 📝 Documentation Check

#### README.md يجب يحتوي على:
- [ ] وصف المشروع
- [ ] Features list
- [ ] Screenshots أو GIFs
- [ ] Installation instructions
- [ ] Requirements
- [ ] Usage examples
- [ ] Architecture diagram
- [ ] Team members
- [ ] License

#### SETUP_GUIDE.md يجب يحتوي على:
- [ ] خطوات التثبيت step by step
- [ ] Python environment setup
- [ ] Unity integration steps
- [ ] Troubleshooting section
- [ ] Network configuration
- [ ] Testing procedures

---

### 5. 🧹 Clean Up قبل Commit

```bash
# 1. Clean Flutter build
flutter clean

# 2. Remove unnecessary files
rm -rf build/
rm -rf .dart_tool/

# 3. Clean Python cache
cd csrnet_server
rm -rf __pycache__/
rm -rf venv/

# 4. Check git status
git status

# 5. Review changes
git diff
```

---

### 6. ✍️ Commit Messages Best Practices

#### Good Commit Messages:
```
✅ "Add A* pathfinding algorithm"
✅ "Implement AI crowd detection with CSRNet"
✅ "Fix GPS location accuracy issue"
✅ "Update README with setup instructions"
```

#### Bad Commit Messages:
```
❌ "fix"
❌ "update"
❌ "changes"
❌ "work done"
```

#### Format:
```
[Type] Short description

Detailed description (if needed)

- Bullet point 1
- Bullet point 2
```

Types:
- `feat:` - new feature
- `fix:` - bug fix
- `docs:` - documentation
- `refactor:` - code refactoring
- `test:` - add tests
- `chore:` - maintenance

---

### 7. 🌿 Branch Strategy

#### Main Branches:
- `main` - Production-ready code
- `develop` - Development branch

#### Feature Branches:
```bash
# Create feature branch
git checkout -b feature/ai-crowd-detection

# Work on feature...

# Merge back to develop
git checkout develop
git merge feature/ai-crowd-detection
```

---

### 8. 📤 Push Steps

```bash
# 1. Check status
git status

# 2. Add all files
git add .

# 3. Commit with message
git commit -m "feat: Add complete stadium navigation system

- Implement A* and Dijkstra pathfinding
- Add CSRNet AI crowd detection
- Integrate Unity AR navigation
- Add GPS location services
- Implement smart facility selection"

# 4. Push to GitHub
git push origin main

# أو إذا أول مرة:
git push -u origin main
```

---

### 9. 🔐 Security Checklist

- [ ] No passwords in code
- [ ] No API keys committed
- [ ] `.env` file in `.gitignore`
- [ ] No personal data in screenshots
- [ ] No sensitive URLs hardcoded

---

### 10. 📊 File Size Check

```bash
# Check large files before commit
find . -type f -size +10M

# إذا في ملفات كبيرة:
# - حطها في .gitignore
# - أو استخدم Git LFS (Large File Storage)
```

#### GitHub Limits:
- Single file: Max **100 MB**
- Repo size: Recommended < **1 GB**

---

### 11. 🎯 Final Checks قبل Share مع الفريق

#### Test on Clean Clone:
```bash
# 1. Clone in new folder
cd /tmp
git clone https://github.com/YOUR_USERNAME/sahalat.git test-clone
cd test-clone

# 2. Follow SETUP_GUIDE.md
# تأكد كل الخطوات تشتغل

# 3. Test app
flutter pub get
flutter run
```

#### Check Links:
- [ ] كل الروابط في README شغالة
- [ ] Screenshots موجودة
- [ ] Links للـ model weights
- [ ] Links للـ external resources

---

### 12. 📱 Create Releases

عشان الفريق يقدر ينزل APK جاهز:

```bash
# 1. Build release APK
flutter build apk --release

# 2. On GitHub:
# - Go to Releases
# - Create new release
# - Tag: v1.0.0
# - Upload app-release.apk
# - Write release notes
```

---

### 13. 👥 Team Collaboration

#### Create Issues:
في GitHub → Issues → New Issue
```
Title: Add Arabic language support
Description:
- [ ] Translate UI strings
- [ ] Add language switcher
- [ ] Test RTL layout
```

#### Use Pull Requests:
```bash
# Team member creates branch
git checkout -b feature/new-feature

# Push to GitHub
git push origin feature/new-feature

# Create Pull Request on GitHub
# Review → Approve → Merge
```

---

## 🚀 Ready to Push?

### Run This Command:
```bash
# Check everything is ready
git status
git diff
flutter analyze
flutter test (if you have tests)
```

### If all looks good:
```bash
git add .
git commit -m "Initial commit: Complete Sahalat navigation system"
git push -u origin main
```

---

## 📮 After Pushing

### Share with Team:
1. ارسل link الـ repository
2. ارسل `SETUP_GUIDE.md`
3. ارسل الموديل weights بشكل منفصل (Google Drive/OneDrive)
4. شارك IP address للـ AI server

### Create Project Board:
- GitHub Projects → New Project
- Add columns: To Do, In Progress, Done
- Create cards for tasks

---

## ✅ Done!

المشروع الحين جاهز للمشاركة مع الفريق! 🎉

**ملاحظة:**
- اتأكد تحذف أي معلومات شخصية قبل النشر
- لو المشروع خاص بالجامعة، خليه **Private** repository
- أضيف زميلاتك كـ Collaborators في Settings → Collaborators

