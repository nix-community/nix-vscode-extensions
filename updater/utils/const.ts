export const TEST = false

export const selectVal = (testVal: any, prodVal: any) => { return TEST ? testVal : prodVal }
