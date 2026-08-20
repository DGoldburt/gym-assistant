import fs from "node:fs/promises";

const provider = "com.dangoldburt.gym-assistant.notes-spike";
const title = "Gym Assistant Spike — disposable";
const eventsPath = "/private/tmp/gym-assistant-notes-spike-events.jsonl";
const trialPath = "/private/tmp/gym-assistant-notes-spike-current-trial.txt";

function elementIndex(text, needle) {
  const line = text.split("\n").find((candidate) => candidate.includes(needle));
  const match = line?.match(/^\s*(\d+)/);
  if (!match) throw new Error(`Could not find accessibility element: ${needle}`);
  return Number(match[1]);
}

async function eventsFor(trial) {
  let text = "";
  try {
    text = await fs.readFile(eventsPath, "utf8");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  return text
    .split("\n")
    .filter(Boolean)
    .map((line) => JSON.parse(line))
    .filter((event) => event.trial === trial);
}

async function waitForEvent(trial, name, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const event = (await eventsFor(trial)).find((candidate) => candidate.event === name);
    if (event) return event;
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
  throw new Error(`${name} was not observed within ${timeoutMs}ms`);
}

async function quitProvider(sky) {
  try {
    await sky.press_key({ app: provider, key: "super+q" });
  } catch {
    return;
  }
  await new Promise((resolve) => setTimeout(resolve, 300));
}

async function prepareNote(sky, input) {
  const initial = await sky.get_app_state({ app: "Notes", disableDiff: true });
  let body = elementIndex(initial.text, "text entry area");
  await sky.set_value({ app: "Notes", element_index: body, value: `${title}\n${input}` });
  const refreshed = await sky.get_app_state({ app: "Notes", disableDiff: true });
  body = elementIndex(refreshed.text, "text entry area");
  await sky.select_text({
    app: "Notes",
    element_index: body,
    text: input,
    selection_type: "text",
  });
}

function verifyNotesState(text, expected) {
  const lines = text.split("\n");
  const bodyLine = lines.findIndex((line) => line.includes("text entry area"));
  const body = lines.slice(bodyLine, bodyLine + 6).join("\n");
  return {
    exact: body.includes(title) && body.includes(expected),
    focus: /focused UI element is .*text entry area/i.test(text),
  };
}

async function runTrial(sky, trial) {
  if (trial.cold) await quitProvider(sky);
  await fs.writeFile(trialPath, `${trial.id}\n`);
  await prepareNote(sky, trial.input);

  const invocationMs = Date.now();
  await sky.press_key({ app: "Notes", key: "ctrl+alt+super+g" });
  const ready = await waitForEvent(trial.id, "chooser_ready", trial.cold ? 5_000 : 3_000);
  if (trial.cold) await waitForEvent(trial.id, "application_launched", 500);
  await sky.get_app_state({ app: provider, disableDiff: true });

  for (let index = 0; index < trial.downPresses; index += 1) {
    await sky.press_key({ app: provider, key: "Down" });
  }
  await new Promise((resolve) => setTimeout(resolve, 100));
  await sky.press_key({ app: provider, key: trial.cancel ? "Escape" : "Return" });

  const action = await waitForEvent(trial.id, trial.cancel ? "cancel" : "confirm", 1_000);
  const visible = await waitForEvent(trial.id, "visible_proxy", 3_000);
  const notes = await sky.get_app_state({ app: "Notes", disableDiff: true });
  const expected = trial.cancel ? trial.input : trial.choice;
  const verification = verifyNotesState(notes.text, expected);

  const shortcutToReadyMs = ready.timeMs - invocationMs;
  const decisionMs = action.timeMs - ready.timeMs;
  const confirmToVisibleMs = visible.timeMs - action.timeMs;
  const systemMs = shortcutToReadyMs + confirmToVisibleMs;
  const record = {
    id: trial.id,
    kind: trial.cancel ? "warm-cancellation" : trial.cold ? "cold-replacement" : "warm-replacement",
    inputCategory: trial.inputCategory,
    shortcutToReadyMs,
    decisionMs,
    confirmToVisibleMs,
    systemMs,
    fullMs: visible.timeMs - invocationMs,
    exactOutput: verification.exact,
    sameNoteAndRange: verification.exact,
    focusReturned: verification.focus,
    anomaly: null,
    result: verification.exact && verification.focus ? "pass" : "fail",
  };
  return record;
}

export async function runTrials({ sky, trials, resetOutput = false, outputPath }) {
  if (resetOutput) {
    await fs.writeFile(eventsPath, "");
    await fs.writeFile(outputPath, "");
  }
  const records = [];
  for (const trial of trials) {
    let record;
    try {
      record = await runTrial(sky, trial);
    } catch (error) {
      record = {
        id: trial.id,
        kind: trial.cancel ? "warm-cancellation" : trial.cold ? "cold-replacement" : "warm-replacement",
        inputCategory: trial.inputCategory,
        anomaly: String(error),
        result: "fail",
      };
    }
    await fs.appendFile(outputPath, `${JSON.stringify(record)}\n`);
    records.push(record);
    if (record.result === "fail") break;
  }
  return records;
}
