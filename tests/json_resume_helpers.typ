// Unit tests for the mapping helpers in
// `internal/json-resume-mapping.typ`. Compile this file to run the
// assertions:
//
//   typst compile tests/json_resume_helpers.typ /tmp/sink.pdf --root .

#import "../internal/json-resume-mapping.typ": (
  _classify-profiles, _split-name, basics-to-author,
)


// ---- _split-name ----

#assert.eq(_split-name("Emmett Brown"), (
  firstname: "Emmett",
  lastname: "Brown",
))
#assert.eq(
  _split-name("Emmett Lathrop Brown"),
  (firstname: "Emmett", lastname: "Lathrop Brown"),
)
#assert.eq(_split-name("Doc"), (firstname: "Doc", lastname: ""))
#assert.eq(_split-name(""), (firstname: "", lastname: ""))
#assert.eq(_split-name(none), (firstname: "", lastname: ""))


// ---- _classify-profiles ----

// Known networks fold to lowercase and surface as usernames.
#assert.eq(
  _classify-profiles((
    (
      network: "GitHub",
      username: "docbrown",
      url: "https://github.com/docbrown",
    ),
    (
      network: "LinkedIn",
      username: "doc-brown",
      url: "https://linkedin.com/in/doc-brown",
    ),
    (network: "X", username: "docbrown1955", url: "https://x.com/docbrown1955"),
  )),
  (
    known: (github: "docbrown", linkedin: "doc-brown", twitter: "docbrown1955"),
    custom: (),
  ),
)

// Unknown networks become custom-links with full URLs.
#assert.eq(
  _classify-profiles((
    (network: "DeLorean", url: "https://example.com/dl"),
  )),
  (known: (:), custom: ((label: "DeLorean", url: "https://example.com/dl"),)),
)

// `icon` extension propagates as `icon-name` on the custom-link record.
#assert.eq(
  _classify-profiles((
    (
      network: "DeLorean Time Machine",
      icon: "car",
      url: "https://example.com/dl",
    ),
  )),
  (
    known: (:),
    custom: (
      (
        label: "DeLorean Time Machine",
        url: "https://example.com/dl",
        icon-name: "car",
      ),
    ),
  ),
)

// Edge cases: empty / none input, multi-word known network, known
// network missing username (falls through to custom).
#assert.eq(_classify-profiles(()), (known: (:), custom: ()))
#assert.eq(_classify-profiles(none), (known: (:), custom: ()))
#assert.eq(
  _classify-profiles(((network: "Google Scholar", username: "abc"),)),
  (known: (scholar: "abc"), custom: ()),
)
#assert.eq(
  _classify-profiles(((network: "GitHub", url: "https://github.com/x"),)),
  (known: (:), custom: ((label: "GitHub", url: "https://github.com/x"),)),
)

// Unknown network with only a username (no URL scheme) — Typst's
// link() would render a broken hyperlink, so the entry is skipped.
#assert.eq(
  _classify-profiles(((network: "PrivateThing", username: "docbrown"),)),
  (known: (:), custom: ()),
)
// `mailto:` / `tel:` schemes are accepted (functional Typst links).
#assert.eq(
  _classify-profiles(((network: "Email", url: "mailto:doc@example.com"),)),
  (known: (:), custom: ((label: "Email", url: "mailto:doc@example.com"),)),
)


// ---- basics-to-author: positions extension ----

// Array `positions` overrides single-string `label`.
#assert.eq(
  basics-to-author((
    name: "Doc Brown",
    positions: ("Inventor", "Theoretical Physicist"),
    label: "ignored",
  )),
  (
    firstname: "Doc",
    lastname: "Brown",
    position: ("Inventor", "Theoretical Physicist"),
  ),
)
// Empty `positions` array falls back to `label`.
#assert.eq(
  basics-to-author((name: "Doc Brown", positions: (), label: "Inventor")),
  (firstname: "Doc", lastname: "Brown", position: "Inventor"),
)
// No `positions` at all → canonical `label` flows through.
#assert.eq(
  basics-to-author((name: "Doc Brown", label: "Inventor")),
  (firstname: "Doc", lastname: "Brown", position: "Inventor"),
)

// A small empty page so typst-compile produces a valid artifact.
#set page(width: 5cm, height: 5cm)
helpers ok
