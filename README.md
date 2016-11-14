
# Coolie([苦力](https://zh.wikipedia.org/wiki/%E8%8B%A6%E5%8A%9B))

Coolie parse a JSON file to generate models (& their constructors).

[Working with JSON in Swift](https://developer.apple.com/swift/blog/?id=37)

中文介绍：[制作一个苦力](https://github.com/nixzhu/dev-blog/blob/master/2016-06-29-coolie.md)

## Requirements

Swift 3.0

## Example

`test.json`:

``` json
{
  "name": "NIX",
  "detail": {
    "birthday": "1987-10-04",
    "gender": null,
    "is_dog_lover": true,
    "skills": [
      "Swift on iOS",
      "C on Linux"
    ],
    "motto": "爱你所爱，恨你所恨。",
    "latest_feelings": [4, 3.5, -4.2],
    "latest_dreams": [null, "Love", null, "Hate"],
    "favorite_websites": ["https://google.com", "https://www.apple.com"],
    "twitter": "https://twitter.com/nixzhu"
  },
  "experiences": [
    {
      "name": "Linux",
      "age": 2.5
    },
    {
      "name": "iOS",
      "age": 4
    }
  ],
  "projects": [
    {
      "name": "Coolie",
      "url": "https://github.com/nixzhu/Coolie",
      "created_at": "2016-01-24T14:50:51.644000Z",
      "more": {
        "design": "nixzhu",
        "code": "nixzhu"
      }
    },
    null,
    {
      "name": null,
      "url": null,
      "created_at": null,
      "more": {
        "design": null,
        "code": null
      }
    }
  ]
}
```

Build coolie & run:

``` bash
$ swift build
$ ./.build/debug/coolie -i test.json --model-name User --argument-label json
```

It will generate:

``` swift
struct User {
	struct Detail {
		let birthday: Date
		let favoriteWebsites: [URL]
		let gender: UnknownType?
		let isDogLover: Bool
		let latestDreams: [String?]
		let latestFeelings: [Double]
		let motto: String
		let skills: [String]
		let twitter: URL
		init?(json info: [String: Any]) {
			guard let birthdayString = info["birthday"] as? String else { return nil }
			guard let birthday = dateOnlyDateFormatter.date(from: birthdayString) else { return nil }
			guard let favoriteWebsitesStrings = info["favorite_websites"] as? [String] else { return nil }
			let favoriteWebsites = favoriteWebsitesStrings.map({ URL(string: $0) }).flatMap({ $0 })
			let gender = info["gender"] as? UnknownType
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let latestDreams = info["latest_dreams"] as? [String?] else { return nil }
			guard let latestFeelings = info["latest_feelings"] as? [Double] else { return nil }
			guard let motto = info["motto"] as? String else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			guard let twitterString = info["twitter"] as? String else { return nil }
			guard let twitter = URL(string: twitterString) else { return nil }
			self.birthday = birthday
			self.favoriteWebsites = favoriteWebsites
			self.gender = gender
			self.isDogLover = isDogLover
			self.latestDreams = latestDreams
			self.latestFeelings = latestFeelings
			self.motto = motto
			self.skills = skills
			self.twitter = twitter
		}
	}
	let detail: Detail
	struct Experience {
		let age: Double
		let name: String
		init?(json info: [String: Any]) {
			guard let age = info["age"] as? Double else { return nil }
			guard let name = info["name"] as? String else { return nil }
			self.age = age
			self.name = name
		}
	}
	let experiences: [Experience]
	let name: String
	struct Project {
		let createdAt: Date?
		struct More {
			let code: String?
			let design: String?
			init?(json info: [String: Any]) {
				let code = info["code"] as? String
				let design = info["design"] as? String
				self.code = code
				self.design = design
			}
		}
		let more: More
		let name: String?
		let url: URL?
		init?(json info: [String: Any]) {
			let createdAtString = info["created_at"] as? String
			let createdAt = createdAtString.flatMap({ jsonLikeDateFormatter.date(from: $0) })
			guard let moreJSONDictionary = info["more"] as? [String: Any] else { return nil }
			guard let more = More(json: moreJSONDictionary) else { return nil }
			let name = info["name"] as? String
			let urlString = info["url"] as? String
			let url = urlString.flatMap({ URL(string: $0) })
			self.createdAt = createdAt
			self.more = more
			self.name = name
			self.url = url
		}
	}
	let projects: [Project?]
	init?(json info: [String: Any]) {
		guard let detailJSONDictionary = info["detail"] as? [String: Any] else { return nil }
		guard let detail = Detail(json: detailJSONDictionary) else { return nil }
		guard let experiencesJSONArray = info["experiences"] as? [[String: Any]] else { return nil }
		let experiences = experiencesJSONArray.map({ Experience(json: $0) }).flatMap({ $0 })
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [[String: Any]?] else { return nil }
		let projects = projectsJSONArray.map({ $0.flatMap({ Project(json: $0) }) })
		self.detail = detail
		self.experiences = experiences
		self.name = name
		self.projects = projects
	}
}
```

You may need some date formatters:

``` swift
let jsonLikeDateFormatter: DateFormatter = {
    let formater = DateFormatter()
    formater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    return formater
}()

let dateOnlyDateFormatter: DateFormatter = {
    let formater = DateFormatter()
    formater.dateFormat = "yyyy-MM-dd"
    return formater
}()
```

Use `--json-like-date-formatter-name` or `--date-only-date-formatter-name` can set the name of date formatter.

Pretty cool, ah?

Now you can modify the models (the name of properties or their type) if you need.

You can specify constructor name, argument label, or json dictionary name, like following command:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --constructor-name create --argument-label with --json-dictionary-name JSONDictionary
```

It will generate:

``` swift
struct User {
	struct Detail {
		let birthday: Date
		let favoriteWebsites: [URL]
		let gender: UnknownType?
		let isDogLover: Bool
		let latestDreams: [String?]
		let latestFeelings: [Double]
		let motto: String
		let skills: [String]
		let twitter: URL
		static func create(with info: JSONDictionary) -> Detail? {
			guard let birthdayString = info["birthday"] as? String else { return nil }
			guard let birthday = dateOnlyDateFormatter.date(from: birthdayString) else { return nil }
			guard let favoriteWebsitesStrings = info["favorite_websites"] as? [String] else { return nil }
			let favoriteWebsites = favoriteWebsitesStrings.map({ URL(string: $0) }).flatMap({ $0 })
			let gender = info["gender"] as? UnknownType
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let latestDreams = info["latest_dreams"] as? [String?] else { return nil }
			guard let latestFeelings = info["latest_feelings"] as? [Double] else { return nil }
			guard let motto = info["motto"] as? String else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			guard let twitterString = info["twitter"] as? String else { return nil }
			guard let twitter = URL(string: twitterString) else { return nil }
			return Detail(birthday: birthday, favoriteWebsites: favoriteWebsites, gender: gender, isDogLover: isDogLover, latestDreams: latestDreams, latestFeelings: latestFeelings, motto: motto, skills: skills, twitter: twitter)
		}
	}
	let detail: Detail
	struct Experience {
		let age: Double
		let name: String
		static func create(with info: JSONDictionary) -> Experience? {
			guard let age = info["age"] as? Double else { return nil }
			guard let name = info["name"] as? String else { return nil }
			return Experience(age: age, name: name)
		}
	}
	let experiences: [Experience]
	let name: String
	struct Project {
		let createdAt: Date?
		struct More {
			let code: String?
			let design: String?
			static func create(with info: JSONDictionary) -> More? {
				let code = info["code"] as? String
				let design = info["design"] as? String
				return More(code: code, design: design)
			}
		}
		let more: More
		let name: String?
		let url: URL?
		static func create(with info: JSONDictionary) -> Project? {
			let createdAtString = info["created_at"] as? String
			let createdAt = createdAtString.flatMap({ jsonLikeDateFormatter.date(from: $0) })
			guard let moreJSONDictionary = info["more"] as? JSONDictionary else { return nil }
			guard let more = More.create(with: moreJSONDictionary) else { return nil }
			let name = info["name"] as? String
			let urlString = info["url"] as? String
			let url = urlString.flatMap({ URL(string: $0) })
			return Project(createdAt: createdAt, more: more, name: name, url: url)
		}
	}
	let projects: [Project?]
	static func create(with info: JSONDictionary) -> User? {
		guard let detailJSONDictionary = info["detail"] as? JSONDictionary else { return nil }
		guard let detail = Detail.create(with: detailJSONDictionary) else { return nil }
		guard let experiencesJSONArray = info["experiences"] as? [JSONDictionary] else { return nil }
		let experiences = experiencesJSONArray.map({ Experience.create(with: $0) }).flatMap({ $0 })
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [JSONDictionary?] else { return nil }
		let projects = projectsJSONArray.map({ $0.flatMap({ Project.create(with: $0) }) })
		return User(detail: detail, experiences: experiences, name: name, projects: projects)
	}
}
```

You may need `typealias JSONDictionary = [String: Any]`.

If you need class model, use the following command:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --model-type class
```

Also `--argument-label` and `--json-dictionary-name` options are available for class.

If you need more information for debug, append a `--debug` option in all the commands.

## Contact

NIX [@nixzhu](https://twitter.com/nixzhu)

## License

Coolie is available under the [MIT License][mitLink]. See the LICENSE file for more info.
[mitLink]:http://opensource.org/licenses/MIT
