import { selectVal } from "../utils/const.ts"

const API_BASE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery/"


const PAGE_COUNT = selectVal(1, 54)

// TODO use actual count

export const getExtensionsDataPage = async (pageNumber: number): Promise<any> => {
	const headers = {
		"CONTENT-TYPE": "application/json",
		"ACCEPT": "application/json; api-version=3.0-preview",
		"ACCEPT-ENCODING": "gzip"
	}
	const body = JSON.stringify({
		filters: [{
			criteria: [
				{ filterType: 8, value: "Microsoft.VisualStudio.Code" },
			],
			pageNumber,
			pageSize: selectVal(10, 1000),
			sortBy: 4,
			sortOrder: 2
		}],
		assetTypes: [],
		flags: 0
	})
	const response = await fetch(API_BASE_URL, { method: "POST", headers, body })

	if (response.status !== 200)
		throw `getExtensionsDataPage(): response.status === ${response.status}`

	return (await response.json()).results[0].extensions
}

export const getExtensionsData = async () => {
	const pages = [...Array(PAGE_COUNT).keys()].map(i => i + 1)
	const data = (await Promise.all(pages.map(pageNumber => getExtensionsDataPage(pageNumber))))
		.flat()
		.filter(e => ["validated, public", "validated, public, preview"].includes(e.flags))
	const count = data.length

	return { count, data }
}
