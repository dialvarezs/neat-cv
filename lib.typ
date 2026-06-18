#import "src/state.typ": *
#import "src/components.typ": *
#import "src/publications.typ": *
#import "src/cv.typ": *
#import "src/letter.typ": *
#import "internal/json-resume.typ": (
  from-json-resume,
  _format-date,
  _format-date-range,
  _format-location-inline,
)


// ---- JSON Resume one-call wrapper ----

// Body emitter for `neat-cv-from-json` — one `entry()` per
// work/education/volunteer/project/award/certificate/publication item.
#let _render-sections(sections) = {
  let work = sections.at("work", default: ())
  let education = sections.at("education", default: ())
  let volunteer = sections.at("volunteer", default: ())
  let awards = sections.at("awards", default: ())
  let certificates = sections.at("certificates", default: ())
  let publications = sections.at("publications", default: ())
  let projects = sections.at("projects", default: ())
  let references-list = sections.at("references", default: ())
  let basics = sections.at("basics", default: (:))

  let summary = basics.at("summary", default: none)
  if summary != none {
    [= About me
    #summary
    ]
  }

  if work.len() > 0 {
    [= Experience]
    for w in work {
      let highlights = w.at("highlights", default: ())
      let summary-w = w.at("summary", default: none)
      let description = {
        if summary-w != none { summary-w; parbreak() }
        if highlights.len() > 0 {
          for h in highlights [- #h
          ]
        }
      }
      entry(
        title: w.at("position", default: ""),
        institution: w.at("name", default: ""),
        location: _format-location-inline(w.at("location", default: none)),
        date: _format-date-range(
          w.at("startDate", default: none),
          w.at("endDate", default: none),
        ),
        description,
      )
    }
  }

  if education.len() > 0 {
    [= Education]
    for ed in education {
      let study = ed.at("studyType", default: "")
      let area = ed.at("area", default: "")
      let title = if study != "" and area != "" {
        study + " — " + area
      } else if study != "" {
        study
      } else {
        area
      }
      let courses = ed.at("courses", default: ())
      let score = ed.at("score", default: none)
      let description = {
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
        description,
      )
    }
  }

  if volunteer.len() > 0 {
    [= Volunteering]
    for v in volunteer {
      let highlights = v.at("highlights", default: ())
      let summary-v = v.at("summary", default: none)
      let description = {
        if summary-v != none { summary-v; parbreak() }
        if highlights.len() > 0 {
          for h in highlights [- #h
          ]
        }
      }
      entry(
        title: v.at("position", default: ""),
        institution: v.at("organization", default: ""),
        location: "",
        date: _format-date-range(
          v.at("startDate", default: none),
          v.at("endDate", default: none),
        ),
        description,
      )
    }
  }

  if projects.len() > 0 {
    [= Projects]
    for p in projects {
      let highlights = p.at("highlights", default: ())
      let desc = p.at("description", default: none)
      let keywords = p.at("keywords", default: ())
      let description = {
        if desc != none { desc; parbreak() }
        if highlights.len() > 0 {
          for h in highlights [- #h
          ]
        }
        if keywords.len() > 0 [_#keywords.join(", ")_
        ]
      }
      entry(
        title: p.at("name", default: ""),
        institution: (p.at("roles", default: ())).join(", "),
        location: "",
        date: _format-date-range(
          p.at("startDate", default: none),
          p.at("endDate", default: none),
        ),
        description,
      )
    }
  }

  if awards.len() > 0 {
    [= Awards]
    for a in awards {
      entry(
        title: a.at("title", default: ""),
        institution: a.at("awarder", default: ""),
        location: "",
        date: _format-date(a.at("date", default: none)),
        a.at("summary", default: ""),
      )
    }
  }

  if certificates.len() > 0 {
    [= Certificates]
    for c in certificates {
      entry(
        title: c.at("name", default: ""),
        institution: c.at("issuer", default: ""),
        location: "",
        date: _format-date(c.at("date", default: none)),
        "",
      )
    }
  }

  if publications.len() > 0 {
    [= Publications]
    for pub in publications {
      entry(
        title: pub.at("name", default: ""),
        institution: pub.at("publisher", default: ""),
        location: "",
        date: _format-date(pub.at("releaseDate", default: none)),
        pub.at("summary", default: ""),
      )
    }
  }

  if references-list.len() > 0 {
    [= References]
    for r in references-list {
      reference(
        name: r.at("name", default: ""),
        role: "",
        location: "",
        r.at("reference", default: ""),
      )
    }
  }
}

// Sidebar emitter for `neat-cv-from-json`'s default `cv-with-side` layout.
#let _render-sidebar(sections) = {
  let basics = sections.at("basics", default: (:))
  let skills = sections.at("skills", default: ())
  let languages = sections.at("languages", default: ())
  let interests = sections.at("interests", default: ())

  let summary = basics.at("summary", default: none)
  if summary != none [= About me
  #summary
  ]

  [= Contact
  #contact-info()
  ]

  if languages.len() > 0 {
    [= Languages]
    for l in languages {
      [- #l.at("language", default: "") — _#l.at("fluency", default: "")_
      ]
    }
  }

  if skills.len() > 0 {
    for s in skills {
      let name = s.at("name", default: "")
      let keywords = s.at("keywords", default: ())
      if name != "" [= #name]
      if keywords.len() > 0 {
        item-pills(keywords)
      }
    }
  }

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

  v(1fr)
  social-links()
}

// `..rest` forwards every kwarg added to `cv` in a future release
// without an adapter edit. Extra positionals are rejected up front so
// `neat-cv-from-json(p, my-prefs)` (drift from the kwarg form) panics
// with a wrapper-aware diagnostic instead of a cv-level one.
#let neat-cv-from-json(data, ..rest) = {
  if rest.pos().len() > 0 {
    panic("neat-cv-from-json takes one positional (`data`); pass cv() kwargs as named arguments. Got extra positionals: " + repr(rest.pos()))
  }
  let parsed = from-json-resume(data)
  let body = {
    // Strip summary from sidebar so it doesn't render twice.
    let side-sections = parsed.sections
    if "basics" in side-sections {
      let b = side-sections.basics
      if "summary" in b {
        let _ = b.remove("summary")
        side-sections.insert("basics", b)
      }
    }
    cv-with-side(
      _render-sidebar(side-sections),
      _render-sections(parsed.sections),
    )
  }
  // Caller-supplied `author:` overrides the JSON-derived one.
  let kwargs = (author: parsed.author)
  for (k, v) in rest.named() {
    kwargs.insert(k, v)
  }
  cv(..kwargs, body)
}
