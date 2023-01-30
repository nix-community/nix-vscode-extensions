import { log } from "../deps.ts"
import * as nixUtils from "../utils/nix.ts"
import * as vscodeMarketplaceAPI from "./api.ts"

export async function getEntries() {
	log.info("Fetching data from VSCode Marketplace API...")
	const { count, data } = await vscodeMarketplaceAPI.getExtensionsData()
	log.info("Fetched data from VSCode Marketplace API.")
	log.info(`${count} extensions found.`)
	log.info("Generating entries...")
	const entries = data
		.filter(x => x !== null)
		.map(e => ({
			name: nixUtils.toValidNixIdentifier(e.extensionName),
			publisher: nixUtils.toValidNixIdentifier(e.publisher.publisherName),
			lastUpdated: e.lastUpdated
		})).sort((e1, e2) => {
			if (`${e1.name}-${e1.publisher}` < `${e2.name}-${e2.publisher}`) {
				return -1
			} else {
				return 1
			}
		})

	log.info("Generated entries.")

	return entries
}
