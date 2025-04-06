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
   👉 https://site.financialmodelingprep.com/register

2. Get your API key.

3. On first launch, the app will ask you to enter your key.

---

## ⚠️ Free Plan Limitations

Some metrics like **EBIT Margin** or **Profit Margin** are available only on paid plans.  
These will be shown as:

🔒 Premium

If you upgrade your plan, they’ll be automatically shown without changing anything in the app.

Note: Although the free plan on Financial Modeling Prep offers 250 API calls per day,
the app makes 2 API calls per ticker search, which effectively limits you to 125 ticker searches per day.
---

## 📷 Screenshots

### ✅ Example (Free data available)
![Apple](https://github.com/user-attachments/assets/ddf5b976-35bb-4841-811c-ae9f328ace03)

### 🔒 Example with Premium-only fields
![BTI](https://github.com/user-attachments/assets/10541b3d-b701-4a48-a2b3-dc62166ffa4c)


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
