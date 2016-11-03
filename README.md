
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
    "age": 18,
    "gender": null,
    "is_dog_lover": true,
    "skills": [
      "Swift on iOS",
      "C on Linux"
    ],
    "motto": "爱你所爱，恨你所恨。",
    "daily_fantasy_hours": [4, 3.5, -4.2],
    "dreams": [null, "Love", null, "Hate"]
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
      "more": {
        "design": "nixzhu",
        "code": "nixzhu"
      }
    },
    null,
    {
      "name": null,
      "url": "https://github.com/nixzhu/XProject",
      "more": {
        "design": null,
        "code": "unknown"
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
		let age: Int
		let dailyFantasyHours: [Double]
		let dreams: [String?]
		let gender: UnknownType?
		let isDogLover: Bool
		let motto: String
		let skills: [String]
		init?(json info: [String: Any]) {
			guard let age = info["age"] as? Int else { return nil }
			guard let dailyFantasyHours = info["daily_fantasy_hours"] as? [Double] else { return nil }
			guard let dreams = info["dreams"] as? [String?] else { return nil }
			let gender = info["gender"] as? UnknownType
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let motto = info["motto"] as? String else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			self.age = age
			self.dailyFantasyHours = dailyFantasyHours
			self.dreams = dreams
			self.gender = gender
			self.isDogLover = isDogLover
			self.motto = motto
			self.skills = skills
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
		struct More {
			let code: String
			let design: String?
			init?(json info: [String: Any]) {
				guard let code = info["code"] as? String else { return nil }
				let design = info["design"] as? String
				self.code = code
				self.design = design
			}
		}
		let more: More
		let name: String?
		let url: String
		init?(json info: [String: Any]) {
			guard let moreJSONDictionary = info["more"] as? [String: Any] else { return nil }
			guard let more = More(json: moreJSONDictionary) else { return nil }
			let name = info["name"] as? String
			guard let url = info["url"] as? String else { return nil }
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
		let age: Int
		let dailyFantasyHours: [Double]
		let dreams: [String?]
		let gender: UnknownType?
		let isDogLover: Bool
		let motto: String
		let skills: [String]
		static func create(with info: JSONDictionary) -> Detail? {
			guard let age = info["age"] as? Int else { return nil }
			guard let dailyFantasyHours = info["daily_fantasy_hours"] as? [Double] else { return nil }
			guard let dreams = info["dreams"] as? [String?] else { return nil }
			let gender = info["gender"] as? UnknownType
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let motto = info["motto"] as? String else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			return Detail(age: age, dailyFantasyHours: dailyFantasyHours, dreams: dreams, gender: gender, isDogLover: isDogLover, motto: motto, skills: skills)
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
		struct More {
			let code: String
			let design: String?
			static func create(with info: JSONDictionary) -> More? {
				guard let code = info["code"] as? String else { return nil }
				let design = info["design"] as? String
				return More(code: code, design: design)
			}
		}
		let more: More
		let name: String?
		let url: String
		static func create(with info: JSONDictionary) -> Project? {
			guard let moreJSONDictionary = info["more"] as? JSONDictionary else { return nil }
			guard let more = More.create(with: moreJSONDictionary) else { return nil }
			let name = info["name"] as? String
			guard let url = info["url"] as? String else { return nil }
			return Project(more: more, name: name, url: url)
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

You may need `typealias JSONDictionary = [String: Any]` at first.

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
