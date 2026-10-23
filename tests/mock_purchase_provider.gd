extends "res://scripts/purchase_provider.gd"
# Tests directory is excluded from every playable export. Never persisted into a real wardrobe.
var state="completed"
var ledger: Dictionary={}
func purchase(product: String) -> Dictionary:
	if product!=PRODUCT:return {"state":"failed","verified":false,"test_only":true}
	if state=="completed":ledger[product]="test-entitlement"
	if state=="revoked":ledger.erase(product)
	return {"state":state,"verified":false,"test_only":true}
func restore() -> Dictionary:
	return {"state":"completed","entitlements":ledger.keys(),"test_only":true}
