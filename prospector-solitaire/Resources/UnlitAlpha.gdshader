shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color : source_color;
uniform sampler2D texture_albedo;

void fragment() {
    vec4 tex = texture(texture_albedo, UV);
    ALBEDO = tex.rgb * color.rgb;
    ALPHA = tex.a * color.a;
}
