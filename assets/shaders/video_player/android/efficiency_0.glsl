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

// Generated from assets/shaders/media_kit/common/Anime4K_Clamp_Highlights.glsl. Do not edit.
// Anime4K-v4.0-De-Ring-Compute-Statistics
precision highp float;
in vec2 vTexCoord;
out vec4 outColor;
uniform sampler2D u_MAIN;
uniform vec2 s_MAIN;
#define MAIN_pos vTexCoord
#define MAIN_size s_MAIN
#define MAIN_pt (vec2(1.0) / s_MAIN)
#define MAIN_tex(pos) texture(u_MAIN, pos)
#define MAIN_texOff(offset) texture(u_MAIN, vTexCoord + (offset) / s_MAIN)


#define KERNELSIZE 5 //Kernel size, must be an positive odd integer.
#define KERNELHALFSIZE 2 //Half of the kernel size without remainder. Must be equal to trunc(KERNELSIZE/2).

float get_luma(vec4 rgba) {
	return dot(vec4(0.299, 0.587, 0.114, 0.0), rgba);
}

vec4 hook() {

	float gmax = 0.0;

	for (int i=0; i<KERNELSIZE; i++) {
		float g = get_luma(MAIN_texOff(vec2(i - KERNELHALFSIZE, 0)));

		gmax = max(g, gmax);
	}

	return vec4(gmax, 0.0, 0.0, 0.0);
}
void main() { outColor = hook(); }
