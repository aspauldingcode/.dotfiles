# Tmux Master Guide

Welcome to your optimized **Tmux** environment. This setup is designed to be ergonomic, persistent, and beginner-friendly with interactive hints.

## ⌨️ The Prefix: `Ctrl-a`
The default prefix has been changed from `Ctrl-b` to **`Ctrl-a`** for better ergonomics.
> In this guide, `prefix` refers to pressing `Ctrl-a` then releasing before the next key.

---

## 🆘 How to learn keybinds (Interactive)
If you ever forget a keybind, just press:
### **`prefix + ?`**
This opens an interactive **Which-Key** menu where you can search and execute any tmux command. This is your best friend for learning!

---

## 🏗️ Managing Panes & Windows

| Action | Keybind |
|---|---|
| **Split Vertical** | `prefix + |` |
| **Split Horizontal** | `prefix + -` |
| **Kill Pane** | `prefix + x` |
| **Create Window** | `prefix + c` |
| **Next Window** | `prefix + n` |
| **Previous Window** | `prefix + p` |
| **Zoom Pane** | `prefix + z` |

---

## 🖱️ Mouse Support
Mouse mode is **ON**. You can:
- Click to select panes
- Drag to resize panes
- Scroll to enter copy-mode
- Use your mouse to select text

---

## 🏃 Navigation (Vim-Style)
You can navigate between Tmux panes and Neovim splits seamlessly using:
- `Ctrl-h` (Left)
- `Ctrl-j` (Down)
- `Ctrl-k` (Up)
- `Ctrl-l` (Right)

---

## 📋 Copy & Paste (Vi-Mode)
Enter copy mode with `prefix + [`:
1. Navigate with `h`, `j`, `k`, `l`
2. Start selection with `v`
3. Copy with `y` (automatically syncs to system clipboard)
4. Paste with `prefix + ]`

---

## 💾 Session Persistence
Your sessions are automatically saved and restored:
- **Save manually:** `prefix + Ctrl-s`
- **Restore manually:** `prefix + Ctrl-r`
- **Continuum:** Automatically saves every 15 minutes and restores on startup.

---

## 🔗 URLs
Want to open a link in your terminal?
Press **`prefix + u`** to fuzzy-search all URLs in the current pane and open them in your browser.
