import { log } from "../deps.ts"
import * as nixUtils from "../utils/nix.ts"
import * as openVSXAPI from "./api.ts"

export async function getEntries() {
	log.info("Fetching data from OpenVSX API...")
	const { count, data } = await openVSXAPI.getExtensionsData()
	log.info("Fetched data from OpenVSX API.")
	log.info(`${count} extensions found.`)

	log.info("Generating entries...")
	const entries = data
		.filter(x => x !== null)
		.map(e => ({
			name: nixUtils.toValidNixIdentifier(e.name),
			publisher: nixUtils.toValidNixIdentifier(e.namespace),
			lastUpdated: e.timestamp
		}))
		.sort((e1, e2) => {
			if (`${e1.name}-${e1.publisher}` < `${e2.name}-${e2.publisher}`) {
				return -1
			} else {
				return 1
			}
		})
	log.info("Generated entries.")

	return entries
}