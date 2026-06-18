// Smoke test for the full feature surface: exercises every extension
// (basics.positions / .nationality / .birthdate / .profiles[].icon,
// languages[].rating, skills[].entries, education[].summary). Pair
// with tests/json_resume_canonical.typ for the vanilla-input case.
//
//   typst compile tests/json_resume.typ /tmp/neat-cv-extended.pdf --root .

#import "../lib.typ": neat-cv-from-json

#set text(lang: "en")

#neat-cv-from-json(json("fixtures/extended_resume.json"))
