import { main as updateOpenVSXExtensions } from "./open-vsx/index.ts"

const mode = Deno.args[0]
const outFile = Deno.args[1]

if (mode === "open-vsx") updateOpenVSXExtensions(outFile)
