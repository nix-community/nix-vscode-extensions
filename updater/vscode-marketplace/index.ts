import { log } from "../deps.ts"
import * as nixUtils from "../utils/nix.ts"
import * as vscodeMarketplaceAPI from "./api.ts"

export async function getEntries() {
	log.info("Fetching data from VSCode Marketplace API...")
	const { count, data } = await vscodeMarketplaceAPI.getExtensionsData()
	log.info("Fetched data from VSCode Marketplace API.")
	log.info(`${count} extensions found.`)

	log.info("Generating entries...")
	const entries = data.map(e => ({
		name: e.extensionName,
		publisher: e.publisher.publisherName,
		passthru: {
			name: nixUtils.toValidNixIdentifier(e.extensionName),
			publisher: nixUtils.toValidNixIdentifier(e.publisher.publisherName),
			marketplaceName: e.extensionName,
			marketplacePublisher: e.publisher.publisherName,
		}
	})).map(e => [`${e.publisher}-${e.name}`, {
		src: `${e.publisher}.${e.name}`,
		fetch: `${e.publisher}.${e.name}`,
		passthru: e.passthru
	}])
	log.info("Generated entries.")

	return entries
}
