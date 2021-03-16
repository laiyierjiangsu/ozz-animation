//----------------------------------------------------------------------------//
//                                                                            //
// ozz-animation is hosted at http://github.com/guillaumeblanc/ozz-animation  //
// and distributed under the MIT License (MIT).                               //
//                                                                            //
// Copyright (c) Guillaume Blanc                                              //
//                                                                            //
// Permission is hereby granted, free of charge, to any person obtaining a    //
// copy of this software and associated documentation files (the "Software"), //
// to deal in the Software without restriction, including without limitation  //
// the rights to use, copy, modify, merge, publish, distribute, sublicense,   //
// and/or sell copies of the Software, and to permit persons to whom the      //
// Software is furnished to do so, subject to the following conditions:       //
//                                                                            //
// The above copyright notice and this permission notice shall be included in //
// all copies or substantial portions of the Software.                        //
//                                                                            //
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR //
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   //
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    //
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER //
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    //
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        //
// DEALINGS IN THE SOFTWARE.                                                  //
//                                                                            //
//----------------------------------------------------------------------------//

#ifndef OZZ_ANIMATION_RUNTIME_ANIMATION_KEYFRAME_H_
#define OZZ_ANIMATION_RUNTIME_ANIMATION_KEYFRAME_H_

#include "ozz/base/platform.h"
#ifndef OZZ_INCLUDE_PRIVATE_HEADER
#error "This header is private, it cannot be included from public headers."
#endif  // OZZ_INCLUDE_PRIVATE_HEADER

namespace ozz {
namespace animation {

// Define animation key frame types (translation, rotation, scale). Every type
// as the same base made of the key time ratio and it's track index. This is
// required as key frames are not sorted per track, but sorted by ratio to favor
// cache coherency. Key frame values are compressed, according on their type.
// Decompression is efficient because it's done on SoA data and cached during
// sampling.

// Defines the float3 key frame type, used for translations and scales.
// Translation values are stored as half precision floats with 16 bits per
// component.
struct Float3Key {
  float ratio;
  uint16_t track;
  uint16_t value[3];
};
//四元数的压缩存储： https://blog.codingnow.com/2017/11/quaternion_compress.html
//如何形象地理解四元数？https://www.zhihu.com/question/23005815
//Understanding Quaternions 中文翻译《理解四元数》： https://www.qiujiawei.com/understanding-quaternions/
//定点数的定义：https://blog.csdn.net/jjj19891128/article/details/22945441
//在计算机发展过程中，我们使用的小数和实数曾经提出过很多种的表示方法。典型的比如相对于浮点数的定点数（Fixed Point Number）。
//在这种表达方式中，小数点固定的位于实数所有数字中间的某个位置。货币的表达就可以使用这种方式，比如 88.22 或者 22.88 可以用于
//表达具有四位精度（Precision），小数点后有两位的货币值。由于小数点位置固定，所以可以直接用四位数值来表达相应的数值。
    // Defines the rotation key frame type.
// Rotation value is a quaternion. Quaternion are normalized, which means each
// component is in range [0:1]. This property allows to quantize the 3
// components to 3 signed integer 16 bits values. The 4th component is restored
// at runtime, using the knowledge that |w| = sqrt(1 - (a^2 + b^2 + c^2)).
// The sign of this 4th component is stored using 1 bit taken from the track
// member.
//
// In more details, compression algorithm stores the 3 smallest components of
// the quaternion and restores the largest. The 3 smallest can be pre-multiplied
// by sqrt(2) to gain some precision indeed.
//
// Quantization could be reduced to 11-11-10 bits as often used for animation
// key frames, but in this case RotationKey structure would induce 16 bits of
// padding.
struct QuaternionKey {
  float ratio;
  uint16_t track : 13;   // The track this key frame belongs to.
  uint16_t largest : 2;  // The largest component of the quaternion.
  uint16_t sign : 1;     // The sign of the largest component. 1 for negative.
  int16_t value[3];      // The quantized value of the 3 smallest components.
};

}  // namespace animation
}  // namespace ozz
#endif  // OZZ_ANIMATION_RUNTIME_ANIMATION_KEYFRAME_H_
