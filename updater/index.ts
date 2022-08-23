import { log, toTOML } from "./deps.ts"
import { getEntries as getOpenVSXEntries } from "./open-vsx/index.ts"
import { getEntries as getVSCodeMarketplaceEntries } from "./open-vsx/index.ts"

const mode = Deno.args[0]
const outFile = Deno.args[1]

const getEntries = {
	["open-vsx"]: getOpenVSXEntries,
	["vscode-marketplace"]: getVSCodeMarketplaceEntries
}

if (!getEntries.hasOwnProperty(mode))
	throw "Invalid mode."

const entries = await getEntries[mode]()

const extensions = Object.fromEntries(entries)

log.info("Generating TOML...")
const tomlandFixSrc = /^src = /gm
const tomlandFixFetch = /^fetch = /gm
const toml = toTOML(extensions)
	.replaceAll(tomlandFixSrc, "src.openvsx = ")
	.replaceAll(tomlandFixFetch, "fetch.openvsx = ")
log.info("Generated TOML.")
log.info("Applied tomland fixes.")

log.info(`Writing to ${outFile}...`)
await Deno.writeTextFile(outFile, toml)
log.info(`Wrote to ${outFile}.`)
