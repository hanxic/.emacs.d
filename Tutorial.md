# Emacs Config — Keybinding Tutorial

A guided reference to this configuration's **custom** keybindings. Built-in
Emacs keys are not repeated here — for those, and for the always-current
version of everything below, use the live discovery tools first.

---

## 0. Discover keys live (the real "searchable manual")

A static list goes stale the moment you rebind something. These stay current:

| Tool | How | What it gives you |
|------|-----|-------------------|
| **which-key** | Just pause after a prefix (`C-c p`, `C-c o`, …) | A popup of every key + command under that prefix. Already on (0.3s delay). |
| **describe-bindings** | `C-h b` | Every active binding in the buffer. |
| **helm-descbinds** *(recommended add)* | `C-h b` | Same, but fuzzy-searchable by key **or** command name. |
| **helpful** | `C-c C-d` (at point), `C-h k` <key>, `C-h F` <fn> | Rich help: source, docs, and what a key/command does. |

> Rule of thumb: to *find* a key, type its prefix and read the which-key popup.
> To *search by intent* ("what runs the tests?"), use `helm-M-x` (`M-x`) — it
> shows the bound key next to each command.

Everything below is the map of the **custom layer** on top of that.

---

## 1. The two prefix maps

Almost all personal commands live under two prefixes:

- **`C-c p`** — personal map (compile, terminal, files, helm, previews, notes)
- **`C-c o`** — org map (capture, agenda, todo)

Type either and pause to let which-key show the menu.

---

## 2. Compile / Run / Test  (`C-c p`)

Context-aware: the same key builds a LaTeX doc in a `.tex` buffer, runs the
project's remembered command in a project, or plain `compile` otherwise.

| Key | Command | Notes |
|-----|---------|-------|
| `C-c p c` | compile | LaTeX → build doc; project → projectile compile (remembers per project) |
| `C-c p r` | run | project run command |
| `C-c p k` | test | project test command (`k` = "check"; `t`/`T` are iTerm) |

Add `C-u` to any of them to re-prompt / change the stored command.
Recompile = just press `C-c p c` again.

---

## 3. Terminal & iTerm2  (`C-c p`)

Two philosophies coexist: **iTerm2** for interactive/exploratory shell work,
**vterm** as an in-Emacs fallback.

| Key | Command | Notes |
|-----|---------|-------|
| `C-c p t` | iTerm2 here | Focus iTerm2's active tab, `cd` to project root |
| `C-c p T` | iTerm2 new tab | New tab at project root |
| `C-c p v` | vterm | Terminal inside Emacs |
| `C-c p V` | multi-vterm | Another vterm |
| `C-c p i` | open-in-iterm (tab) | Open *this file's* directory in an iTerm tab |
| `C-c p I` | open-in-iterm (window) | …in a new iTerm window |

### Inside a vterm buffer (evil normal state)

| Key | Action |
|-----|--------|
| `,n` | new vterm |
| `,>` / `,<` | next / previous vterm |
| `i` / `o` / `RET` | resume insert (type into the shell) |

Most `C-<key>` combos (C-a, C-e, C-r, C-w, …) pass straight through to the
shell in insert state.

---

## 4. Files, previews, Finder  (`C-c p`)

| Key | Command |
|-----|---------|
| `C-c p f` | open current file's dir in Finder |
| `C-c p n` | new research note |
| `C-c p p …` | **preview submap** (view a file/dir read-only) |

Preview submap (`C-c p p`):

| Key | Opens |
|-----|-------|
| `C-c p p i` | `init.el` |
| `C-c p p b` | `~/.bin` |
| `C-c p p r` | `~/research` |
| `C-c p p p` | `~/projects` |
| `C-c p p z` | `~/.zshrc` |

---

## 5. Search & navigation (helm)  (`C-c p h` + globals)

| Key | Command |
|-----|---------|
| `M-x` | helm-M-x |
| `C-x b` / `C-x C-b` | helm-mini (buffers) |
| `C-x C-f` | helm-find-files |
| `C-M-j` | helm buffers list |
| `M-p` | helm kill-ring |
| `C-c h o` | helm-occur |

Projectile via helm (`C-c p h`):

| Key | Command |
|-----|---------|
| `C-c p h h` | helm-projectile (files in project) |
| `C-c p h p` | switch project |
| `C-c p h r` | ripgrep in project |
| `C-c p h a` | ag in project |
| `C-c p h g` | grep in project |
| `C-c p h o` | find other file |
| `C-c p h s` | helm-rg |

---

## 6. Org & TODO  (`C-c o`)

| Key | Command |
|-----|---------|
| `C-c o c` | org-capture |
| `C-c o a` | org-agenda |
| `C-c o t` | personal TODO manager |

### Org agenda (evil normal state)

`TAB` goto · `RET` switch-to · `+` / `-` priority · `d` day view · `w` week view

### TODO manager buffer

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `j` / `k` | move down / up | `a` | add |
| `d` | delete | `t` / `T` | cycle / set state |
| `p` | set priority | `s` | schedule |
| `RET` | open notes | `o` | open file |
| `/` | filter | `\` | clear filter |
| `g` | refresh | `q` | quit |

---

## 7. Editing (evil & friends)

| Key | Action |
|-----|--------|
| `j` / `k` (motion) | move by *visual* line |
| `TAB` (normal/visual) | context indent |
| `C-<tab>` | indent keymap — then `<left>`/`<right>` to shift region |
| `C-h` (insert) | delete-backward (join) |
| `M-;` | comment / uncomment lines |
| `<up>` / `<down>` (isearch) | search-ring history |

---

## 8. LaTeX

| Key | Action |
|-----|--------|
| `C-c p c` | build the document (see §2) |
| `<backspace>` / `DEL` | smart backspace (unwraps pairs/environments) |
| `x` / `X` (normal) | LaTeX-aware delete |

---

## 9. Git, checks, undo, dired

| Key | Command |
|-----|---------|
| `C-x g` / `C-x C-g` | magit-status |
| `C-c C-j n` / `C-c C-j p` | flycheck next / previous error |
| `s-z` / `s-Z` | undo-fu undo / redo |
| `C-x C-j` / `C-x j` | dired-jump |
| `?` (dired) | dired summary |
| `C-c +` (dired) | create empty file |

### Resolving merge conflicts

Preferred flow — drive it from magit with ediff (memorable keys, no prefixes):

1. `C-x g` → open magit-status.
2. Point on a conflicted (**Unmerged**) file → `e` → launches a 3-way ediff.
3. In ediff: `n` / `p` move between conflicts, `a` take **A** (HEAD/ours),
   `b` take **B** (theirs/incoming), `!` refine, `q` quit + save.
4. Back in magit: `s` stage the resolved file, `c c` commit to finish the merge.

Ediff is forced into a single frame (side-by-side) so no floating control
window appears.

Fallback — **smerge** for quick one-liners. Any file with conflict markers
auto-enables `smerge-mode`; you never `M-x` it. Don't memorize the keys — press
`C-c ^` and pause, and which-key lists them (labelled **smerge**):

| Key | Action |
|-----|--------|
| `C-c ^ n` / `p` | next / previous conflict |
| `C-c ^ RET` | keep the hunk at point |
| `C-c ^ u` | keep upper (HEAD / ours) |
| `C-c ^ l` or `o` | keep lower (incoming) |
| `C-c ^ a` | keep both |
| `C-c ^ E` | hand this conflict to ediff |

---

## 10. Language extras

| Mode | Key | Command |
|------|-----|---------|
| OCaml | `C-M-<tab>` | ocamlformat |
| Lean4 (ghost) | `C-c C-n` / `C-c C-p` | step next / prev |
| Copilot | `C-<tab>` | accept completion *(while a suggestion is showing)* |

---

## Maintaining this file

This is a hand-curated overview, so it can drift. When you change a binding,
prefer trusting **which-key / `C-h b`** as the source of truth, and update the
relevant section here only for the keys you use often. If it drifts too far,
regenerate from the `define-key` / `:bind` forms across `lisp/`.
