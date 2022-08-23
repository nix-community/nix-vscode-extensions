import { log, toTOML } from "./deps.ts"
import { getEntries as getOpenVSXEntries } from "./open-vsx/index.ts"
import { getEntries as getVSCodeMarketplaceEntries } from "./vscode-marketplace/index.ts"

const mode = Deno.args[0]
const outFile = Deno.args[1]

const perMode = {
	["open-vsx"]: {
		getEntries: getOpenVSXEntries,
		tomlandFix: "openvsx"
	},
	["vscode-marketplace"]: {
		getEntries: getVSCodeMarketplaceEntries,
		tomlandFix: "vsmarketplace"
	}
}

if (!perMode.hasOwnProperty(mode))
	throw "Invalid mode."

const entries = await perMode[mode].getEntries()

const extensions = Object.fromEntries(entries)

log.info("Generating TOML...")
const tomlandFixSrc = /^src = /gm
const tomlandFixFetch = /^fetch = /gm
const toml = toTOML(extensions)
	.replaceAll(tomlandFixSrc, `src.${perMode[mode].tomlandFix} = `)
	.replaceAll(tomlandFixFetch, `fetch.${perMode[mode].tomlandFix} = `)
log.info("Generated TOML.")
log.info("Applied tomland fixes.")

log.info(`Writing to ${outFile}...`)
await Deno.writeTextFile(outFile, toml)
log.info(`Wrote to ${outFile}.`)
