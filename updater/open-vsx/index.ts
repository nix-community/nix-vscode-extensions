import { log, toTOML } from "../deps.ts"

import * as nixUtils from "../utils/nix.ts"
import * as openVSXAPI from "./api.ts"

export async function main(outFile: string) {
	log.info("Fetching data from OpenVSX API...")
	const { count, data } = await openVSXAPI.getExtensionsData()
	log.info("Fetched data from OpenVSX API.")
	log.info(`${count} extensions found.`)

	log.info("Generating entries...")
	const entries = data.map(e => ({
		name: e.name,
		publisher: e.namespace,
		passthru: {
			name: nixUtils.toValidNixIdentifier(e.name),
			publisher: nixUtils.toValidNixIdentifier(e.namespace),
			marketplaceName: e.name,
			marketplacePublisher: e.namespace,
			license: nixUtils.toNixpkgsLicense(e.license),
			description: e.description,
			changelog: e.files.changelog,
			downloadPage: e.files.download,
			homepage: e.homepage
		}
	})).map(e => [`${e.publisher}-${e.name}`, {
		src: `${e.publisher}.${e.name}`,
		fetch: `${e.publisher}.${e.name}`,
		passthru: e.passthru
	}])
	log.info("Generated entries.")

	const extensions = Object.fromEntries([entries[0], entries[1], entries[2]])

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
}
