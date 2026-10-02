# Zybo HDMI Display Pipeline

This project generates a 1280×720, 60 Hz HDMI video signal on the Zybo Z7-10 using custom RTL. The design produces video timing, converts RGB pixels to TMDS symbols, serializes the symbols with the FPGA's OSERDESE2 resources, and drives the board's HDMI transmitter pins.

The initial test pattern was a bring-up source used to verify the pixel clock, raster timing, TMDS encoding, serialization, and monitor output. In the final implementation, the test-pattern generator is replaced as the pixel source by a display controller connected to a BRAM framebuffer. The controller reads the stored pixel for the current raster location and supplies RGB data to the same TMDS/HDMI output path.

## Video mode and clocks

The implemented mode is 1280×720 at 60 Hz:

| Parameter | Value |
|---|---:|
| Active resolution | 1280 × 720 pixels |
| Horizontal total | 1650 pixel clocks |
| Horizontal front porch / sync / back porch | 110 / 40 / 220 pixel clocks |
| Vertical total | 750 lines |
| Vertical front porch / sync / back porch | 5 / 5 / 20 lines |
| Pixel clock | 74.25 MHz |
| TMDS clock lane | 74.25 MHz (pixel clock) |
| TMDS data bit rate | 742.5 Mb/s per lane (10 bits per pixel clock) |
| OSERDESE2 DDR clock | 371.25 MHz (5× pixel clock; two bits transferred per clock cycle) |

A Clocking Wizard generates the pixel and OSERDESE2 clocks from the Zybo's 125 MHz system clock. Each TMDS data channel emits a 10-bit symbol per pixel clock, giving a serial bit rate of 10× the pixel clock. With DDR serialization, OSERDESE2 transfers two bits on each high-speed clock cycle, so its clock is 5× the pixel clock. Keep the timing counters and pixel updates in the pixel-clock domain; OSERDESE2 handles serialization using the high-speed clock and its divided clock input.

## Signal path

1. **Clock generation** — Clocking Wizard derives the 74.25 MHz pixel clock and 371.25 MHz serializer clock.
2. **Raster timing** — Horizontal and vertical counters generate pixel coordinates, active-video/blanking, horizontal sync, and vertical sync for the 1650 × 750 total raster.
3. **Framebuffer scanout** — During active video, the display controller uses the current pixel location to read RGB data from BRAM. Outside active video, the video path supplies the required blanking/control behavior. An upstream writer or image-processing block populates the framebuffer.
4. **TMDS encoding** — Three channel encoders convert the red, green, and blue pixel bytes into 10-bit TMDS symbols. The blue channel also carries video control symbols during blanking. Each channel maintains its own running disparity.
5. **Serialization and output** — OSERDESE2 serializes each 10-bit data symbol across five DDR clock cycles; differential output buffers drive the Zybo HDMI TX clock and data lanes. The TMDS clock lane carries the pixel clock.

Conceptually, the final pixel path is:

`BRAM framebuffer → display controller → RGB → TMDS encoders → OSERDESE2 → HDMI TX pins`

The test-pattern generator was useful during initial hardware validation, but it is not the final image source. Replacing only that source leaves the already-working timing, TMDS encoding, and HDMI output stages in place.

## Framebuffer behavior

The framebuffer is the pixel store shared by the image producer and the display scanout logic. The producer writes pixel data to BRAM; the display controller reads pixels in raster order and presents them in sync with the timing generator. Keep framebuffer addressing consistent with the raster convention, typically row-major:

`address = y × image_width + x`

For RGB888 at 1280×720, a complete frame contains 921,600 pixels and uses 2,764,800 bytes of pixel data. The actual BRAM depth and pixel packing must match the implemented memory configuration. If BRAM stores a reduced-size image or a packed pixel format, the controller's address and unpacking logic must reflect that format.

For a single framebuffer, avoid writing locations while they are being scanned if the displayed image must remain stable. A later double-buffered design can write one buffer while displaying the other and switch buffers at a frame boundary such as vertical sync.

## Main RTL/IP responsibilities

- `video_timing.sv` — Raster counters, pixel coordinates, sync, and active-video timing.
- `tmds_encoder.sv` — RGB/control encoding into three 10-bit TMDS symbols.
- `hdmi_top.sv` — Top-level connection of timing, pixel source, encoders, serializers, and HDMI pins.
- Clocking Wizard IP — Pixel and high-speed serializer clocks.
- OSERDESE2 instances — DDR serialization of TMDS data and clock symbols.
- Display controller — BRAM read/address sequencing and alignment of returned pixels with raster timing.
- BRAM framebuffer — Stores the image pixels used for final scanout.

The exact source-file organization may differ if the controller or BRAM is packaged as an IP block or inferred from RTL.

## Board integration

Use the Zybo Z7-10 HDMI TX pins for the differential TMDS clock and three differential data lanes. The Vivado project must include the matching board pin constraints, clock constraints, generated Clocking Wizard configuration, and any required output-buffer/serializer primitives. Confirm that the serializer clock, pixel clock, reset release, and serializer load timing match the selected OSERDESE2 implementation.

