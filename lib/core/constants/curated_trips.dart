import '../models/curated_trip.dart';

/// Hand-curated trips selected by the Lost in Egypt team.
///
/// Scoring keys are chosen to be *characteristic* of each trip, not exhaustive,
/// so that taste-vector scoring differentiates between trips clearly.
abstract final class CuratedTrips {
  static const List<CuratedTrip> all = [
    islamicCairo,
    coastal,
    grecoRoman,
    luxorTemples,
    aswanNubia,
    hurghadaRedSea,
    sharmSinai,
    siwaOasis,
  ];

  // ── Islamic Cairo ────────────────────────────────────────────────────────────

  static const islamicCairo = CuratedTrip(
    id: 'islamic_cairo',
    title: 'Islamic Cairo',
    tagline: 'Walk through 1,400 years of Islamic history in a single city',
    imagePath: 'assets/images/islamic_tour.png',
    primaryArea: 'Cairo',
    areas: ['Cairo'],
    durationDays: 2,
    budgetRange: '500–1,500 EGP',
    interests: ['Monuments', 'Culture & Traditions', 'Local Experiences'],
    scoringKeys: [
      'islamic', 'religious', 'cultural', 'historical',
      'mosque', 'market', 'food', 'shopping',
    ],
    highlights: [
      'Wander a 700-year-old bazaar full of spices, gold, and perfume',
      'Climb to a medieval citadel for sweeping views over all of Cairo',
      'Visit three of the oldest mosques in the Islamic world',
    ],
    bestFor: 'History & culture lovers',
    rating: 4.8,
    centerLat: 30.0444,
    centerLng: 31.2357,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — Pharaonic Roots & Islamic Heart',
        stops: [
          CuratedTripStop(
            name: 'Egyptian Museum',
            description:
                'Home to the world\'s largest collection of ancient Egyptian artifacts, '
                'including the golden treasures of Tutankhamun. Arrive early for the '
                'mummies hall upstairs.',
            estimatedDuration: '2–3 hours',
            type: 'museum',
            lat: 30.0478,
            lng: 31.2336,
          ),
          CuratedTripStop(
            name: 'Khan el-Khalili Bazaar',
            description:
                'A labyrinthine medieval bazaar founded in 1382. Browse hand-crafted '
                'jewelry, spices, and perfume oils. Stop at El Fishawy café for a '
                'traditional mint tea — it has been open continuously since 1797.',
            estimatedDuration: '1–2 hours',
            type: 'market',
            lat: 30.0479,
            lng: 31.2628,
          ),
          CuratedTripStop(
            name: 'Al-Azhar Mosque',
            description:
                'Founded in 970 AD, Al-Azhar is one of the world\'s oldest universities '
                'and a living centre of Islamic scholarship. Non-Muslims are welcome '
                'outside prayer times.',
            estimatedDuration: '45 minutes',
            type: 'mosque',
            lat: 30.0455,
            lng: 31.2617,
          ),
          CuratedTripStop(
            name: 'Al-Hussain Mosque & Square',
            description:
                'A lively square surrounded by some of Cairo\'s best street food. Try '
                'koshary (Egypt\'s national dish) or fresh juice from the local stalls '
                'as the evening call to prayer echoes across the rooftops.',
            estimatedDuration: '1 hour',
            type: 'mosque',
            lat: 30.0481,
            lng: 31.2626,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — Citadels, Mosques & Old Cairo',
        stops: [
          CuratedTripStop(
            name: 'Mosque of Ibn Tulun',
            description:
                'Built in 879 AD, this is the oldest mosque in Cairo still standing in '
                'its original form. Its unusual spiral minaret is unique in Egypt. '
                'Climb it for a panoramic view of Islamic Cairo.',
            estimatedDuration: '1 hour',
            type: 'mosque',
            lat: 30.0283,
            lng: 31.2497,
          ),
          CuratedTripStop(
            name: 'Gayer-Anderson Museum',
            description:
                'Two 17th-century houses connected by a bridge, filled with antiques, '
                'Persian rugs, and Islamic art. Made famous as a James Bond filming '
                'location. Entry is included with the Ibn Tulun ticket.',
            estimatedDuration: '45 minutes',
            type: 'museum',
            lat: 30.0284,
            lng: 31.2498,
          ),
          CuratedTripStop(
            name: 'Citadel of Saladin',
            description:
                'A medieval fortress built by Saladin in 1183 that dominates the Cairo '
                'skyline. Inside you\'ll find the Muhammad Ali Mosque with its stunning '
                'alabaster interior and sweeping views of the city below.',
            estimatedDuration: '2 hours',
            type: 'historical_landmark',
            lat: 30.0292,
            lng: 31.2590,
          ),
          CuratedTripStop(
            name: 'Sultan Hassan Mosque',
            description:
                'Considered one of the greatest examples of Mamluk architecture in the '
                'world. Its 38-metre entrance portal is the tallest in Egypt. Visit '
                'at sunset when the light turns golden on the carved stone.',
            estimatedDuration: '45 minutes',
            type: 'mosque',
            lat: 30.0296,
            lng: 31.2564,
          ),
        ],
      ),
    ],
  );

  // ── Coastal Alexandria ───────────────────────────────────────────────────────

  static const coastal = CuratedTrip(
    id: 'coastal_alexandria',
    title: 'Coastal Alexandria',
    tagline: 'Where the Mediterranean meets 3,000 years of layered history',
    imagePath: 'assets/images/coastal_tour.png',
    primaryArea: 'Alexandria',
    areas: ['Alexandria'],
    durationDays: 2,
    budgetRange: '800–2,000 EGP',
    interests: ['Beaches', 'Monuments', 'Museums'],
    scoringKeys: [
      'natural', 'relaxation', 'beach', 'historical', 'park', 'cultural',
    ],
    highlights: [
      'Walk the Mediterranean Corniche — one of the most beautiful seafronts in Africa',
      'Explore the modern Library of Alexandria, reborn after 1,600 years',
      'See the spot where the ancient world\'s greatest lighthouse once stood',
    ],
    bestFor: 'Beach & history lovers',
    rating: 4.5,
    centerLat: 31.2001,
    centerLng: 29.9187,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — Knowledge & Ancient Power',
        stops: [
          CuratedTripStop(
            name: 'Bibliotheca Alexandrina',
            description:
                'The modern resurrection of the ancient Library of Alexandria, opened in '
                '2002. Its tilted disc roof is covered in characters from every known '
                'alphabet. Inside: 8 million books, 4 museums, and a planetarium.',
            estimatedDuration: '2–3 hours',
            type: 'museum',
            lat: 31.2089,
            lng: 29.9093,
          ),
          CuratedTripStop(
            name: 'Qaitbay Citadel',
            description:
                'A 15th-century fortress built on the precise site of the ancient Pharos '
                'lighthouse — one of the Seven Wonders of the Ancient World. Walk the '
                'battlements for views of the Mediterranean stretching to the horizon.',
            estimatedDuration: '1–1.5 hours',
            type: 'historical_landmark',
            lat: 31.2136,
            lng: 29.8855,
          ),
          CuratedTripStop(
            name: 'Alexandria Corniche',
            description:
                'A 20-kilometre seafront promenade along the Mediterranean coast. Rent '
                'a bicycle or stroll westward as fishing boats bob in the harbour. '
                'Perfect at golden hour with fresh corn and seafood from street vendors.',
            estimatedDuration: '1 hour',
            type: 'park',
            lat: 31.2156,
            lng: 29.9553,
          ),
          CuratedTripStop(
            name: 'Abu Abbas al-Mursi Mosque',
            description:
                'A magnificent Ottoman-era mosque in the heart of the city, named for '
                'a 13th-century Moroccan saint. The courtyard fills with worshippers '
                'at dusk — a peaceful contrast to the busy Corniche outside.',
            estimatedDuration: '30 minutes',
            type: 'mosque',
            lat: 31.2131,
            lng: 29.8897,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — Roman Ruins & Mediterranean Beaches',
        stops: [
          CuratedTripStop(
            name: 'Kom el-Dikka (Roman Amphitheatre)',
            description:
                'The only Roman amphitheatre ever discovered in Egypt, with 13 tiers of '
                'white marble. Stumbled upon in 1964 during construction of an apartment '
                'block. The adjacent Roman baths and villas are still being excavated.',
            estimatedDuration: '1 hour',
            type: 'archaeological_site',
            lat: 31.1962,
            lng: 29.9067,
          ),
          CuratedTripStop(
            name: 'Greco-Roman Museum',
            description:
                'Over 40,000 objects tracing Alexandria\'s Hellenistic, Roman, and early '
                'Christian eras. Highlights include a black granite statue of Apis '
                'the sacred bull and mummies in painted coffins.',
            estimatedDuration: '1.5 hours',
            type: 'museum',
            lat: 31.1991,
            lng: 29.9081,
          ),
          CuratedTripStop(
            name: 'Stanley Beach',
            description:
                'Alexandria\'s most iconic beach, known for its photogenic Stanley Bridge '
                'stretching out over the sea. Swim in the Mediterranean, rent a paddle '
                'board, or just sit with a cold sugarcane juice and watch the waves.',
            estimatedDuration: '2 hours',
            type: 'beach',
            lat: 31.2212,
            lng: 29.9641,
          ),
          CuratedTripStop(
            name: 'Montaza Palace Gardens',
            description:
                'A 150-acre royal estate built by Khedive Abbas II. The gardens, open '
                'to the public, stretch along a private beach and contain two palaces. '
                'Perfect for a sunset walk before heading back into the city.',
            estimatedDuration: '1 hour',
            type: 'park',
            lat: 31.2817,
            lng: 30.0100,
          ),
        ],
      ),
    ],
  );

  // ── Greco-Roman Alexandria ───────────────────────────────────────────────────

  static const grecoRoman = CuratedTrip(
    id: 'greco_roman',
    title: 'Greco-Roman Alexandria',
    tagline: 'Where three civilisations — Greek, Roman, and Egyptian — collided',
    imagePath: 'assets/images/greek_tour.png',
    primaryArea: 'Alexandria',
    areas: ['Alexandria'],
    durationDays: 1,
    budgetRange: '300–700 EGP',
    interests: ['Monuments', 'Museums'],
    scoringKeys: [
      'pharaonic', 'ancient', 'historical', 'cultural',
      'museum', 'archaeological_site', 'monument',
    ],
    highlights: [
      'Descend into eerie Roman-era burial chambers carved into solid rock',
      'See a 27-metre granite column that has stood for over 1,700 years',
      'Marvel at art that blends pharaonic, Greek, and Roman styles into one',
    ],
    bestFor: 'Ancient history enthusiasts',
    rating: 4.3,
    centerLat: 31.1900,
    centerLng: 29.8980,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — The Layers of Ancient Alexandria',
        stops: [
          CuratedTripStop(
            name: 'Pompey\'s Pillar',
            description:
                'A 27-metre red Aswan granite column erected in 297 AD in honour of '
                'Emperor Diocletian — one of the largest ancient monoliths outside Rome. '
                'The surrounding site contains sphinxes and underground temple galleries.',
            estimatedDuration: '45 minutes',
            type: 'monument',
            lat: 31.1815,
            lng: 29.8981,
          ),
          CuratedTripStop(
            name: 'Catacombs of Kom el-Shoqafa',
            description:
                'Descend three levels into a vast 2nd-century AD necropolis cut directly '
                'into rock. The burial chambers blend pharaonic imagery with Greek and '
                'Roman decorative styles in a way found nowhere else on Earth.',
            estimatedDuration: '1–1.5 hours',
            type: 'archaeological_site',
            lat: 31.1810,
            lng: 29.8979,
          ),
          CuratedTripStop(
            name: 'Greco-Roman Museum',
            description:
                'Alexandria\'s finest museum, housing 40,000+ objects spanning the '
                'Hellenistic and Roman eras. The Apis bull hall and the mummy portraits '
                'painted in Roman style (Fayum portraits) are the standout exhibits.',
            estimatedDuration: '1.5–2 hours',
            type: 'museum',
            lat: 31.1991,
            lng: 29.9081,
          ),
          CuratedTripStop(
            name: 'Serapeum & Diocletian Column Site',
            description:
                'The ancient sanctuary of the god Serapis — a divine fusion of Greek '
                'and Egyptian religion invented by Ptolemy I. The vast underground '
                'library tunnels here may have stored scrolls from the Great Library.',
            estimatedDuration: '45 minutes',
            type: 'archaeological_site',
            lat: 31.1816,
            lng: 29.8974,
          ),
        ],
      ),
    ],
  );

  // ── Luxor Temples ────────────────────────────────────────────────────────────

  static const luxorTemples = CuratedTrip(
    id: 'luxor_temples',
    title: 'Luxor — Valley of the Pharaohs',
    tagline: 'The world\'s greatest open-air museum, 4,000 years in the making',
    imagePath: 'assets/images/islamic_tour.png',
    primaryArea: 'Luxor',
    areas: ['Luxor'],
    durationDays: 2,
    budgetRange: '1,200–3,000 EGP',
    interests: ['Monuments', 'Museums', 'Culture & Traditions'],
    scoringKeys: [
      'pharaonic', 'ancient', 'historical', 'monument',
      'archaeological_site', 'temple', 'cultural',
    ],
    highlights: [
      'Enter the tomb of Tutankhamun in the legendary Valley of the Kings',
      'Watch sunrise light flood the colossal columns of Karnak Temple',
      'Stand before Queen Hatshepsut\'s mortuary temple carved into the cliffs',
    ],
    bestFor: 'Pharaonic history seekers',
    rating: 4.9,
    centerLat: 25.6872,
    centerLng: 32.6396,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — East Bank: Temples of the Living',
        stops: [
          CuratedTripStop(
            name: 'Karnak Temple Complex',
            description:
                'The largest religious building ever constructed — built over 2,000 years '
                'by 30 successive pharaohs. The Great Hypostyle Hall contains 134 massive '
                'columns, some 23 metres tall. Arrive at dawn before the crowds.',
            estimatedDuration: '2–3 hours',
            type: 'archaeological_site',
            lat: 25.7188,
            lng: 32.6573,
          ),
          CuratedTripStop(
            name: 'Luxor Temple',
            description:
                'Built by Amenhotep III and enlarged by Ramesses II, Luxor Temple sits '
                'right in the heart of the modern city. Connected to Karnak by the '
                '3-km Avenue of the Sphinxes. Spectacular when lit up at night.',
            estimatedDuration: '1.5 hours',
            type: 'archaeological_site',
            lat: 25.6995,
            lng: 32.6391,
          ),
          CuratedTripStop(
            name: 'Luxor Museum',
            description:
                'A world-class museum displaying treasures from the Luxor area, including '
                'two intact royal mummies and a stunning wall from the Karnak cachette. '
                'Far less crowded than Cairo\'s Egyptian Museum.',
            estimatedDuration: '1.5 hours',
            type: 'museum',
            lat: 25.7047,
            lng: 32.6400,
          ),
          CuratedTripStop(
            name: 'Nile Felucca Sunset Cruise',
            description:
                'End the day drifting on a traditional wooden sailboat as the sun sets '
                'over the West Bank. Watch the Theban Hills turn golden while vendors '
                'offer fresh sugarcane juice and the call to prayer drifts across the water.',
            estimatedDuration: '1.5 hours',
            type: 'park',
            lat: 25.6954,
            lng: 32.6369,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — West Bank: Cities of the Dead',
        stops: [
          CuratedTripStop(
            name: 'Valley of the Kings',
            description:
                'Sixty-three royal tombs cut into the limestone hills, including '
                'Tutankhamun\'s (KV62). The ceilings and walls are painted in vivid '
                'colour as perfectly as the day they were sealed 3,200 years ago.',
            estimatedDuration: '2–3 hours',
            type: 'archaeological_site',
            lat: 25.7402,
            lng: 32.6014,
          ),
          CuratedTripStop(
            name: 'Temple of Hatshepsut',
            description:
                'Three colonnaded terraces rising against a sheer cliff face, built for '
                'Egypt\'s most powerful female pharaoh. The painted reliefs inside '
                'tell the story of a divine trade expedition to the land of Punt.',
            estimatedDuration: '1.5 hours',
            type: 'archaeological_site',
            lat: 25.7380,
            lng: 32.6071,
          ),
          CuratedTripStop(
            name: 'Colossi of Memnon',
            description:
                'Two 18-metre quartzite statues of Pharaoh Amenhotep III guard the '
                'entrance to his now-vanished mortuary temple. Once the tallest statues '
                'in the ancient world — still awe-inspiring from across the plain.',
            estimatedDuration: '30 minutes',
            type: 'monument',
            lat: 25.7201,
            lng: 32.6104,
          ),
          CuratedTripStop(
            name: 'Valley of the Queens',
            description:
                'Ninety tombs of royal wives and princes, including the spectacular tomb '
                'of Queen Nefertari — considered the most beautiful tomb in all of Egypt. '
                'Visitor numbers are strictly limited to protect the pigments.',
            estimatedDuration: '1 hour',
            type: 'archaeological_site',
            lat: 25.7295,
            lng: 32.5951,
          ),
        ],
      ),
    ],
  );

  // ── Aswan & Nubia ────────────────────────────────────────────────────────────

  static const aswanNubia = CuratedTrip(
    id: 'aswan_nubia',
    title: 'Aswan & Nubia',
    tagline: 'Where the Nile narrows and ancient Africa meets ancient Egypt',
    imagePath: 'assets/images/coastal_tour.png',
    primaryArea: 'Aswan',
    areas: ['Aswan'],
    durationDays: 2,
    budgetRange: '1,000–2,500 EGP',
    interests: ['Monuments', 'Nature & Parks', 'Local Experiences'],
    scoringKeys: [
      'pharaonic', 'ancient', 'historical', 'natural',
      'cultural', 'nubian', 'river', 'relaxation',
    ],
    highlights: [
      'Island-hop to Philae Temple, rising from the waters of Lake Nasser',
      'Visit a Nubian village and share lunch with a local family',
      'Watch the Nile flow past granite boulders from a rooftop café',
    ],
    bestFor: 'Nature & culture explorers',
    rating: 4.7,
    centerLat: 24.0889,
    centerLng: 32.8998,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — Temples on the Water',
        stops: [
          CuratedTripStop(
            name: 'Philae Temple (Agilkia Island)',
            description:
                'Dedicated to the goddess Isis, Philae was dismantled stone by stone '
                'and rebuilt on a higher island when Lake Nasser was created. Arrive '
                'by motorboat across the turquoise water for maximum drama.',
            estimatedDuration: '1.5–2 hours',
            type: 'archaeological_site',
            lat: 24.0265,
            lng: 32.8837,
          ),
          CuratedTripStop(
            name: 'Aswan High Dam',
            description:
                'One of the largest embankment dams in the world, completed in 1970 '
                'and creating 500-km-long Lake Nasser. The visitor pavilion explains '
                'how it transformed Egypt\'s agriculture and displaced 100,000 Nubians.',
            estimatedDuration: '45 minutes',
            type: 'monument',
            lat: 23.9700,
            lng: 32.8757,
          ),
          CuratedTripStop(
            name: 'Unfinished Obelisk',
            description:
                'A colossal obelisk still attached to its granite bedrock — abandoned '
                'when a crack appeared 3,500 years ago. Had it been completed, it would '
                'have been the largest obelisk ever erected in Egypt.',
            estimatedDuration: '45 minutes',
            type: 'archaeological_site',
            lat: 24.0855,
            lng: 32.8947,
          ),
          CuratedTripStop(
            name: 'Aswan Souq (Market)',
            description:
                'Aswan\'s spice and craft market, spilling along a narrow street above '
                'the Nile corniche. Nubian handicrafts, aromatic hibiscus tea, and '
                'dates pressed with nuts make perfect souvenirs.',
            estimatedDuration: '1 hour',
            type: 'market',
            lat: 24.0897,
            lng: 32.9027,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — Nubian Culture & Nile Islands',
        stops: [
          CuratedTripStop(
            name: 'Nubian Village (West Bank)',
            description:
                'Brightly painted houses, crocodile farms, and impossibly warm '
                'hospitality. A local family will likely invite you in for karkade '
                '(hibiscus tea) and homemade Nubian bread with honey.',
            estimatedDuration: '2 hours',
            type: 'cultural',
            lat: 24.1021,
            lng: 32.8698,
          ),
          CuratedTripStop(
            name: 'Elephantine Island',
            description:
                'Ancient settlement at the heart of the Nile, with ruins dating to '
                '3000 BC. The Nilometer here was used to predict the annual flood. '
                'The island\'s Nubian community still lives amid the pharaonic ruins.',
            estimatedDuration: '1.5 hours',
            type: 'archaeological_site',
            lat: 24.0866,
            lng: 32.8932,
          ),
          CuratedTripStop(
            name: 'Botanical Garden (Kitchener\'s Island)',
            description:
                'Lord Kitchener transformed this entire island into a lush botanical '
                'garden in the 1890s. Hundreds of exotic plants and birds — a serene '
                'escape best reached by rowing boat from the Aswan corniche.',
            estimatedDuration: '1 hour',
            type: 'park',
            lat: 24.0888,
            lng: 32.8887,
          ),
          CuratedTripStop(
            name: 'Aga Khan Mausoleum (viewpoint)',
            description:
                'Perched high on the West Bank above the Nile, this domed marble '
                'tomb of the Aga Khan III offers perhaps the finest panoramic view '
                'of Aswan — best at the golden hour before sunset.',
            estimatedDuration: '45 minutes',
            type: 'monument',
            lat: 24.0868,
            lng: 32.8745,
          ),
        ],
      ),
    ],
  );

  // ── Hurghada Red Sea ─────────────────────────────────────────────────────────

  static const hurghadaRedSea = CuratedTrip(
    id: 'hurghada_red_sea',
    title: 'Hurghada Red Sea',
    tagline: 'Dive into the world\'s most biodiverse coral reef sea',
    imagePath: 'assets/images/coastal_tour.png',
    primaryArea: 'Hurghada',
    areas: ['Hurghada'],
    durationDays: 2,
    budgetRange: '1,500–4,000 EGP',
    interests: ['Beaches', 'Adventure Activities', 'Nature & Parks'],
    scoringKeys: [
      'beach', 'natural', 'relaxation', 'adventure',
      'water', 'snorkeling', 'diving', 'marine',
    ],
    highlights: [
      'Snorkel over living coral reefs teeming with parrotfish and moray eels',
      'Take a glass-bottom boat over Giftun Island\'s private lagoon',
      'Watch the sun rise over the Red Sea from a white sand beach',
    ],
    bestFor: 'Beach & adventure lovers',
    rating: 4.6,
    centerLat: 27.2579,
    centerLng: 33.8116,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — Into the Blue',
        stops: [
          CuratedTripStop(
            name: 'Giftun Island National Park',
            description:
                'A protected coral island 8 km offshore, with water so clear you can '
                'see the reef from the boat deck. Snorkelling kit is provided. '
                'Dolphins are frequently spotted on the crossing.',
            estimatedDuration: 'Full day',
            type: 'beach',
            lat: 27.1652,
            lng: 33.9257,
          ),
          CuratedTripStop(
            name: 'Orange Bay Beach',
            description:
                'A natural crescent of white sand on a small island, accessible only '
                'by boat. The shallow turquoise lagoon makes it perfect for families '
                'and first-time snorkellers. Lunch is typically served on the beach.',
            estimatedDuration: '2 hours',
            type: 'beach',
            lat: 27.1552,
            lng: 33.9303,
          ),
          CuratedTripStop(
            name: 'Hurghada Marina',
            description:
                'End the day at the marina\'s waterfront restaurants watching the '
                'fishing boats return. Order grilled Red Sea fish (Emperor or '
                'Grouper) and watch the stars emerge over the water.',
            estimatedDuration: '1.5 hours',
            type: 'restaurant',
            lat: 27.1984,
            lng: 33.8370,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — Reefs, Ruins & Desert Dunes',
        stops: [
          CuratedTripStop(
            name: 'Hurghada Grand Aquarium',
            description:
                'Walk through a glass tunnel beneath 1,500 Red Sea species — including '
                'sharks, rays, and lionfish — in Egypt\'s largest aquarium. A great '
                'introduction to the reef ecosystem before you dive into it.',
            estimatedDuration: '1.5 hours',
            type: 'museum',
            lat: 27.1984,
            lng: 33.8240,
          ),
          CuratedTripStop(
            name: 'Mahmya Island',
            description:
                'A pristine island with an untouched reef on its southern tip — the '
                'most biodiverse snorkelling in the Hurghada area. The island is '
                'partly protected as a National Park, limiting daily visitors.',
            estimatedDuration: '3 hours',
            type: 'beach',
            lat: 27.1452,
            lng: 33.9157,
          ),
          CuratedTripStop(
            name: 'Desert Quad Bike Safari',
            description:
                'Ride out into the Eastern Desert at sunset on quad bikes, stopping '
                'at a Bedouin camp for mint tea and star-gazing. The contrast of '
                'a reef morning and desert evening is uniquely Hurghada.',
            estimatedDuration: '2–3 hours',
            type: 'park',
            lat: 27.2400,
            lng: 33.7800,
          ),
        ],
      ),
    ],
  );

  // ── Sharm El-Sheikh & Sinai ──────────────────────────────────────────────────

  static const sharmSinai = CuratedTrip(
    id: 'sharm_sinai',
    title: 'Sharm El-Sheikh & Sinai',
    tagline: 'Dive world-class reefs by day, climb a biblical mountain by night',
    imagePath: 'assets/images/greek_tour.png',
    primaryArea: 'Sharm El-Sheikh',
    areas: ['Sharm El-Sheikh', 'Dahab'],
    durationDays: 3,
    budgetRange: '2,000–6,000 EGP',
    interests: ['Beaches', 'Adventure Activities', 'Nature & Parks', 'Monuments'],
    scoringKeys: [
      'beach', 'adventure', 'natural', 'diving',
      'religious', 'historical', 'water', 'mountain',
    ],
    highlights: [
      'Night-hike Mount Sinai to watch sunrise from the summit of a biblical peak',
      'Dive the SS Thistlegorm — the world\'s most famous wreck dive',
      'Snorkel the Blue Hole, one of the planet\'s top dive sites',
    ],
    bestFor: 'Adventure & nature seekers',
    rating: 4.7,
    centerLat: 27.9158,
    centerLng: 34.3300,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — Naama Bay & Ras Mohammed',
        stops: [
          CuratedTripStop(
            name: 'Ras Mohammed National Park',
            description:
                'Egypt\'s first marine national park, where the Gulf of Suez and Gulf '
                'of Aqaba meet. The coral wall at Shark Reef drops 800 metres. '
                'Visibility is often 30+ metres — snorkelling is extraordinary.',
            estimatedDuration: '3–4 hours',
            type: 'park',
            lat: 27.7422,
            lng: 34.2413,
          ),
          CuratedTripStop(
            name: 'Naama Bay Beach',
            description:
                'Sharm\'s main beach strip, with calm, clear water and water sports '
                'ranging from parasailing to glass-bottom kayaking. The promenade '
                'behind fills with restaurants and shisha cafés at night.',
            estimatedDuration: '2 hours',
            type: 'beach',
            lat: 27.9157,
            lng: 34.3295,
          ),
          CuratedTripStop(
            name: 'Old Market (Sharm Old Town)',
            description:
                'The original Sharm El-Sheikh, a 10-minute drive from the beach strip, '
                'with local cafés, Egyptian pastry shops, and a lively spice market. '
                'Far more authentic and affordable than the tourist strip.',
            estimatedDuration: '1.5 hours',
            type: 'market',
            lat: 27.8600,
            lng: 34.2900,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — Dahab Blue Hole',
        stops: [
          CuratedTripStop(
            name: 'Blue Hole, Dahab',
            description:
                'A 100-metre-deep submarine sinkhole with an archway at 55m, '
                'ringed by some of the most colourful coral in the Red Sea. '
                'Snorkellers can safely enjoy the rim; the depth is for experienced divers.',
            estimatedDuration: '2–3 hours',
            type: 'beach',
            lat: 28.5688,
            lng: 34.5381,
          ),
          CuratedTripStop(
            name: 'Dahab Lagoon (Windsurfing)',
            description:
                'A shallow, wind-swept lagoon famous as a world windsurfing destination. '
                'Even beginners can take a 1-hour lesson and be gliding across the '
                'water within the hour. The backdrop of Sinai mountains is stunning.',
            estimatedDuration: '2 hours',
            type: 'beach',
            lat: 28.5056,
            lng: 34.5139,
          ),
          CuratedTripStop(
            name: 'Dahab Corniche at Sunset',
            description:
                'Dahab\'s waterfront strip of cushioned restaurants where you sit '
                'on the sand and eat mezze while watching kitesurfers and the Sinai '
                'mountains turn orange. Order the Dahab fish soup.',
            estimatedDuration: '1.5 hours',
            type: 'restaurant',
            lat: 28.4886,
            lng: 34.5132,
          ),
        ],
      ),
      CuratedTripDay(
        day: 3,
        label: 'Day 3 — Mount Sinai & St. Catherine',
        stops: [
          CuratedTripStop(
            name: 'Mount Sinai (Jebel Musa) — Sunrise Hike',
            description:
                'Begin the 2-hour night hike at 2am to reach the 2,285m summit by '
                'sunrise. The camel trail winds past Bedouin tea stops to the peak, '
                'where Moses is said to have received the Ten Commandments.',
            estimatedDuration: '4–5 hours',
            type: 'park',
            lat: 28.5394,
            lng: 33.9749,
          ),
          CuratedTripStop(
            name: 'St. Catherine\'s Monastery',
            description:
                'The world\'s oldest continuously inhabited Christian monastery, '
                'founded in the 6th century AD. Its library holds the second-largest '
                'collection of ancient manuscripts after the Vatican.',
            estimatedDuration: '1.5 hours',
            type: 'church',
            lat: 28.5561,
            lng: 33.9760,
          ),
          CuratedTripStop(
            name: 'Shark\'s Bay Beach',
            description:
                'A quiet, sheltered bay back in Sharm, perfect for a gentle final '
                'swim over the coral. Resident sea turtles feed on the seagrass '
                'here — sightings are almost guaranteed in the morning.',
            estimatedDuration: '2 hours',
            type: 'beach',
            lat: 27.9500,
            lng: 34.3600,
          ),
        ],
      ),
    ],
  );

  // ── Siwa Oasis ───────────────────────────────────────────────────────────────

  static const siwaOasis = CuratedTrip(
    id: 'siwa_oasis',
    title: 'Siwa Oasis',
    tagline: 'A lost world of salt lakes and palm groves in the Libyan Desert',
    imagePath: 'assets/images/islamic_tour.png',
    primaryArea: 'Siwa',
    areas: ['Siwa'],
    durationDays: 2,
    budgetRange: '800–2,500 EGP',
    interests: [
      'Nature & Parks', 'Monuments', 'Adventure Activities', 'Local Experiences'
    ],
    scoringKeys: [
      'natural', 'relaxation', 'adventure', 'pharaonic',
      'ancient', 'desert', 'oasis', 'cultural',
    ],
    highlights: [
      'Swim in Cleopatra\'s Spring — a 30°C natural pool used since antiquity',
      'Watch the sunset from the ruined mud-brick city of Shali Fortress',
      'Drive into the Great Sand Sea on a 4×4 for star-gazing in the dunes',
    ],
    bestFor: 'Off-the-beaten-path explorers',
    rating: 4.8,
    centerLat: 29.2033,
    centerLng: 25.5195,
    days: [
      CuratedTripDay(
        day: 1,
        label: 'Day 1 — Oracle, Springs & Ancient Walls',
        stops: [
          CuratedTripStop(
            name: 'Temple of the Oracle of Amun',
            description:
                'Built in the 6th century BC, this temple is where Alexander the Great '
                'consulted the oracle and was declared son of Amun in 331 BC. '
                'The mud-brick ruins sit on a rocky outcrop above the palm groves.',
            estimatedDuration: '1 hour',
            type: 'archaeological_site',
            lat: 29.2033,
            lng: 25.5195,
          ),
          CuratedTripStop(
            name: 'Shali Fortress',
            description:
                'A 13th-century mud-salt city that was home to Siwa\'s entire population '
                'until a 1926 rainstorm dissolved most of its walls. Climb the crumbling '
                'towers at sunset for a 360° view of the oasis.',
            estimatedDuration: '1 hour',
            type: 'historical_landmark',
            lat: 29.2022,
            lng: 25.5155,
          ),
          CuratedTripStop(
            name: 'Cleopatra\'s Spring (Ein Guba)',
            description:
                'A circular pool of warm, naturally carbonated spring water used for '
                '3,000 years. The pool itself is ancient; the legend that Cleopatra '
                'bathed here is disputed — but the swim is real and wonderful.',
            estimatedDuration: '1.5 hours',
            type: 'park',
            lat: 29.2166,
            lng: 25.5344,
          ),
          CuratedTripStop(
            name: 'Fatnas Island (Fantasy Island)',
            description:
                'A palm-covered island in the middle of a salt lake, reachable by a '
                'narrow causeway. The café serves fresh dates and mint tea. '
                'Sunset here, watching flamingos in the shallows, is unforgettable.',
            estimatedDuration: '1 hour',
            type: 'park',
            lat: 29.2104,
            lng: 25.5157,
          ),
        ],
      ),
      CuratedTripDay(
        day: 2,
        label: 'Day 2 — The Great Sand Sea',
        stops: [
          CuratedTripStop(
            name: 'Great Sand Sea 4×4 Safari',
            description:
                'A full-morning drive into one of the world\'s largest sand seas, '
                'with dunes reaching 100 metres. Stop at fossil-embedded rock formations, '
                'a Berber spring, and the edge of the Libyan Desert horizon.',
            estimatedDuration: '4 hours',
            type: 'park',
            lat: 29.1500,
            lng: 25.4000,
          ),
          CuratedTripStop(
            name: 'Bir Wahed Hot Spring',
            description:
                'A natural hot spring in the middle of the desert, surrounded by a '
                'cold salt lake. Float in the hot pool, then plunge into the cold '
                'lake — Siwa\'s answer to a Nordic spa, in the middle of the Sahara.',
            estimatedDuration: '1.5 hours',
            type: 'park',
            lat: 29.1700,
            lng: 25.4500,
          ),
          CuratedTripStop(
            name: 'Siwa House Museum',
            description:
                'A small but fascinating museum in a restored traditional Siwan house, '
                'showing silver jewellery, embroidered marriage costumes, and tools '
                'used by the Berber community for thousands of years.',
            estimatedDuration: '45 minutes',
            type: 'museum',
            lat: 29.2028,
            lng: 25.5167,
          ),
          CuratedTripStop(
            name: 'Dakrour Mountain (Sunset Viewpoint)',
            description:
                'A sandstone hill on the edge of Siwa town, traditionally used for '
                'an autumn healing festival. The view from the top spans the entire '
                'oasis — a sea of half-a-million date palms stretching to the dunes.',
            estimatedDuration: '45 minutes',
            type: 'park',
            lat: 29.1990,
            lng: 25.5300,
          ),
        ],
      ),
    ],
  );
}
