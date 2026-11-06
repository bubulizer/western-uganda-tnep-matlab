# Data dictionary and provenance

## Study boundary

The executable case is an 11-bus, 132 kV positive-sequence steady-state
equivalent. It follows the proposal's stated bus count and represents the two
major western loops plus radial Kyaka and Mbarara South interfaces. The bulk-grid
equivalent at Mutundwe is the slack/reference bus.

## Provenance classes

- `public`: value transcribed from a public planning or regulatory source.
- `proposal`: topology or label transcribed from Figure 3.1/Chapter Three.
- `derived`: calculated from a stated public value or engineering formula.
- `assumed`: research-case placeholder needed to run the model.

Key public line values come from JICA's Uganda hydropower master-plan table,
which attributes the data to UETCL: Kabulasoke-Masaka West 59.5 km/63.1 MVA,
Kabulasoke-Nkonge 78 km/63.1 MVA, Masaka West-Kyaka 85 km/73.8 MVA,
Masaka West-Mbarara North 129.6 km/151.6 MVA, Mutundwe-Kabulasoke
84.5 km/63.1 MVA, and Nkonge-Nkenda 138.11 km/63.1 MVA. The latter is split
between Nkonge-Kahungye and Kahungye-Nkenda to match the proposal diagram.

## Electrical assumptions

- Base power: 100 MVA; nominal voltage: 132 kV.
- Generic overhead-line constants where conductor schedules are unavailable:
  R = 0.060 ohm/km, X = 0.380 ohm/km, B = 3.5 microS/km.
- Per-unit conversion uses Zbase = 132^2/100 = 174.24 ohm.
- Loads and generation are illustrative peak-hour injections.
- Voltage limits are 0.95-1.05 p.u.; candidate cost is an illustrative
  0.55 million USD/km unless a row states otherwise.
- Geographic coordinates are approximate town/substation-area centroids for
  mapping and route sanity checks, not surveyed tower coordinates.

## Required UETCL replacements before thesis submission

1. Timestamped bus P/Q demand and generation schedules for at least peak,
   off-peak and shoulder cases.
2. Positive/zero-sequence line impedances, charging, circuit count and actual
   thermal/emergency ratings.
3. Transformer MVA, impedance, tap range/step and control mode.
4. Shunt reactor/capacitor ratings and switched status.
5. Existing breaker status, permitted switching list and protection restrictions.
6. Candidate route/circuit scope, detailed CAPEX, O&M, construction lead time,
   discount rate, outage rate and energy-not-served valuation.
7. SCADA/EMS base-case voltages and flows for calibration, plus event/outage data
   for N-1 validation.
8. Surveyed substation/tower coordinates or utility GIS export.

## Output interpretation

The generated numbers demonstrate the methodology and software implementation.
They are not utility-approved findings. The final thesis should report them as
"research-case" results until the eight replacement groups above are supplied.

