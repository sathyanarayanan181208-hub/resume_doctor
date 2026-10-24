# 🩺 Resume Doctor

> **Open-Source AI Resume Reviewer & ATS Sanitizer**  
> Built for the MLH Hackathon prizes: **"Best Use of Gemma 4"** and **"Best Open-Source AI Project"**.

[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)
[![Powered by Gemma](https://img.shields.io/badge/Model-Gemma%204%20%2F%20Gemma%202-blue.svg)](https://ai.google.dev/gemma)
[![Privacy: 100% Client-Side](https://img.shields.io/badge/Privacy-100%25%20Client--Side-brightgreen.svg)](#-privacy--security-architecture)
[![XSS Protection: textContent Only](https://img.shields.io/badge/Security-XSS--Free%20DOM-emerald.svg)](#-xss-prevention--sanitization)
[![Zero Build Steps](https://img.shields.io/badge/Stack-Vanilla%20JS%20%2F%20Single%20File-orange.svg)](#-quickstart)

---

## 📋 Overview

Over **75% of resumes are discarded by Applicant Tracking Systems (ATS)** before a human recruiter ever sees them. Common culprits include:
- Two-column layouts, tables, and text boxes that scramble text order.
- Fancy icons, graphics, and non-standard bullet characters (`★`, `❖`, `✈`).
- Non-standard section headings (e.g., *"My Journey"*, *"About Me"*, *"Tech I Like"*).
- Vague bullet points with zero quantifiable metrics or missing action verbs.
- Inconsistent verb tenses (past tense for current jobs or present tense for past jobs).
- Keyword gaps when evaluated against a specific job description.

**Resume Doctor** cures your resume before the ATS rejects it. Users upload a resume (PDF, scanned image, or text), and Resume Doctor runs a deep audit using **Gemma 4**, scores ATS-friendliness out of 100, itemizes every flaw with actionable prescriptions, and rewrites the resume into a **clean, single-column, plain-text ATS-safe format**.

---

## ✨ Features

### 1. Multimodal & Versatile Input
- **PDF Extraction**: 100% client-side text parsing using [PDF.js](https://mozilla.github.io/pdf.js/). Multi-page coordinate aware text stitching prevents jammed words.
- **Scanned Resumes & Images**: Automatically detects scanned resumes (PNG, JPG, WEBP) or zero-text PDFs. Resizes images to **max 1600px** on an HTML5 canvas before transmitting to the multimodal model.
- **Plain Text / Direct Editing**: Upload `.txt` files or type/paste directly into the editable input pane with live word and character counters.
- **Target Job Alignment**: Optional fields for **Target Role** and **Job Description** to perform automated keyword matching and missing-skills gap analysis.
- **Pre-Loaded Sample Resumes**: Instant 1-click test resumes (*Junior SWE* and *Technical PM*) with realistic flaws and job descriptions so judges can test instantly without uploading their own resume.

### 2. Comprehensive Diagnostic Engine
Resume Doctor tests across 7 rigorous dimensions:
1. **Spelling & Grammar**: Flags syntax slips, typos, and informal phrasing.
2. **Inconsistent Tense & Dates**: Enforces past tense for previous positions, present tense for current roles, and consistent date formatting (e.g. `Month YYYY` throughout).
3. **Missing Contact Info & Sections**: Verifies email, phone, location, LinkedIn/GitHub, and standard sections (`SUMMARY`, `SKILLS`, `EXPERIENCE`, `PROJECTS`, `EDUCATION`, `CERTIFICATIONS`).
4. **Bullet Point Impact**: Catches weak, passive duties and requires strong action verbs with quantifiable metrics (numbers, %, $, scale).
5. **ATS Formatting Traps**: Flags tables, columns, graphics, avatars, and non-standard headings.
6. **Length & Density**: Evaluates whether page length matches career seniority.
7. **Job Keyword Gap Audit**: Cross-references against the target job description, listing matched keywords and missing keywords.

### 3. Diagnostic Output Dashboard
- **ATS Health Score (0–100)**: Color-coded radial gauge with condition status (*Critical Condition*, *Needs Treatment*, *Healthy*, *ATS Optimus*).
- **Sub-Score Breakdown**: 4 individual bars for *ATS Formatting*, *Bullet Impact & Metrics*, *Grammar & Consistency*, and *Role & Keyword Fit*.
- **2-Sentence Executive Prognosis**: Clear, executive-level diagnosis summarizing main failure points.
- **Prescribed Fixes Checklist**: Filterable by severity (**All**, **High**, **Medium**, **Low**) with section badge, problem description, and the doctor's prescription fix.
- **Keyword Diagnostic Pills**: Interactive matched (green) and missing (orange) keyword chips.
- **Collapsible Raw JSON Inspector**: Inspect the raw structured JSON output for complete transparency and debugging.

### 4. Sanitized Plain-Text Rewritten Resume
- **Single-Column & Plain Text**: Guaranteed parser readability across all legacy and modern ATS platforms (Workday, Taleo, Greenhouse, Lever, iCIMS).
- **Standardized Headings**: Strictly utilizes universal headers:
  - `SUMMARY`
  - `SKILLS`
  - `EXPERIENCE`
  - `PROJECTS`
  - `EDUCATION`
  - `CERTIFICATIONS`
- **Zero Hallucination Guarantee**: Gemma is instructed to **never** invent jobs, companies, degrees, numbers, metrics, or skills.
- **`[ADD: ...]` Placeholders**: If critical details or metrics are missing, the rewrite marks them with `[ADD: what is needed]` (e.g., `[ADD: LinkedIn Profile URL]` or `[ADD: Quantifiable outcome e.g. reduced build time by X%]`).

### 5. Instant Multi-Format Export
- **Copy**: One-click clipboard copy with confirmation toast notification.
- **Download `.txt`**: Instant download of `rewritten_ats_resume.txt`.
- **Print / Save as PDF**: Custom `@media print` styling isolates the rewritten resume in crisp black-and-white 11pt monospace with 1-inch margins, completely hiding navigation, scorecards, and action buttons.

---

## 🔒 Privacy & Security Architecture

Privacy is paramount when handling personal career documents. Resume Doctor is built around a zero-trust, client-only privacy model:

1. **No Backend Server**: Resume Doctor runs entirely in the user's browser. There are no tracking scripts, intermediate databases, or telemetry collectors.
2. **Local Key Storage**: API keys are saved exclusively in your browser's `window.localStorage` under `resume_doctor_config`. Keys are never forwarded anywhere other than Google's official Gemini endpoint.
3. **Client-Side PDF Processing**: PDF text extraction and canvas image rendering run 100% inside your browser's V8 engine via WebAssembly/PDF.js.
4. **100% Offline Capability**: With the local **Ollama** provider, resumes never leave your machine—even for AI inference!

### 🛡️ XSS Prevention & Sanitization
In accordance with strict security standards, Resume Doctor **never uses `innerHTML`** to render untrusted AI model output. All dynamic DOM nodes are created with:
- `document.createElement()`
- `element.textContent = ...`
- `document.createTextNode()`

This guarantees zero risk of Cross-Site Scripting (XSS) even if a malicious resume or prompt injection attempt is analyzed.

---

## ⚡ Quickstart

Resume Doctor is packaged as a **single-file web application (`index.html`)** with zero build tools, node modules, or compile steps required.

### Option 1: Direct Browser Launch (Easiest)
1. Download or clone this repository:
   ```bash
   git clone https://github.com/your-username/resume-doctor.git
   cd resume-doctor
   ```
2. Double-click `index.html` or open it directly in Chrome, Edge, Safari, or Firefox:
   ```bash
   # On Windows:
   start index.html

   # On macOS:
   open index.html

   # On Linux:
   xdg-open index.html
   ```

### Option 2: Run via Local HTTP Server
If preferred, you can serve `index.html` via any static file server:

```bash
# Using Python 3 (if installed):
python -m http.server 8000

# Using Node / npx:
npx serve .

# Using VS Code:
Right-click index.html -> "Open with Live Server"
```
Visit `http://localhost:8000` in your web browser.

---

## 🤖 AI Provider Configuration

Click **⚙️ Settings** in the top navigation bar to choose your AI provider.

### Option A: Google AI (Gemini / Gemma API) — Default
1. Obtain a free Google AI Studio API key at [ai.google.dev](https://aistudio.google.com/app/apikey).
2. Paste your API key into the settings modal.
3. Select your model:
   - **Gemma 4** (`gemma-4`)
   - **Gemma 2 9B IT** (`gemma-2-9b-it`)
   - **Gemma 2 27B IT** (`gemma-2-27b-it`)
   - **Gemini 2.0 Flash** (`gemini-2.0-flash`)
   - **Gemini 1.5 Flash** (`gemini-1.5-flash`)
   - Or input any custom model identifier.
4. Click **Test Connection** & **Save Settings**.

### Option B: Ollama (100% Offline & Air-Gapped)
Resume Doctor natively supports local inference through Ollama's `POST /api/chat` endpoint:

1. Install [Ollama](https://ollama.com/) on your machine.
2. Pull Gemma:
   ```bash
   ollama pull gemma2
   ```
3. Start the Ollama daemon with CORS enabled for browser access:
   ```bash
   # On Windows (PowerShell):
   $env:OLLAMA_ORIGINS="*"
   ollama serve

   # On macOS / Linux:
   OLLAMA_ORIGINS="*" ollama serve
   ```
4. In Resume Doctor, click **⚙️ Settings** -> **Ollama (Offline / Local)**.
5. Set Host URL to `http://localhost:11434` and Model to `gemma2` (or `gemma2:9b`).
6. Click **Test Connection** & **Save Settings**.

---

## 🚀 Deployment Instructions

Because Resume Doctor is a pure static web app, it can be deployed for free in under 2 minutes:

### Deploy to GitHub Pages

1. Push your repository to GitHub:
   ```bash
   git init
   git add .
   git commit -m "Initial commit of Resume Doctor"
   git branch -M main
   git remote add origin https://github.com/<your-username>/resume-doctor.git
   git push -u origin main
   ```
2. Navigate to your repository on GitHub.
3. Go to **Settings** -> **Pages** (under "Code and automation" in the left sidebar).
4. Under **Build and deployment**:
   - **Source**: `Deploy from a branch`
   - **Branch**: `main`
   - **Folder**: `/ (root)`
5. Click **Save**.
6. Within 60 seconds, your site is live at:  
   `https://<your-username>.github.io/resume-doctor/`

---

### Deploy to DigitalOcean App Platform (Static Site)

1. Sign in to your [DigitalOcean Cloud Console](https://cloud.digitalocean.com/).
2. In the navigation bar, click **Create** -> **Apps** (App Platform).
3. Choose **GitHub** as the Service Provider and authorize your account.
4. Select the `resume-doctor` repository and branch `main`.
5. DigitalOcean will automatically detect `index.html`:
   - Set **Resource Type** to **Static Site**.
   - **Output Directory**: Leave empty or set to `/` (root).
   - **Build Command**: Leave empty (no build step needed).
6. Select the **Starter (Free)** tier.
7. Click **Next** -> **Create Resources**.
8. DigitalOcean will deploy the app and provide a live URL like `https://resume-doctor-xxxxx.ondigitalocean.app/`.

---

## 🏆 Hackathon Alignment: Why Resume Doctor Wins

### 1. Best Use of Gemma 4
- **Specialized System Prompting**: Leverages Gemma's advanced instruction-following to enforce strict JSON structure and adhere to uncompromising anti-hallucination constraints (`[ADD: ...]` tags).
- **Multimodal Scanned Resume Audit**: Uses Gemma's vision capabilities to visually inspect formatting cues, misaligned columns, and graphical elements in scanned resumes.
- **Nuanced Semantic Critique**: Gemma doesn't just match keywords; it analyzes linguistic tone, passive voice, and date continuity across career timelines.

### 2. Best Open-Source AI Project
- **Zero Lock-In**: Works out-of-the-box with cloud APIs or local air-gapped open models (Ollama).
- **Self-Contained Architecture**: Single-file design (`index.html`) ensures complete portability without `node_modules` dependency rot.
- **User Agency & Privacy**: Users own their keys, their data, and their resumes.
- **Practical Utility**: Solves an urgent, universal problem for millions of job seekers globally.

---

## 📁 Repository Structure

```
resume_build/
├── index.html        # Complete single-file application (HTML5, responsive CSS, vanilla JS)
├── LICENSE           # Standard MIT Open Source License
└── README.md         # Full project documentation & deployment guide
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — free for personal, commercial, and educational use.
