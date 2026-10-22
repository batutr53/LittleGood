class_name Biomes
extends RefCounted

const NAMES = ["Grassland", "Forest", "Desert", "Mountains", "Snowlands", "Wetlands", "Water"]
const TURKISH = ["Çayır", "Orman", "Çöl", "Dağlar", "Karlı diyar", "Sulak alan", "Su"]
const COLORS = [Color("83b889"), Color("408b73"), Color("dcb782"), Color("9ca9aa"), Color("d1e4db"), Color("74aaa0"), Color("479cab")]
const GROWTH = [0.025, 0.04, 0.008, 0.007, 0.006, 0.035, 0.0]

static func title(b: int, lang: String) -> String:
	return TURKISH[b] if lang == "tr" else NAMES[b]
