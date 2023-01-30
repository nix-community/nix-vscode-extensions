import { log, toTOML, toYAML } from "./deps.ts"
import { getEntries as getOpenVSXEntries } from "./open-vsx/index.ts"
import { getEntries as getVSCodeMarketplaceEntries } from "./vscode-marketplace/index.ts"

const mode = Deno.args[0]
const outFile = Deno.args[1]

class PerModeConfig {
	getEntries: any
}

class PerMode {
	"open-vsx": PerModeConfig
	"vscode-marketplace": PerModeConfig
}

const perMode: PerMode = {
	"open-vsx": {
		getEntries: getOpenVSXEntries,
	},
	"vscode-marketplace": {
		getEntries: getVSCodeMarketplaceEntries,
	}
}

const getPerMode_ = (mode: string): PerModeConfig => {
	if (mode == "open-vsx") return perMode["open-vsx"]
	else if (mode == "vscode-marketplace") return perMode["vscode-marketplace"]
	else throw "Invalid mode."
}

const perMode_ = getPerMode_(mode)

const entries = await perMode_.getEntries()

const extensions = entries

log.info("Generating YAML...")
const yaml = toYAML(extensions)
log.info("Generated YAML.")

log.info(`Writing to ${outFile}...`)
await Deno.mkdir("data/new", { recursive: true })
await Deno.writeTextFile(outFile, yaml)
log.info(`Wrote to ${outFile}.`)
