# Working notes on the animal models

Measured in Godot 4.7.2, not read off the glTF. **The glTF bounding boxes lie
for the duck and the swan**: both are skinned, and a skinned `MeshInstance3D`
reports its bind-pose box, which on these Sketchfab exports is nothing like the
rendered size. The duck's file claims 0.115 m tall; posed, it is 0.618 m. Always
measure by walking the mesh vertices through `Skeleton3D.get_bone_global_pose()`,
or simply scale by eye against a reference post.

| Model | Posed height | Triangles | Skinned | Animations | Materials |
|---|---|---|---|---|---|
| duck | 0.618 m | 652 | yes | `walkcycle_1`, 0.53 s | 7 flat colours |
| swan | 3.708 m (wings spread) | 1684 | yes | `Animation` and `ArmatureAction`, 5.21 s each, identical | 1, textured |
| mouse | 16.55 m | 874 | no | none | 1 flat colour |

Imported animations arrive with `loop_mode = 0`; set `LOOP_LINEAR` at runtime
before playing a walk cycle.

## Wings

Neither bird can be made to do everything, and both limits are in the assets:

- **The duck cannot flap.** Its armature carries `fin.L_1` and `fin.R_0`
  bones, but they hold no meaningful vertex weight: posing them moves nothing
  on screen. This was established by posing `neck_6` the same way, which bends
  the neck right over, so the posing code is sound and the weights are not.
  Duck flight reads through the body's pitch and bank alone. Fixing it means
  weighting the wings in Blender, or finding a duck with a flap cycle.
- **The swan flaps, but never folds.** Its single animation is a wing beat and
  makes a good flight cycle. Its rest pose has the wings spread, and no frame
  of that animation folds them, so it stands and swims with its wings out.
  Fixing it means a folded pose added in Blender.

## Animation gotchas

`AnimationPlayer.pause()` in Godot 4.7 drops the animation entirely and snaps
the model back to its bind pose. To hold a frame, set `speed_scale = 0.0` and
leave it playing.

## Recolouring

The duck is the flexible one. Its seven materials are flat `albedo_color`
values with no texture, named `duck_gray`, `duck_brown`, `duck_green`,
`duck_yellow`, `duck_white`, `duck_black` and `duck_orange`. Override them per
instance (duplicate the material, set `albedo_color`, then
`set_surface_override_material`) and one mesh covers the player at every stage,
the four siblings and Marra. Never edit the imported material in place: it is
shared by every instance.

The mouse is a single flat colour, so it recolours the same way.

The swan is textured (white plumage, black-and-orange bill), so it can only be
tinted, not repainted. It does not need repainting. `HeartMaterial` already
handles tinting textured materials for the Heart system.

## Scale factors

`AnimalModel` does this automatically: it measures the model as posed and
scales it to the `height` given, so a scene only asks for "a duckling this
tall". Measure in the model's **own** space, never world space, or a parent's
scale (the player's growth, a preview holder) silently corrupts the result.

Scale to a target height rather than hard-coding a factor, since the player's
own size is driven by `Globals.player_scale`. Reference heights: the hatchling's
head top is 0.67 m at `PlayerScale` 1.0, so the adult swan at 3.5 is 2.35 m.

The swan's height is dominated by its long neck, not its wings, so scaling by
total height works: at `height` 0.78 it reads correctly beside a duck.
