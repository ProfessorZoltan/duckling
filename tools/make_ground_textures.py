#!/usr/bin/env python3
"""Regenerate the Home Pond ground textures in game/assets/textures/.

Everything here is procedural and seamless: the noise is built in the Fourier
domain of a square grid, so it wraps by construction and a 2.6 m tile repeat
never shows a seam. Run it from anywhere:

    python3 tools/make_ground_textures.py

Needs numpy only; the PNGs are written by hand so there is no Pillow dependency.
"""

import os
import struct
import zlib

import numpy as np

SIZE = 512
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "textures")


def noise(rng, low, high, size=SIZE):
	"""Band-limited tileable noise in 0..1.

	White noise filtered to the [low, high] cycles-per-tile band. Because the
	filter is applied to the periodic DFT of the tile, the result wraps exactly.
	"""
	white = rng.standard_normal((size, size))
	fx = np.fft.fftfreq(size) * size
	radius = np.hypot(*np.meshgrid(fx, fx, indexing="ij"))
	band = np.exp(-((radius - (low + high) * 0.5) ** 2) / (2.0 * ((high - low) * 0.4 + 1e-6) ** 2))
	band[0, 0] = 0.0
	field = np.real(np.fft.ifft2(np.fft.fft2(white) * band))
	field -= field.min()
	return field / max(field.max(), 1e-6)


def fbm(rng, octaves, size=SIZE):
	"""Sum of tileable noise bands, each half the wavelength and amplitude."""
	total = np.zeros((size, size))
	weight = 0.0
	for i, (low, high, amplitude) in enumerate(octaves):
		total += noise(rng, low, high, size) * amplitude
		weight += amplitude
	total /= weight
	total -= total.min()
	return total / max(total.max(), 1e-6)


def ramp(values, stops):
	"""Map a 0..1 field through colour stops [(position, (r, g, b)), ...]."""
	positions = np.array([s[0] for s in stops])
	colours = np.array([s[1] for s in stops], dtype=float)
	out = np.empty(values.shape + (3,))
	for channel in range(3):
		out[..., channel] = np.interp(values, positions, colours[:, channel])
	return out


def write_png(path, rgb):
	"""Write an 8-bit RGB PNG (filter type 0 on every row)."""
	data = np.clip(rgb * 255.0, 0, 255).astype(np.uint8)
	height, width, _ = data.shape
	raw = b"".join(b"\x00" + data[y].tobytes() for y in range(height))

	def chunk(tag, payload):
		return (struct.pack(">I", len(payload)) + tag + payload
			+ struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

	png = (b"\x89PNG\r\n\x1a\n"
		+ chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
		+ chunk(b"IDAT", zlib.compress(raw, 9))
		+ chunk(b"IEND", b""))
	with open(path, "wb") as handle:
		handle.write(png)
	print("wrote", os.path.relpath(path))


def main():
	os.makedirs(OUT, exist_ok=True)
	rng = np.random.default_rng(20260911)

	# Grass: fine blades over a slow patchiness, kept deep enough that the sun
	# does not wash it out to mint.
	blades = fbm(rng, [(70, 150, 1.0), (140, 240, 0.5), (24, 48, 0.35)])
	patches = noise(rng, 4, 9)
	grass = ramp(blades, [
		(0.00, (0.129, 0.216, 0.098)),
		(0.35, (0.196, 0.310, 0.129)),
		(0.62, (0.271, 0.396, 0.161)),
		(0.82, (0.357, 0.463, 0.196)),
		(1.00, (0.451, 0.529, 0.247)),
	])
	# Slow olive/emerald drift so a 2.6 m repeat reads as a field, not wallpaper.
	grass *= (0.86 + 0.28 * patches)[..., None]
	grass[..., 0] *= 0.96 + 0.10 * patches
	grass[..., 2] *= 0.92 + 0.18 * (1.0 - patches)
	write_png(os.path.join(OUT, "ground_grass.png"), grass)

	# Wet sand: the shoreline ring. Coarser grain, a touch of shell-fleck.
	grain = fbm(rng, [(90, 190, 1.0), (30, 70, 0.6), (8, 16, 0.3)])
	sand = ramp(grain, [
		(0.00, (0.325, 0.271, 0.196)),
		(0.40, (0.424, 0.357, 0.255)),
		(0.72, (0.518, 0.443, 0.322)),
		(1.00, (0.596, 0.522, 0.396)),
	])
	fleck = noise(rng, 150, 250)
	sand += ((fleck > 0.82) * 0.06)[..., None]
	write_png(os.path.join(OUT, "ground_sand.png"), sand)

	# Pond bed: dark silt with a green-brown cast so it reads as underwater.
	silt = fbm(rng, [(20, 45, 1.0), (60, 120, 0.45), (6, 12, 0.5)])
	mud = ramp(silt, [
		(0.00, (0.133, 0.114, 0.086)),
		(0.45, (0.208, 0.184, 0.129)),
		(0.78, (0.286, 0.259, 0.176)),
		(1.00, (0.353, 0.322, 0.216)),
	])
	write_png(os.path.join(OUT, "ground_mud.png"), mud)

	# Shared normal map, from a height field with the same grain as the albedos.
	height = fbm(rng, [(28, 60, 1.0), (70, 140, 0.55), (140, 240, 0.3)])
	dx = np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)
	dy = np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)
	strength = 6.0
	nx, ny, nz = -dx * strength, -dy * strength, np.ones_like(height)
	length = np.sqrt(nx * nx + ny * ny + nz * nz)
	normal = np.stack([nx / length, ny / length, nz / length], axis=-1) * 0.5 + 0.5
	write_png(os.path.join(OUT, "ground_normal.png"), normal)

	# Blend mask: very low frequency, used to wobble the mud/sand/grass joins so
	# the shoreline is not a drawn circle. One tile covers the whole 80 m plain.
	blend = fbm(rng, [(2, 5, 1.0), (5, 11, 0.5), (11, 22, 0.25)])
	write_png(os.path.join(OUT, "ground_blend.png"), np.repeat(blend[..., None], 3, axis=2))


if __name__ == "__main__":
	main()
