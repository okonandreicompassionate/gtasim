"# gtasim" 

## Setup

For account-based daily streaks, apply the updated [Supabase schema](./supabase-schema.sql) in the project's Supabase SQL Editor. The streak repair and migration logic runs on the server after the schema is updated.

## Controls

- On foot and in ground vehicles: **Left Arrow/A** turns or moves left; **Right Arrow/D** turns or moves right. In vehicles, **W** accelerates and **S** brakes while moving forward and reverses once nearly stopped.
- Aircraft: **W/Up** ascends while tilting the main rotor forward to move ahead; helicopters do not reverse, and **Space** descends/lands. The helicopter auto-levels, **A/D** turn, and **Q/E** slide via the tail rotor. On touch screens, use the left flight stick to move and turn, and the right-side controls to ascend, land, and slide. The flight gauge displays ground clearance, heading, vertical speed, and rotor speed.
- The in-game clock starts at **08:00** and runs through a full 24-hour day in 24 real minutes, with gradual dawn, daylight, sunset, and night lighting.
- Wanted level is shown in the left HUD. Higher wanted levels add faster foot pursuits and police cruisers that chase and ram your vehicle.
- Find **Police Station** in the landmark list and set a GPS route. At the entrance, press **E** (or touch **ENTER**) to open reception; pay ₦20,000 per active wanted star to clear your wanted level. You need enough cash to cover the full fine.
- Graphics start at **Detail** on desktop and **Balanced** on touch devices; adaptive rendering lowers quality if performance drops.
- Find **Crew House** in the map's landmark list, set a GPS route, then press **E** (or touch **ENTER**) at the house to register a crew and choose its color. The house offers neighborhood patrol, supply-run, and block-hold missions for cash and reputation.
- Crew name, color, reputation, and completed missions save on the device and with the signed-in cloud save. Gang missions are currently solo.
