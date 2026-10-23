# Cosmetic catalog — LittleGod 0.8

24 original reusable SVG assets, 23 earnable cosmetics and one unavailable future store collection. Rarity describes collection value only. All items have English and Turkish names/descriptions in the shared `assets/cosmetics/catalog.json`; game and API use the same IDs.

| ID | English / Türkçe | Category | Rarity | Stardust | Requirement |
|---|---|---|---|---:|---|
| enchanted | Enchanted Forest / Büyülü Orman | theme | common | 0 | none |
| crystal | Crystal Paradise / Kristal Cennet | theme | rare | 40 | species2 |
| celestial | Celestial Night / Göksel Gece | theme | epic | 65 | finding1 |
| ancient | Ancient Kingdom / Kadim Krallık | theme | rare | 50 | village1 |
| flowers | Moon daisies / Ay papatyaları | decor | common | 0 | none |
| stones | Wishing stones / Dilek taşları | decor | common | 0 | none |
| willow | Guardian willow / Koruyucu söğüt | decor | uncommon | 15 | none |
| prisms | Amethyst chorus / Ametist korosu | decor | rare | 20 | species2 |
| falls | Ribbon waterfall / Şerit şelale | decor | rare | 20 | none |
| fireflies | Firefly lantern garden / Ateşböceği bahçesi | decor | uncommon | 15 | none |
| glowfern | Starlit ferns / Yıldızlı eğreltiler | decor | uncommon | 15 | none |
| ruins | Remembering arch / Anı kemeri | decor | rare | 25 | village1 |
| obelisk | Star monument / Yıldız anıtı | decor | epic | 30 | finding1 |
| banner | Village pennant / Köy flaması | settlement | common | 10 | village1 |
| lanterns | Festival lanterns / Şenlik fenerleri | settlement | uncommon | 15 | village1 |
| statue | Little guardian statue / Küçük koruyucu heykeli | settlement | rare | 20 | village1 |
| aurora | Aurora ribbons / Kutup ışığı şeritleri | sky | rare | 20 | species2 |
| comets | Wandering stars / Gezgin yıldızlar | sky | uncommon | 15 | none |
| orbit | Orbital embrace / Yörünge kucaklaması | frame | rare | 20 | none |
| mint | Mint coat / Nane kürk | creature | uncommon | 10 | none |
| sunset | Sunset coat / Günbatımı kürkü | creature | uncommon | 10 | none |
| starband | Star circlet / Yıldız tacı | creature | rare | 15 | species2 |
| dreamer | Dreaming dance / Düş dansı | creature | epic | 20 | finding1 |
| royal_pack | Astral heirloom collection / Göksel yadigâr koleksiyonu | premium | legendary | Unavailable | none |

`none`: no discovery gate; `species2`: two discovered species; `finding1`: one recorded story; `village1`: an existing community. Ownership remains after storing/unequipping. Village themes coordinate existing settlement palettes; banners, lanterns, statues and ruins are decorative, never functional population buildings.

Enchanted Forest uses green atmosphere and moonlit vegetation; Crystal Paradise adds icy cyan/amethyst palette and floating prisms; Celestial Night uses indigo sky and orbiting stars; Ancient Kingdom adds amber light and gold motes. Terrain, water and settlement colors are coordinated while original painted biome/creature art remains. Sky ribbons/comets and the orbit frame are separately equipable.

The 24 vector illustrations are generated reproducibly by `devtools/create_cosmetic_art.py`, rasterized by Godot at 128×128. World props share a 768×512 atlas to reduce GPU texture switches; UI previews retain the individual SVGs. Environment assets appear as real depth-sorted world props, not static concept art. Isometric facings mirror/foreshorten props rather than tilting upright trees sideways. Waterfalls require a boundary water tile. Creature colors, star accessory and harmless dreamer idle target real individual IDs.

Premium collection `royal_pack` is metadata/preview only, excluded from valid local ownership and public appearance. No price, real-money purchase, fake completion or Stardust sale is enabled.
