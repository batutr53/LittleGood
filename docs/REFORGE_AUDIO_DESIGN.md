# Reforge audio — audit begun, redesign pending

Current `soundscape.gd` builds audio players in code, loads legacy action WAVs
and wind/rain loops, and exposes synthesized chimes and sanctuary SFX. The
requested independent Master/Music/Ambience/UI/SFX/Combat/Voice mix, replacement
assets and contact-aligned audio redesign are not implemented by R2.

Five existing PCM files were measured: UI button, water action, discovery,
sanctuary swing and impact. `docs/benchmarks/reforge/audio-pcm.json` records
duration, peak/RMS dBFS and full-scale sample counts. These are numerical file
measurements, **not a listening audit**, concurrent mix test or evidence of
pleasant sound. No professional soundtrack/voiceover claim is made.

Next audio work must audition before/after output, classify actual accepted
events, separate buses and volume persistence, bound voice overlap, route valid
hits separately from misses, preserve ambience across NPC conversations and
test mute/background behavior. Existing sounds are preserved until replacements
are properly verified. No paid services/packs were used.
