#import "lib.typ": cv, entry

#show: cv.with(author: (firstname: "X", lastname: "Y"))

#entry(
  title: "Test",
  date: "2024",
  institution: ().join(", "),
  location: "",
  "body",
)
