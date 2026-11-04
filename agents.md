# Agent Instructions: Support Repository

This repository (`support`) contains helper scripts, installation tools, and step-by-step guides for friends and users who are not well-versed in the deep technical workings of IT.

When contributing to, creating, or modifying projects in this repository, all agents must adhere to the following principles and standards.

---

## 1. Project Purpose & Target Audience

- **Audience:** Everyday computer users, gamers, friends, and family who need solutions that "just work" without requiring command-line mastery or deep OS knowledge.
- **Goal:** Automate technical tasks (e.g., SteamOS tweaks, proton prefix fixes, game modding/tracking setups) and provide foolproof, safe, and beginner-friendly instructions.

---

## 2. Documentation Standards (READMEs)

Every project folder **must** have its own `README.md` adhering to the following rules:

### A. Dual Language Requirement (English & German)
- Every project `README.md` must be written in **both English and German**.
- Include a quick-jump language switcher at the top:
  ```markdown
  **[English](#english) · [Deutsch](#deutsch)**
  ```
- Both sections must mirror each other in structure, clarity, and completeness.
- In German translations, use natural phrasing and localized UI terms (e.g., for SteamOS/KDE: *„Zum Desktop wechseln“*, *„Konsole“*, *„Strg+Umschalt+V“*, *„Ein/Aus“*).

### B. Written for Novice Users
- **Clear, sequential steps:** Number every step chronologically.
- **Explicit UI paths:** Guide the user click-by-click using bold breadcrumbs (e.g., **Steam button** → **Power** → **Switch to Desktop**).
- **Exact keyboard shortcuts:** Clearly state key combinations (e.g., **Ctrl+Shift+V** to paste into Konsole, **Strg+Umschalt+V** in German).
- **Proactive reassurance:** Address common novice concerns before they cause confusion:
  - *Example:* "You won't see the characters as you type your password—that is completely normal."
  - *Example:* "The download is around 190 MB, so it may take a few minutes. Wait until you see 'All done!'."
- **Helpful troubleshooting:** Tell users what to do if something goes wrong (e.g., "If you see an ERROR message, read it or take a screenshot and send it over").
- **Separation of technical details:** Keep the primary guide clean and simple. Place technical explanations (e.g., how DLL overrides work, patch details, architecture) in a separate *"What the script does, technically"* section at the bottom for advanced users or future maintainers.

---

## 3. Scripting & Tooling Guidelines

When creating or modifying helper scripts:

1. **Frictionless Run Commands:**
   - Provide a single, copy-pasteable command (e.g., `curl -fsSL <url> | bash`) or desktop shortcuts/launchers where possible.
2. **Safety First:**
   - Never overwrite or delete user data silently. Show what will be modified or removed, and ask for confirmation before destructive actions.
3. **Friendly, Informative Terminal Output:**
   - Print clear progress indications.
   - End successful runs with a distinct, reassuring message like `All done!`.
   - On errors, print clear explanations and actionable advice instead of cryptic raw stack traces.
4. **Security & Integrity:**
   - Verify checksums (SHA256) when downloading third-party tools or binaries.
   - Avoid requiring `sudo` unless strictly necessary. If root permissions are required, explain why and guide the user through setting/using their password.

---

## 4. Repository Maintenance

- **Subfolder Structure:** Each distinct tool or guide lives in its own subfolder (e.g., `opentrack/`).
- **Root README:** Keep the table in the root `README.md` updated whenever a new tool or directory is added, referencing the folder and a brief description with `(English & Deutsch)`.
