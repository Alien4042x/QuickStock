# 📊 QuickStock

**macOS stock analyzer app** built with Swift – delivered ready to use!  
No Xcode required – just download, run, and start searching for tickers.

---

## ⚙️ Requirements

- macOS 12 or later
- Internet connection (the app fetches live data)

---

## 🔐 API Key Required

QuickStock uses the [Financial Modeling Prep API](https://site.financialmodelingprep.com/developer).

To use the app, you’ll need to:

1. Register for a free account:  
   👉 https://site.financialmodelingprep.com/developer

2. Get your API key.

3. On first launch, the app will ask you to enter your key.

---

## ⚠️ Free Plan Limitations

Some metrics like **EBIT Margin** or **Profit Margin** are available only on paid plans.  
These will be shown as:

🔒 Premium

yaml
Zkopírovat
Upravit

If you upgrade your plan, they’ll be automatically shown without changing anything in the app.

---

## 📷 Screenshots

### ✅ Example (Free data available)
![AAPL Screenshot](screenshots/aapl.png)

### 🔒 Example with Premium-only fields
![BTI Screenshot](screenshots/bti.png)

---

## 📁 Included in this repo

- Compiled `.app` file (ready to run)
- Source code (for devs)
- `.gitignore`, `LICENSE`, `README.md`

---

## 👨‍💻 For Developers

You’re welcome to dive into the code and customize it.  
Open the project in Xcode (`QuickStock.xcodeproj`), insert your API key, and build away.

---

## 🧾 License

MIT License.  
You’re free to use, modify, and redistribute.  
**Note:** You are still responsible for complying with Financial Modeling Prep’s [Terms of Service](https://site.financialmodelingprep.com/terms-of-service).

---

Made with ❤️ by **Alien4042x**
