extends RefCounted
const SHADER=preload("res://assets/selection_outline.gdshader")
static func set_selected(sprite,selected,color=Color("ffda79")):
	if not is_instance_valid(sprite):return
	if selected:
		if not sprite.has_meta("selection_original_material"):
			sprite.set_meta("selection_original_material",{"material":sprite.material});var material=ShaderMaterial.new();material.shader=SHADER;sprite.material=material
			var bounds=Vector4(0,0,1,1)
			if sprite.texture is AtlasTexture:
				var t=sprite.texture;var size=t.atlas.get_size();bounds=Vector4(t.region.position.x/size.x,t.region.position.y/size.y,t.region.end.x/size.x,t.region.end.y/size.y)
			sprite.material.set_shader_parameter("selection_texture",sprite.texture.atlas if sprite.texture is AtlasTexture else sprite.texture)
			sprite.material.set_shader_parameter("uv_bounds",bounds);sprite.material.set_shader_parameter("thickness",clampf(3.0/maxf(.01,absf(sprite.scale.x)),2,14))
		sprite.material.set_shader_parameter("outline_color",color)
	elif sprite.has_meta("selection_original_material"):
		sprite.material=sprite.get_meta("selection_original_material").material;sprite.remove_meta("selection_original_material")
static func hit(sprite,screen):
	if not is_instance_valid(sprite) or not sprite.is_visible_in_tree():return false
	return sprite.is_pixel_opaque(sprite.get_global_transform_with_canvas().affine_inverse()*screen)
