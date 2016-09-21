
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
    "daily_fantasy_hours": [-0.1, 3.5, 4.2]
  },
  "projects": [
    {
      "name": "Coolie",
      "url": "https://github.com/nixzhu/Coolie"
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
		let gender: UnknownType?
		let isDogLover: Bool
		let motto: String
		let skills: [String]
		init?(json info: [String: Any]) {
			guard let age = info["age"] as? Int else { return nil }
			guard let dailyFantasyHours = info["daily_fantasy_hours"] as? [Double] else { return nil }
			let gender = info["gender"] as? UnknownType
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let motto = info["motto"] as? String else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			self.age = age
			self.dailyFantasyHours = dailyFantasyHours
			self.gender = gender
			self.isDogLover = isDogLover
			self.motto = motto
			self.skills = skills
		}
	}
	let detail: Detail
	let name: String
	struct Project {
		let name: String
		let url: String
		init?(json info: [String: Any]) {
			guard let name = info["name"] as? String else { return nil }
			guard let url = info["url"] as? String else { return nil }
			self.name = name
			self.url = url
		}
	}
	let projects: [Project]
	init?(json info: [String: Any]) {
		guard let detailJSONDictionary = info["detail"] as? [String: Any] else { return nil }
		guard let detail = Detail(json: detailJSONDictionary) else { return nil }
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [[String: Any]] else { return nil }
		let projects = projectsJSONArray.map({ Project(json: $0) }).flatMap({ $0 })
		self.detail = detail
		self.name = name
		self.projects = projects
	}
}
```

Pretty cool, ah?

Now you can modify the models (the name of properties or their type) if you need.

You can specify constructor name or json dictionary name like following command:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --constructor-name fromJSONDictionary --json-dictionary-name JSONDictionary
```

It will generate:

``` swift
struct User {
	struct Detail {
		let age: Int
		let dailyFantasyHours: [Double]
		let gender: UnknownType?
		let isDogLover: Bool
		let motto: String
		let skills: [String]
		static func fromJSONDictionary(_ info: JSONDictionary) -> Detail? {
			guard let age = info["age"] as? Int else { return nil }
			guard let dailyFantasyHours = info["daily_fantasy_hours"] as? [Double] else { return nil }
			let gender = info["gender"] as? UnknownType
			guard let isDogLover = info["is_dog_lover"] as? Bool else { return nil }
			guard let motto = info["motto"] as? String else { return nil }
			guard let skills = info["skills"] as? [String] else { return nil }
			return Detail(age: age, dailyFantasyHours: dailyFantasyHours, gender: gender, isDogLover: isDogLover, motto: motto, skills: skills)
		}
	}
	let detail: Detail
	let name: String
	struct Project {
		let name: String
		let url: String
		static func fromJSONDictionary(_ info: JSONDictionary) -> Project? {
			guard let name = info["name"] as? String else { return nil }
			guard let url = info["url"] as? String else { return nil }
			return Project(name: name, url: url)
		}
	}
	let projects: [Project]
	static func fromJSONDictionary(_ info: JSONDictionary) -> User? {
		guard let detailJSONDictionary = info["detail"] as? JSONDictionary else { return nil }
		guard let detail = Detail.fromJSONDictionary(detailJSONDictionary) else { return nil }
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [JSONDictionary] else { return nil }
		let projects = projectsJSONArray.map({ Project.fromJSONDictionary($0) }).flatMap({ $0 })
		return User(detail: detail, name: name, projects: projects)
	}
}
```

You may need `typealias JSONDictionary = [String: Any]` at first.

If you need class model, use the following command:

``` bash
$ ./.build/debug/coolie -i test.json --model-name User --model-type class
```

If you need more information for debug, append a `--debug` option in the command.

## Contact

NIX [@nixzhu](https://twitter.com/nixzhu)

## License

Coolie is available under the [MIT License][mitLink]. See the LICENSE file for more info.
[mitLink]:http://opensource.org/licenses/MIT
