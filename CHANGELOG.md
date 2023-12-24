## 0.2.0
- [BREAKING] Renamed `toggle` to `trigger` in .animate() to better reflect its purpose.
- [BREAKING] Renamed `AnimatedEffect` to `EffectWidget` to better reflect its purpose.
- [BREAKING] Renamed `EffectAnimationValue` to `EffectQuery` to better reflect its purpose.
- [BREAKING] Replace `value` in `EffectQuery` with `linearValue` and `curvedValue` to allow more refined control over animations.
- [BREAKING] Renamed `PostFrameWidget` to `PostFrame`.
- Add new Rolling Text effect.
- Add new shake effect.
- Add new align effect.
- Update all effect extension functions to add more functionality of the `from` state.
- Add new extension functions that have default from states like slideIn/Out() and fadeIn/Out().
- Add new `oneShot`, `animateAfter`, `resetAll` functions to allow for more control over animations.
- Add new `repeat` parameter to animation functions to allow for repeating animations.
- Add new `delay` parameter to animation functions to allow for delaying animations.
- Add new `playIf` parameter to animation functions to allow for conditional animations.

## 0.1.1

- Minor doc updates.
- Add example GIFs in readme.

## 0.1.0

- Initial Release.
