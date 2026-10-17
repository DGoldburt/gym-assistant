# Gym Assistant user guide

This guide is for coaches using Gym Assistant, separate from the development tutorial
and product specifications. It is a starting point, not yet a complete app manual.

## Session entry — development build only

### Optional ChatGPT synthetic trial

A separate development trial can use **5.6 Terra, medium reasoning** through your
ChatGPT plan. It is separate from the real Notes entry. Its title clearly says
**Synthetic trial**; the note context and coaching profile are synthetic, not your
actual client note or full coaching preferences. Do not paste private content into
this trial window. It saves its scratchpad separately from normal workspaces.

In that window, the app menu's **ChatGPT Account…** offers **Continue with ChatGPT**,
**Manage usage**, and **Sign out**. Credentials are stored in macOS Keychain. Signing
out does not delete local planning. If remote revocation cannot be confirmed, the
app tells you to disconnect it in ChatGPT settings.

The trial allows ten submitted requests total, including failed or stopped requests,
and 100 KB of total request text each. Oversized requests are rejected, not trimmed.
There is no output-token cap. Requests use your plan allowance or available credits
under your ChatGPT settings; the app does not buy credits or retry automatically.
If a usage limit is reported, review **Manage usage**. If usage availability could
not be checked, try later; that error does not establish an exhausted allowance.
The bounded synthetic native test has passed; this is not full product acceptance.

### Notes entry

The feature build was installed on 2026-10-17; the combined real-Notes/model flow
still needs manual acceptance. After opening autocomplete with Option-Command-G,
Command-P chooses **Program session**. Once the selected note has been captured,
Return opens its latest session or reuses its existing scratchpad. The Service
returns before the programming window opens; this action does not insert text.

If Notes access is missing, choose **Allow Notes access**. After granting access,
select the intended note in Notes and explicitly choose **Use currently selected
Notes note**. Granting permission does not silently capture a new selection.

The current feature build uses **5.6 Terra, medium reasoning**, through the app's
ChatGPT connection. Only sending a question initiates inference; opening the entry
or reading Notes does not. The request includes the current note context,
scratchpad, conversation and fixed coaching profile. The 100 KB text bound remains,
with no lifetime request cap, automatic retries or background inference. Your
ChatGPT billing settings remain unchanged. Notes are never edited by the model.

Choose **ChatGPT account…** in the entry window to connect, manage usage or sign
out. Opening the panel does not verify current account availability. The existing
**Programming preferences** view shows the same read-only profile supplied to the
assistant, including sources, scope and caveats. Chat cannot edit that profile.

The private profile is loaded from `Library/Application Support/GymAssistant/coaching-profile.json`
in your user folder. Missing or invalid content blocks new programming entry rather
than silently loading an empty profile. The profile is fixed for the current app
session; restart after an externally prepared profile update. The new real-Notes
composition still needs installed/manual acceptance; this is not the completed slice.

### Recover an earlier idea

Choose **Previous planning…** from the programming entry window or scratchpad
(Command-Shift-H). Select a record at the top to view its scratchpad and conversation
side by side, both read-only. Unsent questions are shown separately. Select a passage
and use Command-C, then paste it directly into Notes where useful. Pasting into a
scratchpad is also available, but is not required. Command-W closes the reference window.

Verified session locations are labeled with their current heading. Unlocated records
appear under **Other planning for this note**, with their original heading retained;
the app does not infer identity from a matching session number. If Notes is unavailable,
local planning remains readable without a verified association. The timestamp is the
saved file's modification time, not a claimed session/performance date. An open editor
is captured when the browser opens; reopen the browser to see subsequent edits.

This first browser exposes existing local workspace records, not imported ChatGPT
history or a complete revision timeline. Browsing does not save, repair associations,
or write Notes.

In the scratchpad's comparison view, **Replace scratchpad with current Notes…**
copies the verified session region into the scratchpad after confirmation. Notes
does not change. Conversation and the unsent message remain attached; the previous
scratchpad remains read-only in Previous planning, labeled **Preserved before Notes
replacement**. If the location is uncertain, replacement is unavailable. If either
side changes during confirmation, compare again. An uncertain storage failure locks
editing and asks you to quit and reopen rather than risk overwriting preserved work.

Choose **Set aside…** on a planning record when you no longer want it to remain an
active scratchpad. Review the confirmation: it stops any current reply, preserves the
text, conversation and unsent message, and closes that editor. Cancel does nothing.
The retained record remains read-only in Previous planning but no longer reserves a
Notes region or resumes as unfinished work. Close the browser to return to program
entry. This does not delete content or write Notes; there is no reactivation control
in this slice. Copy any useful material directly into Notes.

If the record changed after opening the browser, reopen Previous planning and review
it again. If saving fails, do not assume set-aside succeeded. Existing files remain
preserved; the app does not release its in-memory editing claim on an unconfirmed save.

For an active record, **Continue scratchpad** reopens the saved editor, even when
its session cannot currently be located. It does not substitute Notes content.
Choose **Find session in Notes…** to review the read-only scratchpad beside Notes,
select the intended paragraphs, and explicitly associate them. Comparison can show
the selected content on the scratchpad side. Confirmation changes location evidence,
not either version's content or the original comparison baseline. Occupied regions
are unavailable. Other unresolved owners or duplicate headings must be resolved
before association; batch recovery is not included. Set-aside and pre-replacement
records remain read-only references, not competing editable scratchpads.

### Start or resume a new session

Choose **New session** (Command-N in the programming entry window). Existing
unrecorded work reopens instead of creating another copy. Otherwise, review the
session-headings and Parking Lot preview and choose **Create scratchpad** or **Cancel**. Nothing is
saved merely by previewing. The session number or letter increments automatically;
an ambiguous label becomes `Session [number or letter]`, which you can edit later.
Uncertain headings are listed as **Not copied**; old exercises, doses and results
are not carried forward from the previous session. A clearly trailing Parking Lot
is copied with its existing ideas and formatting; otherwise an empty Parking Lot
heading is added. Copy includes this section: manually consolidate it into the
note-level Parking Lot after pasting. No automatic merge or deletion occurs.
If Notes changes during preview, cancel and prepare again.

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
