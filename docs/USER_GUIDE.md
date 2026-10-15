# Gym Assistant user guide

This guide is for coaches using Gym Assistant, separate from the development tutorial
and product specifications. It is a starting point, not yet a complete app manual.

## Session entry — development build only

This is implemented on the feature branch, not installed or yet verified through
the native Notes shortcut. After opening autocomplete with Option-Command-G,
Command-P chooses **Program session**. Once the selected note has been captured,
Return opens its latest session or reuses its existing scratchpad. The Service
returns before the programming window opens; this action does not insert text.

If Notes access is missing, choose **Allow Notes access**. After granting access,
select the intended note in Notes and explicitly choose **Use currently selected
Notes note**. Granting permission does not silently capture a new selection.

This development route uses a clearly labeled local test assistant, not OpenAI,
and has no coaching profile loaded. Damaged-file recovery and uncertain initial
boundary entry remain unfinished. Do not treat this as the completed product slice.

### Start or resume a new session

Choose **New session** (Command-N in the programming entry window). Existing
unrecorded work reopens instead of creating another copy. Otherwise, review the
headings-only preview and choose **Create scratchpad** or **Cancel**. Nothing is
saved merely by previewing. The session number or letter increments automatically;
an ambiguous label becomes `Session [number or letter]`, which you can edit later.
Uncertain headings are listed as **Not copied**; old exercises, doses and results
are not carried forward. If Notes changes during preview, cancel and prepare again.

The scratchpad stays unrecorded until its Notes association is verified. When a
match needs review, choose **Find session in Notes…** (Command-Shift-F, also in Edit). The scratchpad becomes
read-only and the Notes browser temporarily replaces the conversation. Find a
heading, press Tab to focus the Notes text without losing selection, then use
Shift–Arrow or drag to select the session paragraphs. The left
**Compare with source** toggle shows text-only differences for that selection—not
formatting differences; Command-Shift-D toggles it, also from Edit.
**Associate selected session** connects identity without
replacing either version (Command-Return confirms). Cancel returns to editing;
in a focused heading search, Escape clears the search first and a second Escape
cancels review. If comparison is still on, turn it off to edit. Notes changes require a new
selection; a region owned by another workspace cannot be selected for association.

Choose **Not pasted yet** only if the scratchpad is still an addition, not a session
already in Notes. This refreshes context without changing scratchpad content.
These development interactions have automated tests and a bounded native pass with
synthetic content, including keyboard-only new-session creation, heading search,
comparison and association. Broader keyboard selection and real Notes integration still
need acceptance; they are not installed by these changes.

## Recover a saved scratchpad

If a saved scratchpad cannot be opened, the entry window offers **Preview last valid
backup…**. Review its read-only contents, revision and backup file modification time;
it may omit more recent edits. **Cancel** changes nothing. **Restore this backup**
(Command-Return) restores the local snapshot, including saved conversation and unsent
message. Notes is not changed. The damaged file is preserved separately beside the
backup, which remains intact. Choose the session again to recheck its Notes association.

If files changed during preview, reopen the preview before retrying. If other
scratchpads are retained in the app, quit normally to save them and relaunch before
restoring. When no valid backup is available, files stay untouched; the app does not
silently start an empty scratchpad. Newer unsupported file versions cannot be restored
over. Session-association recovery is a separate flow still under development.

## Exercise labels in replies

Exercise names identified in assistant replies can have a subtle underline: solid
means **In library**, dotted means **Not matched**. Hover to see the label; confirmed
aliases also show their canonical name. Not matched means unresolved wording, not
necessarily a new exercise. Undecorated text carries no library-status claim.
For keyboard access, choose Edit → Focus Conversation (Command-Shift-M), then use
Tab/Shift-Tab to move between decorated names and reveal their labels. Tab after
the last name leaves the conversation. Names remain ordinary selectable text;
there are no exercise action menus. This is implemented in the development build;
real-provider mention identification is not yet connected.

## Paste formatted Markdown into Apple Notes

The development scratchpad has a Format menu (not yet in the installed Service):

| Format | Shortcut |
| --- | --- |
| Heading | Option-Command-2 |
| Subheading | Option-Command-3 |
| Body | Option-Command-0 |
| Bold | Command-B |
| Bulleted list | Option-Command-7 |

Paragraph commands affect the current or selected paragraphs; Bold affects selected
text or what you type next. Return continues a bullet; Return on an empty bullet
returns to Body. Formatting commands do not target chat or the read-only comparison.
If copy reports a list paragraph without a visible marker, select that paragraph
and choose Body or Bulleted list before copying again.

Use Notes' **Paste as Markdown** command to turn copied Markdown into native headings,
lists and bold text. Ordinary Command-V may paste the Markdown symbols literally.
Your Notes version must offer **Edit → Paste as Markdown**.

Paste at a paragraph boundary so the first heading does not join existing text.
The planned scratchpad handoff may add one blank line after a bulleted list before
ordinary text; this keeps Notes from turning that text into another bullet.

Gym Assistant's session scratchpad and chat handoff are still in development. These
Notes instructions work independently with Markdown copied from another source;
they do not imply the scratchpad feature is already available in the app.

### Set a keyboard shortcut for Notes only

1. Open **System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts**.
2. Click **+** to add an app shortcut.
3. Set **Application** to **Notes**, not All Applications. If Notes is missing,
   choose Other and select Notes from the Applications folder.
4. Enter the exact **Menu Title**: `Paste as Markdown`.
5. Click the **Keyboard Shortcut** field and press **Control–Option–Command–V**
   (`⌃⌥⌘V`), or another unused combination. Press the keys; do not type their names.
6. Click **Done**.
7. In Notes, open **Edit** and confirm the combination appears beside
   **Paste as Markdown**.

This uses macOS **App Shortcuts**, not the Shortcuts app, and applies only to Notes.
See [Apple's app-shortcut instructions](https://support.apple.com/guide/mac-help/create-keyboard-shortcuts-for-apps-mchlp2271/mac).

### Try it safely

Copy this small block, place the cursor on a blank line in a test note, and press
your new shortcut:

```markdown
## Keyboard paste test
### Warmup
* **A1** Single-leg RDL
* Balance preparation
```

The heading markers should disappear, the two headings should have different tiers,
and the exercise label should be bold inside a native bulleted list. Pressing Return
at the end of a list item should continue the list.

If the shortcut does nothing, check the exact menu title, the Notes application
selection and possible shortcut conflicts. You can still use **Edit → Paste as
Markdown** with the mouse. A successful menu paste confirms formatting, not that
the keyboard shortcut is configured correctly.

To remove the custom shortcut, select it under App Shortcuts and click **−**.
