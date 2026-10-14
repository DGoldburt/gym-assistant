# Gym Assistant user guide

This guide is for coaches using Gym Assistant, separate from the development tutorial
and product specifications. It is a starting point, not yet a complete app manual.

## Paste formatted Markdown into Apple Notes

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
