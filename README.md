# Hamamatsu Imaging Rebuilt Workflow

This repository currently uses the rebuilt acquisition workflow centered on:

- `Hamamatsu_Imaging_2_Cameras_rebuilt.m`
- `Hamamatsu_Imaging_2_Cameras_rebuilt.mlx`

The `.m` file is the cleaned script source.
The `.mlx` file is the live-script version used during experiments.

## What This Rebuilt Version Covers

- Hamamatsu camera acquisition
- DAQ configuration and synchronization
- ROI registration and re-application
- PTB-based visual stimulation
- Method / record allocation and manifest saving
- Unified stimulus selection, preview, and experiment playback

## Current Stimulus Programs

The rebuilt workflow currently supports five selectable stimulus programs:

1. `drifting_grating`
2. `gray_blue_gray`
3. `gray_white_gray_black`
4. `white_black_flicker`
5. `contrast_reverse`

Each of these programs is available in three places:

- `Stimulus preparation`
- `PTB selected stimulus test section`
- formal experiment playback through `RunVisualStimulation`

## Recommended Section Order

Run sections in this order during a normal session:

1. `Initialization`
2. `Connect to Camera`
3. `Connect to DAQ`
4. `Set light source`
5. `Align Two Cameras`
6. `Apply Imported Registration Parameters` if imported registration is needed
7. `Configure Default Device Properties for Voltage Recording`
8. PTB / stimulation initialization section
9. One `Stimulus preparation: ...` section
10. `PTB selected stimulus test section`
11. `Output allocation: freeze a new method`
12. `Recording start`
13. `Main execution engine`

## User-Specific Parameters

The following values are expected to change between animals, sessions, rigs, or monitor setups:

- `root_path`
- `recordmode`
- `method_note`
- `light_channel`
- `screenNumber`
- `cfg.label`

These are marked inline in `Hamamatsu_Imaging_2_Cameras_rebuilt.m` with `User-specific parameter` comments.

## Notes

- `screenNumber` is currently fixed in the script instead of using `max(Screen('Screens'))`.
  Adjust it if PTB opens on the wrong monitor.
- The old standalone PTB preview sections were removed in favor of the unified selected-stimulus preview path.
- The manual registration re-application section is kept because it is part of the actual operating workflow, not just a personal parameter tweak.
