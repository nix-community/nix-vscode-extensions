// import { Maybe, Just, Nothing } from 'purify-ts/Maybe'
import { selectVal } from "../utils/const.ts"

const API_BASE_URL = "https://open-vsx.org/api/"

const retryAfter = 1 * 1000
const retryN = 5

async function responseRetry(url: string, errorMsg: String): Promise<Response> {
	var response = await fetch(url)
	for (var i = 0; i < retryN && response.status != 200; i++) {
		const resp = await fetch(url)
		if (resp.status == 200) {
			response = resp
			break
		} else if (i == retryN - 1) {
			throw `${errorMsg} ${resp.status}`
		}
		console.log(`${errorMsg} ${resp.status}`)
		console.log("Retrying")
		await new Promise(f => setTimeout(f, retryAfter));
	}
	return response
}

export const getExtensionsCount = async (): Promise<number> => {
	const response = await responseRetry(
		`${API_BASE_URL}-/search?size=1`,
		"Couldn't get the extension count. Response status:"
	)
	return (await response.json()).totalSize
}

// TODO include for different platforms
// universal: https://open-vsx.org/api/zjffun/snippetsmanager?size=1

export const getExtensionsData = async () => {
	const count = selectVal(10, await getExtensionsCount())
	const response = await responseRetry(
		`${API_BASE_URL}-/search?includeAllVersions=false&size=${count}&targetPlatform=universal`,
		`Could not get the extensions data. Response status:`
	)
	const data = (await response.json()).extensions

	return {
		count, data
	}
}
