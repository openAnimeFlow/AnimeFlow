#version 300 es
// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org>

// Generated from assets/shaders/Anime4K_AutoDownscalePre_x2.glsl. Do not edit.
// Anime4K-v4.0-AutoDownscalePre-x2
precision highp float;
in vec2 vTexCoord;
out vec4 outColor;
uniform sampler2D u_HOOKED;
#define HOOKED_pos vTexCoord
#define HOOKED_size s_HOOKED
#define HOOKED_pt (vec2(1.0) / s_HOOKED)
#define HOOKED_tex(pos) texture(u_HOOKED, pos)
#define HOOKED_texOff(offset) texture(u_HOOKED, vTexCoord + (offset) / s_HOOKED)


vec4 hook() {
	return HOOKED_tex(HOOKED_pos);
}
void main() { outColor = hook(); }
