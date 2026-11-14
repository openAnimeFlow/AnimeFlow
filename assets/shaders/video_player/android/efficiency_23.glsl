#version 300 es
// MIT License

// Copyright (c) 2019-2021 bloc97
// All rights reserved.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Generated from assets/shaders/media_kit/common/Anime4K_Upscale_CNN_x2_M.glsl. Do not edit.
// Anime4K-v3.2-Upscale-CNN-x2-(M)-Depth-to-Space
precision highp float;
in vec2 vTexCoord;
out vec4 outColor;
uniform sampler2D u_conv2d_last_tf;
uniform vec2 s_conv2d_last_tf;
#define conv2d_last_tf_pos vTexCoord
#define conv2d_last_tf_size s_conv2d_last_tf
#define conv2d_last_tf_pt (vec2(1.0) / s_conv2d_last_tf)
#define conv2d_last_tf_tex(pos) texture(u_conv2d_last_tf, pos)
#define conv2d_last_tf_texOff(offset) texture(u_conv2d_last_tf, vTexCoord + (offset) / s_conv2d_last_tf)
uniform sampler2D u_MAIN;
#define MAIN_pos vTexCoord
#define MAIN_size s_MAIN
#define MAIN_pt (vec2(1.0) / s_MAIN)
#define MAIN_tex(pos) texture(u_MAIN, pos)
#define MAIN_texOff(offset) texture(u_MAIN, vTexCoord + (offset) / s_MAIN)

vec4 hook() {
    vec2 f0 = fract(conv2d_last_tf_pos * conv2d_last_tf_size);
    ivec2 i0 = ivec2(f0 * vec2(2.0));
    float c0 = conv2d_last_tf_tex((vec2(0.5) - f0) * conv2d_last_tf_pt + conv2d_last_tf_pos)[i0.y * 2 + i0.x];
    float c1 = c0;
    float c2 = c1;
    float c3 = c2;
    return vec4(c0, c1, c2, c3) + MAIN_tex(MAIN_pos);
}
void main() { outColor = hook(); }
