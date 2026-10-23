extends RefCounted
# Production default: no store plugin, credentials, SDK connection or live payment flow enabled.
const PRODUCT="org.littlegod.cosmetics.astral_heirloom.v1"
func products() -> Array:
	return [{"product":PRODUCT,"item":"royal_pack","available":false,"price_label":""}]
func purchase(_product: String) -> Dictionary:
	return {"state":"unavailable","verified":false,"test_only":false}
func restore() -> Dictionary:
	return {"state":"unavailable","entitlements":[],"test_only":false}
