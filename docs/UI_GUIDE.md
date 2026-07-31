# MoonMoon UI Guide

MoonMoon turns a measured lunar site model into one operational question:
**is this route ready to move?** The answer shown by the product is evidence,
not an authorization from the robot preview.

The interface has two pages. Use the header navigation so browser Back,
Forward, refresh, and the selected navigation item stay meaningful:

- **Operator** is the live mission decision, Moon/site view, route comparison,
  illumination evidence, terrain dossier, and robot-adapter boundary.
- **Moonbook & Guide** explains the product vocabulary and includes the local,
  evidence-grounded bookkeeper.

## Operator

### Read the decision first

The right-hand decision rail answers the five-second question:

1. **Mission decision** is the current gate result. `block` means no route
   motion is authorized.
2. **Next required action** says what must happen before simulation.
3. **Site score**, **energy margin**, and **blocked routes** summarize the same
   records shown in the detailed evidence.
4. **Controlling blockers** lists every condition currently holding the gate.
5. **Review blocking evidence** opens and focuses the source and motion-handoff
   evidence. This is the primary action when the decision is blocked.

### Move between Moon and site terrain

- **Moon / Site terrain** switches the world view without changing mission
  selection.
- **Focus site** switches to the measured LOLA site terrain.
- **Return to Moon view** returns to the globe and restores its default camera.
- **Pause orbit / Resume orbit** changes automatic Moon motion only.
- **Physical / Readable** changes visual lighting contrast. Readable mode is a
  display aid and does not change illumination evidence.
- **Lighting timestamp** scrubs the loaded DE440 samples. It supports pointer
  input and arrow keys. The timestamp, Sun altitude, azimuth, Earth phase, and
  3D light update together.

These inspection choices survive refresh in the current browser session.

### Compare routes without changing authority

Open **Compare route candidates** to inspect one of six measured corridors.
Exactly one candidate is visually pressed. The rail explicitly distinguishes:

- **Mission selected route**: the route owned by the loaded mission model.
- **Inspecting candidate; mission selection unchanged**: a comparison view.

Inspecting a candidate updates route score, maximum grade, roughness,
illumination, horizon profile, and terrain overlay. It never promotes that
candidate to mission authority.

### Read illumination evidence

Open **Illumination evidence** to compare:

- the current route window;
- the ranked next window;
- route-visible sunlight;
- longest darkness;
- available energy;
- solar clearance; and
- the local horizon profile and evidence path.

`candidate` means ranked evidence, not clearance. A window is actionable only
after all mission gates pass.

### Inspect terrain cells

Open **Evidence dossier** and choose any of the 16 terrain cells. Exactly one
cell is selected. Its elevation, slope, roughness, hazard, and confidence
update together. Cell inspection does not change route authority.

The dossier also shows:

- all six route records;
- the LOLA source and catalog status;
- the motion contract;
- inspector facts; and
- controlling blockers.

### Understand the adapter preview

Open **Adapter preview** to load the Noetix E1 scene. It is deliberately labeled
**preview only** and **non-authoritative**. Robot motion cannot clear terrain,
illumination, power, or operator-review gates.

## Moonbook & Guide

Moonbook is the product knowledge base. On a narrow window, the bookkeeper is
placed before the longer topic guide so asking a question never requires
hunting down the page.

### Browse topics

The six topic buttons cover:

- mission status;
- terrain evidence;
- illumination;
- route authority;
- robot boundary; and
- project architecture.

Each topic explains the concept, the first useful action, the current authority,
and its source path.

### Ask the bookkeeper

The bookkeeper is local and deterministic. Its answer registry is produced by
the MoonBit UI package from the loaded mission view model. Browser code only
classifies the question and renders the selected MoonBit answer.

Use a common question or type your own:

- “Why is the mission blocked?”
- “What is the best illumination window?”
- “Where does terrain data come from?”
- “Can robot motion authorize a route?”
- Questions about MoonBit, Rabbita, or project architecture.

Every known answer identifies whether it is a Moon fact, mission fact, project
fact, or project boundary and lists its evidence sources. Blank questions
explain what to ask. Unknown questions say that the registry lacks evidence and
offer recoverable categories instead of inventing an answer.

The bookkeeper does not fetch remote sources, infer live telemetry, or grant
route authority.

## Language and accessibility

The interface-language selector supports system preference, English, and
Simplified Chinese. The choice is encoded in the page URL and stored locally,
so the selected option, document locale, refresh, and browser history agree.

Interactive controls expose names and pressed/current states. Primary controls
and the lighting scrubber provide at least 44 px touch targets. The supported
narrow release viewport is 720×900 with no document-level horizontal overflow.

## Recovery

- If an inspected route or cell is confusing, reload: the inspection is
  restored and remains labeled separately from mission selection.
- Use **Return to Moon view** if terrain inspection hides the lighting controls.
- Use **Clear** in Moonbook to reset the question and answer.
- If Moonbook cannot answer, choose a topic or use one of the four common
  questions.
- A blocked decision is not an application error. Use **Review blocking
  evidence** to see the evidence source and required handoff.
