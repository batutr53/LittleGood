shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0, 0.82, 0.36, 1.0);
uniform vec4 uv_bounds = vec4(0.0, 0.0, 1.0, 1.0);
uniform float thickness = 6.0;
varying vec4 sprite_tint;
void vertex() { sprite_tint = COLOR; }
uniform sampler2D selection_texture : filter_linear;
float alpha_at(vec2 uv) {
 if (uv.x < uv_bounds.x || uv.y < uv_bounds.y || uv.x > uv_bounds.z || uv.y > uv_bounds.w) { return 0.0; }
 return texture(selection_texture, uv).a;
}
void fragment() {
 vec4 base = texture(TEXTURE, UV);
 vec2 d = TEXTURE_PIXEL_SIZE * thickness;
 float edge = 1.0;
 edge = min(edge, alpha_at(UV + vec2(d.x, 0.0)));
 edge = min(edge, alpha_at(UV - vec2(d.x, 0.0)));
 edge = min(edge, alpha_at(UV + vec2(0.0, d.y)));
 edge = min(edge, alpha_at(UV - vec2(0.0, d.y)));
 edge = min(edge, alpha_at(UV + d * 0.707));
 edge = min(edge, alpha_at(UV - d * 0.707));
 edge = min(edge, alpha_at(UV + vec2(d.x, -d.y) * 0.707));
 edge = min(edge, alpha_at(UV + vec2(-d.x, d.y) * 0.707));
 float around = max(alpha_at(UV + vec2(d.x, 0.0)), alpha_at(UV - vec2(d.x, 0.0)));
 around = max(around, max(alpha_at(UV + vec2(0.0, d.y)), alpha_at(UV - vec2(0.0, d.y))));
 around = max(around, max(alpha_at(UV + d * 0.707), alpha_at(UV - d * 0.707)));
 around = max(around, max(alpha_at(UV + vec2(d.x,-d.y)*0.707), alpha_at(UV + vec2(-d.x,d.y)*0.707)));
 float border = clamp(base.a - edge, 0.0, 1.0);
 COLOR.rgb = mix(base.rgb * sprite_tint.rgb, outline_color.rgb, max(border * 0.96, 0.08));
 COLOR.a = max(base.a, around) * sprite_tint.a;
 if (base.a < 0.01 && around > 0.01) { COLOR = vec4(outline_color.rgb, around * outline_color.a * sprite_tint.a); }
}
