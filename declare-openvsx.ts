import * as log from "https://deno.land/std@0.152.0/log/mod.ts"
import { stringify as toTOML } from "https://deno.land/std@0.152.0/encoding/toml.ts"

import * as nixUtils from "./nix-utils.ts"
import * as openVSX from "./open-vsx-api.ts"

const { count, data } = await openVSX.getExtensionsData()

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

const extensions = Object.fromEntries([entries[0], entries[1]])

const tomlandFixSrc = /^src = /gm
const tomlandFixFetch = /^fetch = /gm
const toml = toTOML(extensions)
	.replaceAll(tomlandFixSrc, "src.openvsx = ")
	.replaceAll(tomlandFixFetch, "fetch.openvsx = ")
await Deno.writeTextFile("./open-vsx-extensions.toml", toml)

// const licenses = extensionsData.map(e => e.license)
// console.log(licenses.map(l => nixUtils.toNixpkgsLicense(l)).filter(l => l == "unfree").length)

// const names = extensions.map(e => e.name)
// const namespaces = extensions.map(e => e.namespace)

// const invalidNames = names.filter(n => !nixUtils.isValidNixIdentifier(n))
// const fixedNames = invalidNames.map(n => nixUtils.toValidNixIdentifier(n))
// console.log(fixedNames.filter(n => names.includes(n)))

// const invalidNamespaces = namespaces.filter(n => !nixUtils.isValidNixIdentifier(n))
// const fixedNamespaces = invalidNamespaces.map(n => nixUtils.toValidNixIdentifier(n))
// console.log(fixedNamespaces.filter(n => namespaces.includes(n)))

// console.log(extensions.filter(e => !nixUtils.isValidNixIdentifier(e.name)).filter(e => extensions.some(a => a.name === nixUtils.toValidNixIdentifier(e.name))))
// console.log(extensions.filter(e => !nixUtils.isValidNixIdentifier(e.namespace)).filter(e => extensions.some(a => a.namespace === nixUtils.toValidNixIdentifier(e.namespace))))
