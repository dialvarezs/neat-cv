// JSON Resume (https://jsonresume.org/schema) → neat-cv adapter.
// Validation runs through @preview/gairm-import (which aborts compile
// on schema errors); `basics-to-author` (in json-resume-mapping.typ)
// turns the parsed dict into neat-cv's split `author`. The rest of
// this file is the Typst rendering layer.

#import "@preview/gairm-import:0.8.1": (
  parse as _parse, resume-schema-strict,
  lens, add-field, object, array-of,
  str-type, number-type, content-type,
)
#import "../src/cv.typ": cv, cv-with-side
#import "../src/components.typ": (
  contact-info, entry, item-pills, item-with-level, reference, social-links,
)
#import "json-resume-mapping.typ": basics-to-author

// Optional extensions on the strict schema. All `add-field` (not
// `set-required`) so a vanilla JSON Resume document still validates.
// The `level` name is borrowed from canonical JSON Resume's own
// `skills[].level` (string, "e.g. Master") — same vocabulary, our
// usages are numeric (driving `item-with-level` bars) and at nested
// paths so they don't collide with the canonical field.
//   - basics.positions          — array of roles, overrides single-string `label`
//   - basics.profiles[].icon    — Font Awesome name for custom-link profiles
//   - basics.nationality        — Personal block (sidebar)
//   - basics.birthdate          — Personal block (sidebar)
//   - languages[].level         — numeric, drives item-with-level
//                                 (canonical `languages[].fluency` stays the subtitle)
//   - skills[].entries[].level  — numeric per-keyword, distinct from the
//                                 canonical per-group string `skills[].level`
//   - education[].summary       — dissertation / thesis line on the entry
#let _schema = {
  let s = resume-schema-strict
  s = add-field(s, lens(("basics",)), "positions", array-of(str-type))
  s = add-field(s, lens(("basics", "profiles", "items")), "icon", str-type)
  s = add-field(s, lens(("basics",)), "nationality", str-type)
  s = add-field(s, lens(("basics",)), "birthdate", str-type)
  s = add-field(s, lens(("languages", "items")), "level", number-type)
  s = add-field(
    s,
    lens(("skills", "items")),
    "entries",
    array-of(object((name: str-type, level: number-type))),
  )
  s = add-field(s, lens(("education", "items")), "summary", content-type)
  s
}


// ---- Render helpers ----

// Empty `().join(...)` returns `none` in Typst, which trips `entry()`'s
// `x != ""` guards downstream and produces orphan icons / empty rows.
// Always coerce to a real string.
#let _safe-join(arr, sep) = if arr.len() == 0 { "" } else { arr.join(sep) }

/// One-line collapse for `entry()`'s `location` slot.
///
/// -> string
#let _format-location-inline(loc) = {
  if loc == none { return "" }
  if type(loc) == str { return loc }
  if type(loc) == dictionary {
    return _safe-join(
      (
        loc.at("city", default: none),
        loc.at("region", default: none),
        loc.at("countryCode", default: none),
      ).filter(p => p != none and p != ""),
      ", ",
    )
  }
  ""
}

#let _months = (
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
)

/// Iso8601 → short human label. Defensive against year-as-JSON-number
/// and out-of-range months (the strict iso8601 pattern accepts e.g.
/// "2024-00" — we fall back to year-only rather than panic).
///
/// -> string
#let _format-date(d) = {
  if d == none or d == "" { return "" }
  let s = if type(d) == str { d } else { str(d) }
  let parts = s.split("-")
  if parts.len() == 1 { return parts.at(0) }
  let year = parts.at(0)
  let mm = parts.at(1)
  if mm.match(regex("^(0[1-9]|1[0-2])$")) != none {
    return _months.at(int(mm) - 1) + " " + year
  }
  year
}

/// Open-ended entries (no `endDate`) render as "… – present", matching
/// the convention in `template/cv.typ`.
///
/// -> string
#let _format-date-range(start, end) = {
  let s = _format-date(start)
  let e = if end == none or end == "" { "present" } else { _format-date(end) }
  if s == "" and e == "present" { return "" }
  if s == "" { return e }
  s + " – " + e
}

// `entry()` body for work-shaped sections: italic summary above a
// `-`-bulleted highlights list. Empty when both are absent.
#let _entry-body(summary, highlights) = {
  if summary != none { summary; parbreak() }
  if highlights.len() > 0 {
    for h in highlights [- #h
    ]
  }
}


// ---- Body section emitters ----

// Work-shaped sections share `position` + a date range + summary/highlights;
// only the heading and the institution-name field differ.
#let _render-work-shaped(items, heading, employer-field) = {
  if items.len() == 0 { return [] }
  [= #heading]
  for w in items {
    entry(
      title: w.at("position", default: ""),
      institution: w.at(employer-field, default: ""),
      location: _format-location-inline(w.at("location", default: none)),
      date: _format-date-range(
        w.at("startDate", default: none),
        w.at("endDate", default: none),
      ),
      _entry-body(
        w.at("summary", default: none),
        w.at("highlights", default: ()),
      ),
    )
  }
}

#let _render-experience(items) = _render-work-shaped(items, "Experience", "name")
#let _render-volunteer(items) = _render-work-shaped(items, "Volunteering", "organization")

#let _render-education(items) = {
  if items.len() == 0 { return [] }
  [= Education]
  for ed in items {
    let study = ed.at("studyType", default: "")
    let area = ed.at("area", default: "")
    let title = if study != "" and area != "" {
      study + " — " + area
    } else if study != "" { study } else { area }
    let courses = ed.at("courses", default: ())
    let score = ed.at("score", default: none)
    let summary = ed.at("summary", default: none)
    let body = {
      if summary != none { summary; parbreak() }
      if score != none [Score: #score
      ]
      if courses.len() > 0 [Coursework: #courses.join(", ")
      ]
    }
    entry(
      title: title,
      institution: ed.at("institution", default: ""),
      location: "",
      date: _format-date-range(
        ed.at("startDate", default: none),
        ed.at("endDate", default: none),
      ),
      body,
    )
  }
}

#let _render-projects(items) = {
  if items.len() == 0 { return [] }
  [= Projects]
  for p in items {
    let keywords = p.at("keywords", default: ())
    let body = {
      let desc = p.at("description", default: none)
      if desc != none { desc; parbreak() }
      let highlights = p.at("highlights", default: ())
      if highlights.len() > 0 {
        for h in highlights [- #h
        ]
      }
      if keywords.len() > 0 [_#keywords.join(", ")_
      ]
    }
    entry(
      title: p.at("name", default: ""),
      institution: _safe-join(p.at("roles", default: ()), ", "),
      location: "",
      date: _format-date-range(
        p.at("startDate", default: none),
        p.at("endDate", default: none),
      ),
      body,
    )
  }
}

// Flat single-date sections (awards / certificates / publications)
// share an `entry()` shape — only the field names and heading differ.
// `summary-key: none` for sections without a body field.
#let _render-flat-entries(items, heading, title-key, inst-key, date-key, summary-key) = {
  if items.len() == 0 { return [] }
  [= #heading]
  for it in items {
    let body = if summary-key != none { it.at(summary-key, default: "") } else { "" }
    entry(
      title: it.at(title-key, default: ""),
      institution: it.at(inst-key, default: ""),
      location: "",
      date: _format-date(it.at(date-key, default: none)),
      body,
    )
  }
}

#let _render-awards(items) = _render-flat-entries(items, "Awards", "title", "awarder", "date", "summary")
#let _render-certificates(items) = _render-flat-entries(items, "Certificates", "name", "issuer", "date", none)
#let _render-publications(items) = _render-flat-entries(items, "Publications", "name", "publisher", "releaseDate", "summary")

#let _render-references(items) = {
  if items.len() == 0 { return [] }
  [= References]
  for r in items {
    reference(
      name: r.at("name", default: ""),
      role: "",
      location: "",
      r.at("reference", default: ""),
    )
  }
}

#let _render-body(sections) = {
  _render-experience(sections.at("work", default: ()))
  _render-education(sections.at("education", default: ()))
  _render-volunteer(sections.at("volunteer", default: ()))
  _render-projects(sections.at("projects", default: ()))
  _render-awards(sections.at("awards", default: ()))
  _render-certificates(sections.at("certificates", default: ()))
  _render-publications(sections.at("publications", default: ()))
  _render-references(sections.at("references", default: ()))
}

// Sidebar order mirrors the canonical `template/cv.typ`: summary →
// interests → contact → personal → languages → skills → social
// links at the bottom.
#let _render-sidebar(sections) = {
  let basics = sections.at("basics", default: (:))
  let summary = basics.at("summary", default: none)
  if summary != none [= About me
  #summary
  ]

  let interests = sections.at("interests", default: ())
  if interests.len() > 0 {
    [= Interests]
    for i in interests {
      let name = i.at("name", default: "")
      let keywords = i.at("keywords", default: ())
      if keywords.len() > 0 {
        [- #name: #keywords.join(", ")
        ]
      } else {
        [- #name
        ]
      }
    }
  }

  [= Contact
  #contact-info()
  ]

  // `parbreak()` between fields so Nationality and Date of birth don't
  // collide on one rendered line (markup `\n` alone runs them together).
  let nationality = basics.at("nationality", default: none)
  let birthdate = basics.at("birthdate", default: none)
  if nationality != none or birthdate != none {
    [= Personal]
    if nationality != none {
      [Nationality: #nationality]
      parbreak()
    }
    if birthdate != none {
      [Date of birth: #birthdate]
    }
  }

  // `level` (numeric) → item-with-level with `fluency` as subtitle;
  // canonical `fluency`-only documents fall back to a bullet line.
  let languages = sections.at("languages", default: ())
  if languages.len() > 0 {
    [= Languages]
    for l in languages {
      let lang = l.at("language", default: "")
      let level = l.at("level", default: none)
      let fluency = l.at("fluency", default: "")
      if level != none {
        item-with-level(lang, level, subtitle: fluency)
      } else if fluency != "" {
        [- #lang — #emph(fluency)]
      } else {
        [- #lang]
      }
    }
  }

  // `entries[]` (levelled items) → per-item item-with-level. Falls
  // back to `keywords[]` rendered as item-pills (canonical JSON Resume).
  // A levelless entry degrades to a bullet rather than a zero-filled bar.
  for s in sections.at("skills", default: ()) {
    let name = s.at("name", default: "")
    let entries = s.at("entries", default: ())
    let keywords = s.at("keywords", default: ())
    if entries.len() == 0 and keywords.len() == 0 { continue }
    if name != "" { [= #name] }
    if entries.len() > 0 {
      for e in entries {
        let item-name = e.at("name", default: "")
        let level = e.at("level", default: none)
        if level != none {
          item-with-level(item-name, level)
        } else {
          [- #item-name]
        }
      }
    } else {
      item-pills(keywords)
    }
  }

  v(1fr)
  social-links()
}


// ---- Public API ----

/// Validate + reshape. Returns `(author, sections)` — `author` plugs
/// into `cv()`'s `author:` kwarg; `sections` is the parsed resume for
/// body rendering.
///
/// -> dictionary
#let from-json-resume(data) = {
  let resume = _parse(data, schema: _schema)
  (author: basics-to-author(resume.at("basics", default: (:))), sections: resume)
}

// `..rest` forwards every kwarg added to `cv` in a future release
// without an adapter edit. Extra positionals are rejected up front so
// `neat-cv-from-json(p, my-prefs)` (drift from the kwarg form) panics
// with a wrapper-aware diagnostic instead of a cv-level one.
#let neat-cv-from-json(data, ..rest) = {
  if rest.pos().len() > 0 {
    panic(
      "neat-cv-from-json takes one positional (`data`); pass cv() kwargs as named arguments. Got extra positionals: "
        + repr(rest.pos()),
    )
  }
  let named = rest.named()
  // The wrapper owns `body` (it renders the sidebar+body via cv-with-side);
  // a caller-supplied `body:` would collide with the trailing positional.
  if "body" in named {
    panic(
      "neat-cv-from-json controls the body via cv-with-side. To inject custom markup, call `from-json-resume(data)` and compose `cv(...)` yourself.",
    )
  }
  let parsed = from-json-resume(data)
  // Merge a caller-supplied `author:` into the JSON-derived one (rather
  // than replacing it wholesale) so partial overrides don't silently
  // drop email / phone / profile fields.
  let merged-author = if "author" in named {
    (..parsed.author, ..named.at("author"))
  } else { parsed.author }
  let kwargs = (author: merged-author)
  for (k, v) in named {
    if k != "author" { kwargs.insert(k, v) }
  }
  cv(
    ..kwargs,
    cv-with-side(
      _render-sidebar(parsed.sections),
      _render-body(parsed.sections),
    ),
  )
}
