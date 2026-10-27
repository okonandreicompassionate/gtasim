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
- Open the **⚽ Football Career** button from the game menu to create a saved player, choose a position, and progress through Academy Prospect, Reserve Player, First-Team Starter, and Lagos Star. The career has separate money, fitness, energy, mood, reputation, match results, and attributes.
- Follow GPS to the **Academy Training Ground** for a live ball trial. Move with the normal walking controls or touch stick; press **J/SHOOT** to shoot and **E/PASS** to pass. Score three goals or play out the 90-second drill to earn skill progress and career funds.
- Play an on-foot, timed 3-a-side match at Lagos National Stadium, Island Arena, or Surulere City Stadium. Move around the pitch with **WASD / arrow keys** or the touch stick; **E** passes to a teammate and **J** shoots. The ball starts within reach and has a bright floating locator. Opponents and teammates chase and play the ball. Match score, player goals, wellbeing, reputation, wages, and promotions update your saved career. Matches last 2:30; walk to a stadium or use its GPS button in the career panel.
- Visit Iron Palm Fitness, Lagoon View Hotel, The Velvet Room, Surulere Cinema, or Mama Suya and use their career activity option. Workouts, rest, meals, movies, and dancing have different costs and wellbeing effects; club dancing uses an in-game dance animation.
- Career funds can buy vehicles that join the city garage and purchase residences: the starter apartment, City Villa Estate, and Lagos Mansion Estate. The villa and mansion are walkable city landmarks; press **E** at either entrance to open career ownership. The starter apartment uses the existing home interior, while bespoke villa/mansion interiors are not part of this first pass. Career progress is saved locally and included with signed-in cloud saves; it uses a separate wallet from sandbox cash.
- Three large football stadiums have been added as city landmarks, with floodlight towers, multi-tier stands, pitch markings, goals, and GPS entrances. The playable career match is a compact 3-a-side arcade simulation, not full 11-a-side FIFA-style gameplay.
