// import { Maybe, Just, Nothing } from 'purify-ts/Maybe'

const API_BASE_URL = "https://open-vsx.org/api/"

export const getExtensionsCount = async (): Promise<number> => {
	const response = await fetch(`${API_BASE_URL}-/search?size=1`)
	if (response.status !== 200)
		throw `getExtensionsCount(): response.status === ${response.status}`
	return (await response.json()).totalSize
}

// universal: https://open-vsx.org/api/zjffun/snippetsmanager?size=1
export const getExtensionURLs = async (count: number): Promise<string[]> => {
	const response = await fetch(`${API_BASE_URL}-/search?includeAllVersions=false&size=${count}&target=universal`)
	if (response.status !== 200) {
		throw `getExtensionsList(): response.status === ${response.status}`
	}
	return (await response.json()).extensions.map((e: any) => e.url)
}

export const getExtensionData = async (url: string): Promise<any> => {
	const response = await fetch(url)
	if (response.status !== 200) {
		console.log(`getExtensionData(${url}): response.status === ${response.status}`)
		return null
	}
	return await response.json()
}

export const getExtensionsData = async () => {
	const count = await getExtensionsCount()
	const urls = await getExtensionURLs(count)

	let urls_ = new Array<Promise<any>>(urls.length)
	for (let i = 0; i < urls.length; i++) {
		urls_[i] = getExtensionData(urls[i])
		await new Promise(f => setTimeout(f, 40));
	}

	return {
		count, data: await Promise.all(urls_.filter(x => x !== null))
	}
}
