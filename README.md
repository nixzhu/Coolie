# Coolie([苦力](https://zh.wikipedia.org/wiki/%E8%8B%A6%E5%8A%9B))

Coolie parse a JSON file to generate models (& their constructors).

苦力有很强的类型推断能力，除了能识别 URL 或常见 Date 类型，还能自动推断数组类型（并进行类型合并），你可从下面的例子看出细节。

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
    "loves": [],
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
      "bytes": [1, 2, 3],
      "more": {
        "design": "nixzhu",
        "code": "nixzhu",
        "comments": ["init", "tokens", "parse"]
      }
    },
    null,
    {
      "name": null,
      "bytes": [],
      "more": null
    }
  ]
}
```

Build coolie & run:

``` bash
$ swift build
$ ./.build/debug/coolie -i test.json --model-name User --argument-label json --parameter-name info
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
		struct Love {
			init?(json info: [String: Any]) {
			}
		}
		let loves: [Love]
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
			guard let lovesJSONArray = info["loves"] as? [[String: Any]] else { return nil }
			let loves = lovesJSONArray.map({ Love(json: $0) }).flatMap({ $0 })
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
			self.loves = loves
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
		let bytes: [Int]
		let createdAt: Date?
		struct More {
			let code: String
			let comments: [String]
			let design: String
			init?(json info: [String: Any]) {
				guard let code = info["code"] as? String else { return nil }
				guard let comments = info["comments"] as? [String] else { return nil }
				guard let design = info["design"] as? String else { return nil }
				self.code = code
				self.comments = comments
				self.design = design
			}
		}
		let more: More?
		let name: String?
		let url: URL?
		init?(json info: [String: Any]) {
			guard let bytes = info["bytes"] as? [Int] else { return nil }
			let createdAtString = info["created_at"] as? String
			let createdAt = createdAtString.flatMap({ iso8601DateFormatter.date(from: $0) })
			let moreJSONDictionary = info["more"] as? [String: Any]
			let more = moreJSONDictionary.flatMap({ More(json: $0) })
			let name = info["name"] as? String
			let urlString = info["url"] as? String
			let url = urlString.flatMap({ URL(string: $0) })
			self.bytes = bytes
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
let iso8601DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
    return formatter
}()

let dateOnlyDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
```

Use `--iso8601-date-formatter-name` or `--date-only-date-formatter-name` can set the name of the date formatter.

Pretty cool, ah?
Now you can modify the models (the name of properties or their type) if you need.

You can specify constructor name, argument label, or json dictionary name, like following command:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --constructor-name create --argument-label with --parameter-name json --json-dictionary-name JSONDictionary
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
		struct Love {
			static func create(with json: JSONDictionary) -> Love? {
				return Love()
			}
		}
		let loves: [Love]
		let motto: String
		let skills: [String]
		let twitter: URL
		static func create(with json: JSONDictionary) -> Detail? {
			guard let birthdayString = json["birthday"] as? String else { return nil }
			guard let birthday = dateOnlyDateFormatter.date(from: birthdayString) else { return nil }
			guard let favoriteWebsitesStrings = json["favorite_websites"] as? [String] else { return nil }
			let favoriteWebsites = favoriteWebsitesStrings.map({ URL(string: $0) }).flatMap({ $0 })
			let gender = json["gender"] as? UnknownType
			guard let isDogLover = json["is_dog_lover"] as? Bool else { return nil }
			guard let latestDreams = json["latest_dreams"] as? [String?] else { return nil }
			guard let latestFeelings = json["latest_feelings"] as? [Double] else { return nil }
			guard let lovesJSONArray = json["loves"] as? [JSONDictionary] else { return nil }
			let loves = lovesJSONArray.map({ Love.create(with: $0) }).flatMap({ $0 })
			guard let motto = json["motto"] as? String else { return nil }
			guard let skills = json["skills"] as? [String] else { return nil }
			guard let twitterString = json["twitter"] as? String else { return nil }
			guard let twitter = URL(string: twitterString) else { return nil }
			return Detail(birthday: birthday, favoriteWebsites: favoriteWebsites, gender: gender, isDogLover: isDogLover, latestDreams: latestDreams, latestFeelings: latestFeelings, loves: loves, motto: motto, skills: skills, twitter: twitter)
		}
	}
	let detail: Detail
	struct Experience {
		let age: Double
		let name: String
		static func create(with json: JSONDictionary) -> Experience? {
			guard let age = json["age"] as? Double else { return nil }
			guard let name = json["name"] as? String else { return nil }
			return Experience(age: age, name: name)
		}
	}
	let experiences: [Experience]
	let name: String
	struct Project {
		let bytes: [Int]
		let createdAt: Date?
		struct More {
			let code: String
			let comments: [String]
			let design: String
			static func create(with json: JSONDictionary) -> More? {
				guard let code = json["code"] as? String else { return nil }
				guard let comments = json["comments"] as? [String] else { return nil }
				guard let design = json["design"] as? String else { return nil }
				return More(code: code, comments: comments, design: design)
			}
		}
		let more: More?
		let name: String?
		let url: URL?
		static func create(with json: JSONDictionary) -> Project? {
			guard let bytes = json["bytes"] as? [Int] else { return nil }
			let createdAtString = json["created_at"] as? String
			let createdAt = createdAtString.flatMap({ iso8601DateFormatter.date(from: $0) })
			let moreJSONDictionary = json["more"] as? JSONDictionary
			let more = moreJSONDictionary.flatMap({ More.create(with: $0) })
			let name = json["name"] as? String
			let urlString = json["url"] as? String
			let url = urlString.flatMap({ URL(string: $0) })
			return Project(bytes: bytes, createdAt: createdAt, more: more, name: name, url: url)
		}
	}
	let projects: [Project?]
	static func create(with json: JSONDictionary) -> User? {
		guard let detailJSONDictionary = json["detail"] as? JSONDictionary else { return nil }
		guard let detail = Detail.create(with: detailJSONDictionary) else { return nil }
		guard let experiencesJSONArray = json["experiences"] as? [JSONDictionary] else { return nil }
		let experiences = experiencesJSONArray.map({ Experience.create(with: $0) }).flatMap({ $0 })
		guard let name = json["name"] as? String else { return nil }
		guard let projectsJSONArray = json["projects"] as? [JSONDictionary?] else { return nil }
		let projects = projectsJSONArray.map({ $0.flatMap({ Project.create(with: $0) }) })
		return User(detail: detail, experiences: experiences, name: name, projects: projects)
	}
}
```

You may need `typealias JSONDictionary = [String: Any]`.

Or the way I like with throws:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --argument-label with --parameter-name json --json-dictionary-name JSONDictionary --throws
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
		struct Love {
			init(with json: JSONDictionary) throws {
			}
			static func create(with json: JSONDictionary) -> Love? {
				do {
					return try Love(with: json)
				} catch {
					print("Love json parse error: \(error)")
					return nil
				}
			}
		}
		let loves: [Love]
		let motto: String
		let skills: [String]
		let twitter: URL
		init(with json: JSONDictionary) throws {
			guard let birthdayString = json["birthday"] as? String else { throw ParseError.notFound(key: "birthday") }
			guard let birthday = dateOnlyDateFormatter.date(from: birthdayString) else { throw ParseError.failedToGenerate(property: "birthday") }
			guard let favoriteWebsitesStrings = json["favorite_websites"] as? [String] else { throw ParseError.notFound(key: "favorite_websites") }
			let favoriteWebsites = favoriteWebsitesStrings.map({ URL(string: $0) }).flatMap({ $0 })
			let gender = json["gender"] as? UnknownType
			guard let isDogLover = json["is_dog_lover"] as? Bool else { throw ParseError.notFound(key: "is_dog_lover") }
			guard let latestDreams = json["latest_dreams"] as? [String?] else { throw ParseError.failedToGenerate(property: "latestDreams") }
			guard let latestFeelings = json["latest_feelings"] as? [Double] else { throw ParseError.notFound(key: "latest_feelings") }
			guard let lovesJSONArray = json["loves"] as? [JSONDictionary] else { throw ParseError.notFound(key: "loves") }
			let loves = lovesJSONArray.map({ Love(with: $0) }).flatMap({ $0 })
			guard let motto = json["motto"] as? String else { throw ParseError.notFound(key: "motto") }
			guard let skills = json["skills"] as? [String] else { throw ParseError.notFound(key: "skills") }
			guard let twitterString = json["twitter"] as? String else { throw ParseError.notFound(key: "twitter") }
			guard let twitter = URL(string: twitterString) else { throw ParseError.failedToGenerate(property: "twitter") }
			self.birthday = birthday
			self.favoriteWebsites = favoriteWebsites
			self.gender = gender
			self.isDogLover = isDogLover
			self.latestDreams = latestDreams
			self.latestFeelings = latestFeelings
			self.loves = loves
			self.motto = motto
			self.skills = skills
			self.twitter = twitter
		}
		static func create(with json: JSONDictionary) -> Detail? {
			do {
				return try Detail(with: json)
			} catch {
				print("Detail json parse error: \(error)")
				return nil
			}
		}
	}
	let detail: Detail
	struct Experience {
		let age: Double
		let name: String
		init(with json: JSONDictionary) throws {
			guard let age = json["age"] as? Double else { throw ParseError.notFound(key: "age") }
			guard let name = json["name"] as? String else { throw ParseError.notFound(key: "name") }
			self.age = age
			self.name = name
		}
		static func create(with json: JSONDictionary) -> Experience? {
			do {
				return try Experience(with: json)
			} catch {
				print("Experience json parse error: \(error)")
				return nil
			}
		}
	}
	let experiences: [Experience]
	let name: String
	struct Project {
		let bytes: [Int]
		let createdAt: Date?
		struct More {
			let code: String
			let comments: [String]
			let design: String
			init(with json: JSONDictionary) throws {
				guard let code = json["code"] as? String else { throw ParseError.notFound(key: "code") }
				guard let comments = json["comments"] as? [String] else { throw ParseError.notFound(key: "comments") }
				guard let design = json["design"] as? String else { throw ParseError.notFound(key: "design") }
				self.code = code
				self.comments = comments
				self.design = design
			}
			static func create(with json: JSONDictionary) -> More? {
				do {
					return try More(with: json)
				} catch {
					print("More json parse error: \(error)")
					return nil
				}
			}
		}
		let more: More?
		let name: String?
		let url: URL?
		init(with json: JSONDictionary) throws {
			guard let bytes = json["bytes"] as? [Int] else { throw ParseError.notFound(key: "bytes") }
			let createdAtString = json["created_at"] as? String
			let createdAt = createdAtString.flatMap({ iso8601DateFormatter.date(from: $0) })
			let moreJSONDictionary = json["more"] as? JSONDictionary
			let more = moreJSONDictionary.flatMap({ More(with: $0) })
			let name = json["name"] as? String
			let urlString = json["url"] as? String
			let url = urlString.flatMap({ URL(string: $0) })
			self.bytes = bytes
			self.createdAt = createdAt
			self.more = more
			self.name = name
			self.url = url
		}
		static func create(with json: JSONDictionary) -> Project? {
			do {
				return try Project(with: json)
			} catch {
				print("Project json parse error: \(error)")
				return nil
			}
		}
	}
	let projects: [Project?]
	init(with json: JSONDictionary) throws {
		guard let detailJSONDictionary = json["detail"] as? JSONDictionary else { throw ParseError.notFound(key: "detail") }
		guard let detail = try? Detail(with: detailJSONDictionary) else { throw ParseError.failedToGenerate(property: "detail") }
		guard let experiencesJSONArray = json["experiences"] as? [JSONDictionary] else { throw ParseError.notFound(key: "experiences") }
		let experiences = experiencesJSONArray.map({ Experience(with: $0) }).flatMap({ $0 })
		guard let name = json["name"] as? String else { throw ParseError.notFound(key: "name") }
		guard let projectsJSONArray = json["projects"] as? [JSONDictionary?] else { throw ParseError.notFound(key: "projects") }
		let projects = projectsJSONArray.map({ $0.flatMap({ Project(with: $0) }) })
		self.detail = detail
		self.experiences = experiences
		self.name = name
		self.projects = projects
	}
	static func create(with json: JSONDictionary) -> User? {
		do {
			return try User(with: json)
		} catch {
			print("User json parse error: \(error)")
			return nil
		}
	}
}
```

Of course, you need to define `ParseError`:

``` swift
enum ParseError: Error {
    case notFound(key: String)
    case failedToGenerate(property: String)
}
```

If you need class model, use the following command:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --model-type class
```

``` swift
class User {
	class Detail {
		var birthday: Date
		var favoriteWebsites: [URL]
		var gender: UnknownType?
		var isDogLover: Bool
		var latestDreams: [String?]
		var latestFeelings: [Double]
		class Love {
			init?(_ json: [String: Any]) {
			}
		}
		var loves: [Love]
		var motto: String
		var skills: [String]
		var twitter: URL
		init?(_ json: [String: Any]) {
			guard let birthdayString = json["birthday"] as? String else { return nil }
			guard let birthday = dateOnlyDateFormatter.date(from: birthdayString) else { return nil }
			guard let favoriteWebsitesStrings = json["favorite_websites"] as? [String] else { return nil }
			let favoriteWebsites = favoriteWebsitesStrings.map({ URL(string: $0) }).flatMap({ $0 })
			let gender = json["gender"] as? UnknownType
			guard let isDogLover = json["is_dog_lover"] as? Bool else { return nil }
			guard let latestDreams = json["latest_dreams"] as? [String?] else { return nil }
			guard let latestFeelings = json["latest_feelings"] as? [Double] else { return nil }
			guard let lovesJSONArray = json["loves"] as? [[String: Any]] else { return nil }
			let loves = lovesJSONArray.map({ Love($0) }).flatMap({ $0 })
			guard let motto = json["motto"] as? String else { return nil }
			guard let skills = json["skills"] as? [String] else { return nil }
			guard let twitterString = json["twitter"] as? String else { return nil }
			guard let twitter = URL(string: twitterString) else { return nil }
			self.birthday = birthday
			self.favoriteWebsites = favoriteWebsites
			self.gender = gender
			self.isDogLover = isDogLover
			self.latestDreams = latestDreams
			self.latestFeelings = latestFeelings
			self.loves = loves
			self.motto = motto
			self.skills = skills
			self.twitter = twitter
		}
	}
	var detail: Detail
	class Experience {
		var age: Double
		var name: String
		init?(_ json: [String: Any]) {
			guard let age = json["age"] as? Double else { return nil }
			guard let name = json["name"] as? String else { return nil }
			self.age = age
			self.name = name
		}
	}
	var experiences: [Experience]
	var name: String
	class Project {
		var bytes: [Int]
		var createdAt: Date?
		class More {
			var code: String
			var comments: [String]
			var design: String
			init?(_ json: [String: Any]) {
				guard let code = json["code"] as? String else { return nil }
				guard let comments = json["comments"] as? [String] else { return nil }
				guard let design = json["design"] as? String else { return nil }
				self.code = code
				self.comments = comments
				self.design = design
			}
		}
		var more: More?
		var name: String?
		var url: URL?
		init?(_ json: [String: Any]) {
			guard let bytes = json["bytes"] as? [Int] else { return nil }
			let createdAtString = json["created_at"] as? String
			let createdAt = createdAtString.flatMap({ iso8601DateFormatter.date(from: $0) })
			let moreJSONDictionary = json["more"] as? [String: Any]
			let more = moreJSONDictionary.flatMap({ More($0) })
			let name = json["name"] as? String
			let urlString = json["url"] as? String
			let url = urlString.flatMap({ URL(string: $0) })
			self.bytes = bytes
			self.createdAt = createdAt
			self.more = more
			self.name = name
			self.url = url
		}
	}
	var projects: [Project?]
	init?(_ json: [String: Any]) {
		guard let detailJSONDictionary = json["detail"] as? [String: Any] else { return nil }
		guard let detail = Detail(detailJSONDictionary) else { return nil }
		guard let experiencesJSONArray = json["experiences"] as? [[String: Any]] else { return nil }
		let experiences = experiencesJSONArray.map({ Experience($0) }).flatMap({ $0 })
		guard let name = json["name"] as? String else { return nil }
		guard let projectsJSONArray = json["projects"] as? [[String: Any]?] else { return nil }
		let projects = projectsJSONArray.map({ $0.flatMap({ Project($0) }) })
		self.detail = detail
		self.experiences = experiences
		self.name = name
		self.projects = projects
	}
}
```

Also `--argument-label`, `--parameter-name` and `--json-dictionary-name` options are available for class.

If you need more information for debug, append a `--debug` option in all the commands.

## Contact

NIX [@nixzhu](https://twitter.com/nixzhu)

## License

Coolie is available under the [MIT License][mitLink]. See the LICENSE file for more info.
[mitLink]:http://opensource.org/licenses/MIT
