class FirstAidStep {
  final String text;
  const FirstAidStep({required this.text});
}

class FirstAidTopic {
  final String title;
  final String overview;
  final String emoji;
  final String severity;
  final List<FirstAidStep> steps;
  final String? warning;

  const FirstAidTopic({
    required this.title,
    required this.overview,
    required this.emoji,
    required this.severity,
    required this.steps,
    this.warning,
  });
}

final firstAidTopics = [
  FirstAidTopic(
    title: 'CPR (Cardiopulmonary Resuscitation)',
    overview: 'CPR is a life-saving technique used when someone\'s heart stops beating. Act quickly — every second counts.',
    emoji: '❤️',
    severity: 'Critical',
    steps: [
      FirstAidStep(text: 'Check the scene is safe. Tap the person and shout "Are you OK?"'),
      FirstAidStep(text: 'Call emergency services (191 in Thailand, 911 in US, 112 in EU) immediately. Put on speakerphone.'),
      FirstAidStep(text: 'Kneel beside the person\'s chest. Place the heel of one hand on the center of the chest (between nipples).'),
      FirstAidStep(text: 'Place your other hand on top and interlock fingers. Keep your arms straight.'),
      FirstAidStep(text: 'Push hard and fast — at least 2 inches deep, 100-120 compressions per minute. Let the chest fully recoil.'),
      FirstAidStep(text: 'After 30 compressions, give 2 rescue breaths: tilt head back, lift chin, pinch nose, and breathe mouth-to-mouth for 1 second each.'),
      FirstAidStep(text: 'Repeat cycles of 30 compressions and 2 breaths until help arrives or the person shows signs of life.'),
    ],
    warning: 'Do NOT stop CPR unless the person wakes up, trained responders take over, or you are physically exhausted.',
  ),
  FirstAidTopic(
    title: 'Choking (Heimlich Maneuver)',
    overview: 'Someone is choking if they cannot speak, cough, or breathe. Act immediately.',
    emoji: '🫁',
    severity: 'Critical',
    steps: [
      FirstAidStep(text: 'Ask "Are you choking?" If they nod yes but cannot speak, act now.'),
      FirstAidStep(text: 'Stand behind the person and wrap your arms around their waist.'),
      FirstAidStep(text: 'Make a fist with one hand and place the thumb side just above their navel.'),
      FirstAidStep(text: 'Grasp your fist with the other hand and thrust inward and upward sharply.'),
      FirstAidStep(text: 'Repeat thrusts until the object is dislodged or the person becomes unconscious.'),
      FirstAidStep(text: 'If unconscious, lower them to the ground, call emergency services, and start CPR.'),
    ],
    warning: 'Do NOT perform the Heimlich on infants under 1 year — use back blows and chest thrusts instead.',
  ),
  FirstAidTopic(
    title: 'Bleeding Control',
    overview: 'Severe bleeding can lead to shock or death within minutes. Act fast to stop blood loss.',
    emoji: '🩸',
    severity: 'Critical',
    steps: [
      FirstAidStep(text: 'Put on disposable gloves if available. Do not remove any embedded objects.'),
      FirstAidStep(text: 'Apply firm, direct pressure to the wound using a clean cloth, gauze, or bandage.'),
      FirstAidStep(text: 'If blood soaks through, do NOT remove the first layer — add more on top.'),
      FirstAidStep(text: 'Elevate the injured area above heart level if no broken bones.'),
      FirstAidStep(text: 'Apply a tourniquet only if bleeding is life-threatening (severe arm/leg wound) — place 2-3 inches above the wound.'),
      FirstAidStep(text: 'Keep the person warm and calm. Call emergency services immediately.'),
    ],
    warning: 'Do NOT remove an embedded object — it may be plugging the wound. Apply pressure around it and seek medical help.',
  ),
  FirstAidTopic(
    title: 'Burns Treatment',
    overview: 'Burns can be thermal, chemical, or electrical. Cooling the burn immediately reduces the damage.',
    emoji: '🔥',
    severity: 'Urgent',
    steps: [
      FirstAidStep(text: 'Move the person away from the heat source. Do not touch the burn.'),
      FirstAidStep(text: 'Cool the burn under cool (not cold) running water for at least 10 minutes.'),
      FirstAidStep(text: 'Remove clothing or jewelry near the burn unless stuck to the skin.'),
      FirstAidStep(text: 'Cover the burn loosely with a sterile gauze or clean cloth. Do not apply ice.'),
      FirstAidStep(text: 'Do NOT pop blisters — they protect against infection.'),
      FirstAidStep(text: 'Take over-the-counter pain relief if available. Seek medical attention for burns larger than 3 inches or on face/hands/genitals.'),
    ],
    warning: 'Do NOT apply butter, toothpaste, or ice to burns — these make the injury worse.',
  ),
  FirstAidTopic(
    title: 'Fractures & Sprains',
    overview: 'A fracture is a broken bone. A sprain is a stretched or torn ligament. Immobilize the area to prevent further injury.',
    emoji: '🦴',
    severity: 'Urgent',
    steps: [
      FirstAidStep(text: 'Do NOT move the person if a neck or back injury is suspected — wait for paramedics.'),
      FirstAidStep(text: 'Immobilize the injured area using splints (boards, rolled magazines, or towels) bandaged above and below the injury.'),
      FirstAidStep(text: 'Apply ice wrapped in a cloth for 20 minutes to reduce swelling.'),
      FirstAidStep(text: 'Elevate the injured limb above heart level if possible.'),
      FirstAidStep(text: 'For sprains: follow RICE — Rest, Ice, Compression (elastic bandage), Elevation.'),
      FirstAidStep(text: 'Seek medical attention. Signs of fracture include deformity, swelling, bruising, or inability to move the limb.'),
    ],
    warning: 'Do NOT try to realign or push a broken bone back into place. This can cause nerve and blood vessel damage.',
  ),
  FirstAidTopic(
    title: 'Poisoning',
    overview: 'Poisoning can occur through ingestion, inhalation, skin contact, or injection. Act quickly to minimize harm.',
    emoji: '☠️',
    severity: 'Critical',
    steps: [
      FirstAidStep(text: 'Call your local poison control center immediately (Thailand: 1669, US: 1-800-222-1222, UK: 111).'),
      FirstAidStep(text: 'If the person is unconscious, having seizures, or not breathing — call emergency services first.'),
      FirstAidStep(text: 'Do NOT induce vomiting unless instructed by a medical professional.'),
      FirstAidStep(text: 'Identify the poison: check containers, plants, or substances nearby. Keep samples for medical personnel.'),
      FirstAidStep(text: 'If poison is on the skin: remove contaminated clothing and rinse skin with water for 15-20 minutes.'),
      FirstAidStep(text: 'If poison is inhaled: move the person to fresh air immediately.'),
    ],
    warning: 'Do NOT give the person anything to eat or drink unless told by poison control. Do NOT induce vomiting for acid or petroleum products.',
  ),
];
