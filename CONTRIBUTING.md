# Contributing

TodoChecklister is plain Lua 5.1 and FrameXML that the game client loads directly. There is no build step and no test suite. You check a change with static analysis and by testing it in game. [CLAUDE.md](./CLAUDE.md) describes the architecture, load order and conventions in detail.

## Tooling

Editor tooling uses [EmmyLua Analyzer Rust](https://github.com/EmmyLuaLs/emmylua-analyzer-rust) (`emmylua_ls`) with [Ketho's WoW API annotations](https://github.com/Ketho/vscode-wow-api).

```sh
brew install emmylua_ls   # or: cargo install emmylua_ls
pnpm bootstrap            # fetches WoW API annotations + emmylua_check
pnpm check                # runs diagnostics from the CLI
pnpm vendor               # clones/updates Blizzard UI source into ./vendor (gitignored)
```

`pnpm check` exits non-zero on warnings that predate your change. Judge your change by whether it adds new diagnostics.

Config lives in `.emmyrc.json`. In VS Code, install the recommended `EmmyLua` extension (it bundles `emmylua_ls`). In Neovim, run `vim.lsp.enable("emmylua_ls")` through nvim-lspconfig.

## Supported clients

One codebase ships to five clients: Retail, Mists of Pandaria Classic, TBC Anniversary, Classic Era and WoW: Forever. Every API and template you use has to exist on all of them. Grep the matching `vendor/` folders before you use one, and feature-detect when a client lacks it.

`./vendor` holds read-only Blizzard UI source from [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), one folder per flavor: `retail` (live), `classic` (Mists), `anniversary` (TBC), `classic_era` and `forever` (WoW: Forever runs 1.60 content on the retail client and shares most UI code with `retail`). Update one with `pnpm vendor forever`.

`./vendor/<flavor>-export/` holds the client's own `ExportInterfaceFiles code|art` output. Launch the client with `-console`, press `` ` `` at the login screen and run the command. See [Viewing Blizzard's interface code](https://warcraft.wiki.gg/wiki/Viewing_Blizzard%27s_interface_code).

## Saved data

Never break people's saved lists. They can't be recovered, and players switch addon versions in both directions. Before changing anything that is saved, read the rules in "User data safety" in [CLAUDE.md](./CLAUDE.md) and at the top of `src/utils/migrationUtils.lua`. In short:

- Add fields; never rename or remove them.
- A change that can't be additive gets a new format version with an upgrade step.
- Never edit an upgrade step that has shipped.
- Test against the saved files of older releases.

## Testing in game

Put the repository (or a symlink to it) at `Interface/AddOns/TodoChecklister` inside your client folder, then type `/reload` in game after each change.

## Releasing

Bump `## Version` in `TodoChecklister.toc`, commit and push to `master`. The release workflow tags the version, builds one zip per client and uploads them to CurseForge, Wago, WoWInterface and GitHub. See `.github/workflows/release.yml`.

Commit messages follow [gitmoji](https://gitmoji.dev): `:sparkles: #15: Added item linking`.

## References

- [World of Warcraft API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) ([Wowpedia mirror](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API))
- [Widget API](https://warcraft.wiki.gg/wiki/Widget_API) ([Wowpedia mirror](https://wowpedia.fandom.com/wiki/Widget_API))
- [wowprogramming.com docs](https://wowprogramming.com/docs.html), older but still useful for concepts
- [World of Warcraft Programming: A Guide and Reference for Creating WoW Addons](http://garde.sylvanas.free.fr/ressources/Guides/Macros-Addons/Wiley-World.of.Warcraft.Programming.A.Guide.and.Reference.for.Creating.WoW.Addons.pdf) (book, PDF)
- [Extracting WoW user interface files](https://wowwiki-archive.fandom.com/wiki/Extracting_WoW_user_interface_files) (archive)
- [WoWInterface forums](https://www.wowinterface.com/forums)
