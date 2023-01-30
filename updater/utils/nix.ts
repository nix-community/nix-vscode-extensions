export const isValidNixIdentifier = (str: string) => {
	const identifier = /^[A-Za-z_][A-za-z0-9-_]*$/g
	return identifier.test(str)
}

export const toValidNixIdentifier = (str: any) => {
	const invalidChars = /[^A-Za-z0-9-_]/g
	const invalidFirstChar = /^\d+$/g
	return str.toString().toLowerCase()
		.replaceAll(invalidChars, "")
		.replaceAll(invalidFirstChar, (match, digit, offset, string) => `_${match}`)
}

export const toNixpkgsLicense = (license: string) => {
	const nixpkgsLicenses = [{
		nixpkgsName: "mit",
		accepted: [
			"MIT",
			"MIT License",
			"(MIT)",
			"MIT OR GPL-2.0",
			"MIT OR Apache-2.0",
			"MIT License - full document in LICENSE.md",
			"MIT - see LICENSE file",
			"MIT OR 0BSD OR CC0-1.0 OR Unlicense",
			"(MIT OR Apache-2.0)",
			"(MIT AND 996ICU)",
			"We use the “Commons Clause” License Condition v1.0 with the MIT License."
		]
	}, {
		nixpkgsName: "epl10",
		accepted: ["EPL-1.0", "EPL-1"]
	}, {
		nixpkgsName: "epl20",
		accepted: ["EPL-2.0", "EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0"]
	}, {
		nixpkgsName: "gpl2Only",
		accepted: ["GPL-2.0-only", "GPLv2", "GPL-2.0"]
	}, {
		nixpkgsName: "gpl2Plus",
		accepted: ["GPL-2.0-or-later", "GPL-2-later"]
	}, {
		nixpkgsName: "gpl3Only",
		accepted: [
			"GPL-3.0-only",
			"GPL-3.0",
			"GPLv3",
			"GPL-3.0 License",
			"GNU General Public License v3.0"
		]
	}, {
		nixpkgsName: "gpl3Plus",
		accepted: ["GPL-3.0-or-later", "GPL-3.0+"]
	}, {
		nixpkgsName: "unlicense",
		accepted: ["Unlicense"]
	}, {
		nixpkgsName: "agpl3Only",
		accepted: ["AGPL-3.0-only", "AGPL-3.0"]
	}, {
		nixpkgsName: "agpl3Plus",
		accepted: ["AGPL-3.0-or-later"]
	}, {
		nixpkgsName: "bsd0",
		accepted: ["0BSD"]
	}, {
		nixpkgsName: "bsd2",
		accepted: ["BSD-2-Clause"]
	}, {
		nixpkgsName: "bsd3",
		accepted: ["BSD-3-Clause", "BSD3"]
	}, {
		nixpkgsName: "wtfpl",
		accepted: ["WTFPL"]
	}, {
		nixpkgsName: "asl20",
		accepted: ["Apache-2.0", "Apache 2.0", "Apache", "Apache License Version 2.0"]
	}, {
		nixpkgsName: "mpl20",
		accepted: ["MPL-2.0", "MPL-2.0 AND Apache-2.0", "MLP-2.0 AND Apache-2.0"]
	}, {
		nixpkgsName: "lgpl3Only",
		accepted: ["LGPL-3.0-only", "LGPL-3.0"]
	}, {
		nixpkgsName: "cc0",
		accepted: ["CC0-1.0"]
	}, {
		nixpkgsName: "isc",
		accepted: ["ISC"]
	}, {
		nixpkgsName: "publicDomain",
		accepted: ["public domain"]
	}, {
		nixpkgsName: "osl3",
		accepted: ["OSL-3.0"]
	}, {
		nixpkgsName: "ncsa",
		accepted: ["NCSA"]
	}, {
		nixpkgsName: "cc-by-nc-30",
		accepted: ["CC-BY-NC-3.0"]
	}]

	return nixpkgsLicenses.find(l => l.accepted.includes(license))?.nixpkgsName || "unfree"
}
