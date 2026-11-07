# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

TodoChecklister is a World of Warcraft addon: a todo list window with chat commands (`/todo`), a keybind, a minimap icon, and an Interface Options panel. The addon is plain Lua 5.1 + FrameXML loaded by the game client. There is no build step and no automated test suite: verification is static analysis plus manual testing in-game.

## Commands

```sh
brew install emmylua_ls   # language server (Rust EmmyLua analyzer); not on npm
pnpm bootstrap            # fetch WoW API annotations (.annotations/) + emmylua_check binary (.tools/)
pnpm check                # static diagnostics over src/ using .emmyrc.json
pnpm vendor [flavor...]   # clone/update Blizzard UI source into vendor/ (retail, classic, classic_era, anniversary, forever)
```

`pnpm check` currently exits non-zero on pre-existing warnings (unused, undefined-field, type mismatches in the original code). Judge a change by whether it adds new diagnostics, not by the exit code.

`pnpm setup` is a pnpm built-in, which is why the fetch script is named `bootstrap`.

Manual testing: the addon folder must be named `TodoChecklister` inside the client's `Interface/AddOns/` (the only installed client is `/Applications/World of Warcraft/_forever_/`). Reload in-game with `/reload` (or `/rl` and `/fs` framestack when `Constants.debugMode` is on, which is hardcoded to the character name "Assis").

## Architecture

### Layers and load order

The game loads `TodoChecklister.toc` → `src/init.xml` → `src/init.lua` → `bindings.xml`. `src/init.xml` includes per-folder XML manifests in a fixed order, and that order is the dependency direction:

| Order | Folder | Role | Depends on |
|---|---|---|---|
| 1 | `libs/` | LibStub, LibDataBroker, LibDBIcon (vendored externals, don't edit) | nothing |
| 2 | `utils/` | `TableUtils`, `FunctionUtils`: pure helpers, no game state, no SavedVariables | nothing |
| 3 | `config/constants.lua` | `Constants`: theme colors, `debugMode` | game API only |
| 4 | `model/` | `Settings`, `TodoList`: the only code that reads or writes SavedVariables | utils |
| 5 | `config/interfaceOptions.*` | `InterfaceOptions`: the Blizzard options panel | Settings, then later layers late-bound |
| 6 | `components/` | `ResponsiveFrame` (movable/resizable/scalable template), `TodoChecklisterFrame` (main window controller) | model, utils |
| 7 | `modules/` | `Debug`, `Utils`, `MinimapIcon`, `Chat`: integrations with the game (slash commands, minimap, chat output) | components, model |
| 8 | `src/init.lua` | composition root: one `ADDON_LOADED` handler calls every `:Init()` | everything |

Each manifest lists `<Script file=...>` entries. A component's XML file loads its own `.lua` first, then declares templates. **A new Lua file does nothing until it is added to its folder's XML manifest.**

### Module pattern (service locator, not DI)

There are no `require`s and no constructor injection. Every file receives the addon's private namespace table through the vararg and uses it as a service registry:

```lua
---@class TodoAddon
local TodoAddon = select(2, ...)      -- shared private table, same for every file
local addonName = select(1, ...)      -- "TodoChecklister"
---@class Settings
local Settings = TodoAddon.Settings   -- "import": capture an earlier-loaded module at file scope

TodoAddon.Chat = {}                   -- "export": register this module
---@class Chat
local Chat = TodoAddon.Chat
```

Rules that follow from this:

- **File-scope imports only work for modules that loaded earlier.** A module that loads later is still `nil` when the file runs. To call into a later layer, look it up at call time instead: `TodoAddon.MinimapIcon:LoadCFG()`, `TodoAddon.Chat:Print(...)`. `interfaceOptions.lua` and `TodoChecklister.lua` do this. Don't "clean up" those calls into file-scope locals.
- Modules are singletons, plain tables of `:`-methods. Per-instance state lives on the module table (`TodoChecklisterFrame.selectedItem`, `.memoizationId`, `.frame`).
- `src/init.lua` is the only place that decides start-up order: Debug, Settings, TodoList, InterfaceOptions, TodoChecklisterFrame, Chat, MinimapIcon. Model `Init`s must run before any UI `Init` because they create the SavedVariables tables.
- Every file repeats `---@class TodoAddon` / `---@class X` annotations on these locals, which is the old EmmyLua style where repeated declarations merged. `duplicate-type` is disabled in `.emmyrc.json` for this. Keep the same header when adding a file.

### Lifecycle contract

UI-facing modules implement up to three methods:

- `Init()`: runs once at `ADDON_LOADED`. Creates frames from XML templates, registers events, hooks and slash commands, then calls `LoadCFG()`.
- `LoadCFG()`: idempotent. Re-reads `Settings` and applies the values to the UI. Call it after any setting changes; it is the "refresh" entry point.
- `Defaults()`: resets to defaults, then calls `LoadCFG()`.

When a setting changes, the flow fans out like this: XML handler (global function) → `Settings:SetX(value)` → `InterfaceOptions:LoadCFG()` → `TodoChecklisterFrame:LoadCFG()` → `TodoChecklisterFrame:OnUpdate()`. The Blizzard settings panel hooks in through `frame.OnRefresh = LoadCFG` and `frame.OnDefault = Defaults`.

### Responsibilities, and which entry point to call

- **`TodoList`** (`model/todoList.lua`) is the data layer over `TodoChecklisterDB` and `TodoChecklisterCharacterDB`. It has no knowledge of frames. Item functions (`AddItem`, `GetItems`, `Move`...) act on the list the current character has selected.
- **`Settings`** (`model/settings.lua`) is getter/setter pairs over `TodoChecklisterSettingsDB`. Nothing else touches that table directly.
- **`TodoChecklisterFrame`** (`components/TodoChecklister.lua`) is the controller and view for the main window. It owns UI state: `selectedItem` (an index; `0` means none) and `memoizationId`. Its mutators (`AddItem`, `RemoveItemWithIndex`, `Move`, `CheckItemWithIndex`, `SelectItem`, and for lists `SwitchList`, `CreateList`, `DeleteList`) call `TodoList`, keep the selection pointing at the same item across index shifts, bump `memoizationId`, and call `OnUpdate()`.
- **Other modules mutate the list through `TodoChecklisterFrame`, never through `TodoList` directly.** `Chat` and `MinimapIcon` follow this rule. Calling `TodoList` directly skips the selection fix-up and the repaint.
- **`Chat`** (`modules/chat.lua`): the `/todo` command table `Chat.commands` maps a lowercase verb to a function that receives the remaining space-split args. A nested table makes a sub-command. `Chat:Print` is the only chat output path and honors `Settings:ChatMuted()`.

### Rendering and memoization

- The list is a `WowScrollBoxList` (`frame.Background.ScrollBox`, nested so its clipped rows draw above the translucent backdrop) with a `WowTrimScrollBar` (`frame.ScrollBar`, hidden when nothing scrolls), set up in `InitScrollBox()`. Only visible rows exist; they are pooled `TodoItemTemplate` buttons. `OnUpdate()` hands `TodoList:GetItems()` to the ScrollBox as a new `CreateDataProvider(...)`, which re-runs `PaintItem(row, item, index)` on the visible rows only. Don't use `HybridScrollFrame`: both clients mark it deprecated.
- Drag and drop is Blizzard's `ScrollUtil.InitDefaultLinearDragBehavior`. `SetCursorFactory` paints the clone that follows the cursor (same row, with backdrop and locked highlight), `SetDropEnter` places a `DropIndicatorTemplate` line, and `SetPostDrop` applies the move to the saved list through `TodoChecklisterFrame:Move(from, to)`, where `to` is the final position.
- No script runs every frame while idle. The resize grip only sets `OnUpdate` while it is right-dragged to scale. Keep it that way.
- Linked-item counts (`|Hitem:...|r` links in the text, plus `GetItemCount`) are cached with `FunctionUtils:Memoize(fn, comparator, name)`. The cache key includes `self.memoizationId`, so **any change that affects row text must increment `memoizationId` before `OnUpdate()`**. `BAG_UPDATE_DELAYED`, scrolling and `LoadCFG` already increment it.
- Shift-clicking an item inserts its link into the input box through `hooksecurefunc("HandleModifiedItemClick", ...)` (and a hook on `StackSplitFrame:OpenStackSplitFrame` that closes the split frame while the input box has focus), installed when `TodoChecklister.lua` loads.

### UI: XML first

**Declare UI in XML, and use Lua only for what XML can't express.** This is how the existing code is split:

- **XML (`*.xml`):** virtual templates (`TodoItemTemplate`, `TodoChecklisterTemplate`, `TodoChecklisterResponsiveFrameTemplate`, `TodoChecklisterInterfaceOptionsTemplate`, `DropIndicatorTemplate`), layout, anchors, sizes, layers, fonts, textures, inheritance from Blizzard templates (`UIPanelDialogTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`, `WowScrollBoxList`, `WowTrimScrollBar`, `GameTooltipTemplate`), static text set in `<OnLoad>`, and `<Scripts>` handlers that delegate to Lua.
- **Lua:** instantiating templates (`CreateFrame(type, name, parent, "Template")` in `Init`), anything that depends on runtime data (row painting, titles with the player name, version text), event registration, scripts that need module closures (drag and drop, the close button override), and pooled or dynamic frames (ScrollBox views and data providers).
- Child frames are addressed with `parentKey` (`self.frame.TodoText`, `row.TodoCheckButton`, `self.frame.SettingsContainer.FanfareCheck`). Give every new child a `parentKey` and use that from Lua. Avoid `_G[...]` lookups by name; the only one in the code is `TodoChecklisterClose`, which comes from `UIPanelDialogTemplate`'s `$parentClose` and has no `parentKey`.

### Globals: what is global, why, and how to add one

Inline XML scripts can't see the private `TodoAddon` table, and the game resolves some things by global name. That is the only reason anything here is global. The current globals:

| Kind | Names | Defined in |
|---|---|---|
| SavedVariables (must match `.toc`) | Account-wide: `TodoChecklisterDB`, `TodoChecklisterSettingsDB`, `TodoChecklisterMapIcon`. Per character (`SavedVariablesPerCharacter`): `TodoChecklisterCharacterDB` | model `Init`s, `MinimapIcon:Init` |
| Keybinding (resolved by `bindings.xml`) | `BINDING_HEADER_TC_HEADER`, `BINDING_NAME_TC_TOGGLE_FRAME`, `GLOBAL_TodoChecklisterFrameToggle` | `src/init.lua` |
| Slash commands | `SLASH_TodoChecklister1` + `SlashCmdList.TodoChecklister`; debug only: `SLASH_RELOADUI1`, `SLASH_FRAMESTK1` | `chat.lua`, `debug.lua` |
| Named frames (XML `name=` / `CreateFrame` name) | `TodoChecklister` (the window frame, not the `TodoChecklisterFrame` module), `TodoChecklisterInterfaceOptions`, `TodoChecklisterMAINFRAME`, and `$parent...` children | XML, `Init`s |
| XML script handlers | `OnShow`, `OnSaveItem`, `OnRemoveItem`, `OnCheckItem`, `OnSelectItem`, `ToggleFocusSettings`, `TodoChecklister_OnFolderButtonClick` | bottom of `TodoChecklister.lua` |
| | `ShowKeepFocusClick`, `KeepFocusClick`, `OpacityValueChanged`, `OpacityOnHoverValueChanged`, `OnFanfarreCheck`, `DisplayLinkedCountClick`, `ToggleMapClick`, `MuteChatClick`, `DisplayBankClick`, `DisplayChargesClick` | bottom of `interfaceOptions.lua` |
| Misc | `printDBG` (debug print), `StaticPopupDialogs["TodoChecklisterWEBSITE"]` | `debug.lua`, `interfaceOptions.lua` |
| XML-referenced data | `TodoChecklister_BACKDROP` (the `backdropInfo` of `BackdropTemplate` frames) | `constants.lua` |

The XML handler globals have generic names (`OnLoad`, `OnUpdate`, `OnShow`) that any other addon can overwrite, and they are not namespaced. When adding UI behavior:

- Keep the handler a thin adapter. It sits in the "XML Events" section at the bottom of the component's Lua file and immediately calls a module method (`OnCheckItem(frame)` → `TodoChecklisterFrame:CheckItem(frame:GetParent().todoItem)`).
- XML template names (`name="..." virtual="true"`) share the same global namespace as Blizzard's. Before naming a template, grep both `vendor/retail` and `vendor/forever-export` for `name="ThatName"`; a clash breaks Blizzard's template or ours (this happened with `CollapseButtonTemplate`). Prefix new templates with `TodoChecklister`.
- Prefix any **new** global with `TodoChecklister_` (for example `TodoChecklister_OnClearClick`). Don't add more bare names. Renaming the existing ones is a separate refactor; rename the XML and the Lua together.
- If the logic needs module closures, set the script from Lua in `Init` with `SetScript` / `HookScript` instead of adding a global.
- Every new global must also go into `diagnostics.globals` in `.emmyrc.json` and `globals` in `.luacheckrc`.

Blizzard globals (`NORMAL_FONT_COLOR`, `SOUNDKIT`, `GameFont*`, `ScrollUtil`, `UIParent`) are used directly. When the retail annotations don't know one, which happens with Classic-era or removed APIs, add it to both allow-lists rather than declaring a stub.

### Recipes

**Add a setting:** add the `---@field` to the `TodoSettings` annotation and the getter/setter pair in `Settings`. Add the default in `Settings:Defaults` and a `nil`-check default in `Settings:Init`; the `nil`-check is how users upgrading from older versions get the new key. Then add the control (with a `parentKey`) to `TodoChecklisterInterfaceOptionsTemplate` in `interfaceOptions.xml`, add a handler that calls the setter and then `InterfaceOptions:LoadCFG()`, reflect the value in `InterfaceOptions:LoadCFG`, and apply it in the consuming module's `LoadCFG`.

**Add a chat command:** add a key to `Chat.commands` that calls a `TodoChecklisterFrame` method, and add a line to `commands.help`. `lists`/`switch` show the pattern for commands that take a multi-word argument (`strjoin(" ", ...)`).

**Add a module:** create the file with the standard header, add it to the correct folder manifest (its layer decides what it can import at file scope), and add its `:Init()` call to `TodoAddon:Init` in `src/init.lua`.

### Design notes

- Responsibilities are mostly split one per module. The exception is `TodoChecklisterFrame`, which combines controller, row rendering, drag and drop, and item-link parsing. New window features should go into a new component or module rather than growing that file.
- There are no seams for unit tests: modules reach SavedVariables and the game API directly through globals. Pure logic belongs in `utils/` and the model layer, which have no frame dependencies.

### Known quirks in existing code

- `TodoChecklisterDB` is account-wide: `{ lists = { [name] = TodoItem[] } }`, where `TodoItem` is `{ id, text, isChecked }`. Lists are keyed by name, so names are unique. Any character can view any list.
- Folders keep each list a flat array, so lists saved before folders load unchanged. A folder is an item with `isFolder` (and `isCollapsed`); the run of `inFolder` items right after it belongs to it. Folders can't nest or be checked. `TodoList:ResolveMove` decides where a drag lands, `GetVisibleItems` feeds the ScrollBox (so row indexes aren't saved indexes: compare items, not indexes), and `RepairFolders` in `Init` clears an `inFolder` with no folder above it.
- `TodoChecklisterCharacterDB` is per character: `{ selectedList = name }`. `TodoList:EnsureSelectedList()` falls back to `"<Name>'s List"` (and creates it) when the character never picked a list or its list was deleted. `<Name>` comes from `NameUtil.GetUnmodifiedUnitFullName("player")`: name plus surname on Forever, just the name elsewhere.
- Before lists, `TodoChecklisterDB` was a flat `TodoItem[]`. `TodoList:Init` migrates it into the first character's default list.

## Game version and API references

- The `.toc` says `## Interface: 120105, 50504, 20506, 11509, 16001`: one build for retail (Midnight 12.1.5), Mists of Pandaria Classic 5.5.4, TBC Classic Anniversary 2.5.6, Classic Era 1.15.9 and WoW: Forever 1.60.1. Every API and template used must exist in `vendor/retail`, `vendor/forever-export`, `vendor/classic` (Mists), `vendor/anniversary` (TBC) and `vendor/classic_era`; grep all five. The Classic trees ship files for every expansion: check the `[AllowLoadGameType ...]` / `_TBC.toc` / `_Mists.toc` manifests so the file you found actually loads on `vanilla`, `tbc` and `mists`. When one side lacks something, feature-detect (`NameUtil` only exists on Forever, so `TodoList:GetDefaultListName` falls back to `UnitName`; `OpenStackSplitFrame` is a `StackSplitFrame` method on retail/Forever but a global function on Classic, so the hook picks one). The release workflow builds one zip per flavor named the way Wago's GitHub release automation expects (`.zip` retail, `-mists`, `-bcc`, `-classic` = Classic Era, `-forever`) for GitHub, CurseForge and Wago (direct upload; Wago's GitHub import stays off to avoid duplicates). WoWInterface gets two combined zips: retail + Forever to page 25349, Mists + TBC + Era to 25348. The addon was written for Classic 1.13.2 (`11302`) and ported to Forever: removed globals were replaced with their namespaced versions (`C_Item.GetItemInfo`, `C_Item.GetItemCount`, `C_AddOns.GetAddOnMetadata`, `C_AddOns.LoadAddOn`), the options panel registers through `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory` with `OnDefault`/`OnRefresh` on the frame, and XML `<Backdrop>` was replaced by `inherits="BackdropTemplate"` + a `backdropInfo` KeyValue. Don't reintroduce un-namespaced APIs; grep the Forever export first.
- The addon's `Settings` and `Constants` modules shadow Blizzard's global `Settings` and `Constants` tables. Reach the Blizzard ones through `_G` (`interfaceOptions.lua` captures `BlizzardSettings = _G.Settings`; `debug.lua` reads `_G.Constants.ChatFrameConstants`).
- Don't use anything defined in `Blizzard_Deprecated*` addons or `Blizzard_FrameXML/DeprecatedTemplates.*`. Those files show the replacement (e.g. `OptionsSliderTemplate` = `UISliderTemplateWithLabels` + `<Size x="144" y="17"/>`).
- WoW: Forever runs on the **retail client**, not the Classic client, despite its 1.60 version number. Its UI code is closest to `vendor/retail`. Blizzard's tocs load `[Family]` = Mainline files plus `[Game]` = `Camelot/` overrides (`AllowLoadGameType camelot`), so check both folders in the export.
- `vendor/<flavor>/` holds Blizzard's FrameXML/UI source per flavor, from Gethe/wow-ui-source. `vendor/forever-export/` is the client's own `ExportInterfaceFiles code|art` output. The art folder is about 10G, so don't search it broadly. Before using an API or template, grep `vendor/` to see how Blizzard's own code uses it on the target flavor.
- `.annotations/wow-api` holds Ketho's WoW API type annotations, which the language server uses. They describe retail.

## Release

Packaging uses the CurseForge/WowAce packager via `pkgmeta.yaml`. `src/libs/LibStub` and `src/libs/LibDBIcon-1.0` are externals that the packager re-fetches. Bump `## Version` in the `.toc` for releases; the options panel shows it through `GetAddOnMetadata`.

## Commit messages

Use the [gitmoji](https://gitmoji.dev) shortcode style the history follows: `:<shortcode>: [#<issue>: ]<Past-tense sentence>`. Write one line, starting with a capitalized past-tense verb, with no period and no conventional-commit `type(scope):` prefix. Reference the GitHub issue number after the emoji when there is one. Commit directly on `master`.

```
:sparkles: #15: Added item linking!
:bug: Fixed a bug where options would not get saved
:zap: #33: Improved performance when get linked info by memoizing its result
:bookmark: Version 1.2.2
```

Shortcodes in use: `:sparkles:` (feature), `:bug:` (fix), `:bookmark:` (version release, message is just `Version x.y.z`), `:art:` (structure/refactor), `:recycle:` (refactor), `:zap:` (performance), `:pencil:` (docs), `:wrench:` (tooling/config), `:ambulance:` (hotfix), `:fire:` (removal), `:tada:` (milestone), `:rocket:` (deploy/release-adjacent). Use shortcodes, not literal emoji characters.

## References

Always check documentation when implementing and working. Read official apis and reference urls and crawl other links they also refer to. Prefer checking `vendor/` source first, then the wikis:

- [World of Warcraft API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) (also on [Wowpedia](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API))
- [Widget API](https://warcraft.wiki.gg/wiki/Widget_API) (also on [Wowpedia](https://wowpedia.fandom.com/wiki/Widget_API)): frame/region/FontString methods
- [wowprogramming.com docs](https://wowprogramming.com/docs.html): older API docs, still useful for concepts
- [Viewing Blizzard's interface code](https://warcraft.wiki.gg/wiki/Viewing_Blizzard%27s_interface_code) and [Extracting WoW user interface files](https://wowwiki-archive.fandom.com/wiki/Extracting_WoW_user_interface_files): launch the client with `-console`, then at the login screen press `` ` `` and run `ExportInterfaceFiles code` / `ExportInterfaceFiles art`. The Fandom archive returns HTTP 402 to automated fetches.
- [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source): Blizzard UI source per flavor branch (`live`, `classic`, `classic_era`, `classic_anniversary`, `forever`), the source of `vendor/`
- [Ketho/vscode-wow-api](https://github.com/Ketho/vscode-wow-api): the API annotations in `.annotations/`
- [EmmyLua Analyzer Rust](https://github.com/EmmyLuaLs/emmylua-analyzer-rust): `emmylua_ls` / `emmylua_check`, config schema for `.emmyrc.json`
- [WoWInterface forums](https://www.wowinterface.com/forums): addon author community, useful for undocumented behavior
