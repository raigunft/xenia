#include "endian.hlsli"
#include "pixel_formats.hlsli"
#include "resolve.hlsli"

RWBuffer<uint4> xe_resolve_dest : register(u0);
ByteAddressBuffer xe_resolve_source : register(t0);

[numthreads(8, 8, 1)]
void main(uint3 xe_thread_id : SV_DispatchThreadID) {
  // 1 thread = 4 pixels.
  uint2 pixel_index = xe_thread_id.xy << uint2(2u, 0u);
  // Group height is the same as resolve granularity, Y overflow check not
  // needed.
  [branch] if (pixel_index.x >= XeResolveSize().x) {
    return;
  }
  float4 pixel_0, pixel_1, pixel_2, pixel_3;
  XeResolveLoad4RGBAColorsX1(
      xe_resolve_source, XeResolveColorCopySourcePixelAddressInts(pixel_index),
      pixel_0, pixel_1, pixel_2, pixel_3);
  uint4 packed_01, packed_23;
  XePack64bpp4Pixels(pixel_0, pixel_1, pixel_2, pixel_3, XeResolveDestFormat(),
                     packed_01, packed_23);
  uint endian = XeResolveDestEndian128();
  uint dest_address = XeResolveDestPixelAddress(pixel_index, 3u) >> 4u;
  xe_resolve_dest[dest_address] = XeEndianSwap64(packed_01, endian);
  // Odd 2 pixels = even 2 pixels + 32 bytes when tiled.
  xe_resolve_dest[dest_address + 2u] = XeEndianSwap64(packed_23, endian);
}
