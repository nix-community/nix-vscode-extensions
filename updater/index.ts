import { log, toTOML } from "./deps.ts"
import { getEntries as getOpenVSXEntries } from "./open-vsx/index.ts"
import { getEntries as getVSCodeMarketplaceEntries } from "./vscode-marketplace/index.ts"

const mode = Deno.args[0]
const outFile = Deno.args[1]

class PerModeConfig {
	getEntries: any
	tomlandFix: any
}

class PerMode {
	"open-vsx": PerModeConfig
	"vscode-marketplace": PerModeConfig
}

const perMode: PerMode =  {
	"open-vsx": {
		getEntries: getOpenVSXEntries,
		tomlandFix: "openvsx"
	},
	"vscode-marketplace": {
		getEntries: getVSCodeMarketplaceEntries,
		tomlandFix: "vsmarketplace"
	}
}

const getPerMode_ = (mode: string): PerModeConfig => {
	if (mode == "open-vsx") return perMode["open-vsx"]
	else if (mode == "vscode-marketplace") return perMode["vscode-marketplace"]
	else throw "Invalid mode."
}

const perMode_ = getPerMode_(mode)

const entries = await perMode_.getEntries()

const extensions = Object.fromEntries(entries)

log.info("Generating TOML...")
const tomlandFixSrc = /^src = /gm
const tomlandFixFetch = /^fetch = /gm
const toml = toTOML(extensions)
	.replaceAll(tomlandFixSrc, `src.${perMode_.tomlandFix} = `)
	.replaceAll(tomlandFixFetch, `fetch.${perMode_.tomlandFix} = `)
log.info("Generated TOML.")
log.info("Applied tomland fixes.")

log.info(`Writing to ${outFile}...`)
await Deno.writeTextFile(outFile, toml)
log.info(`Wrote to ${outFile}.`)
