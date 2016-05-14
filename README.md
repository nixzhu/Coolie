
# Coolie([苦力](https://zh.wikipedia.org/wiki/%E8%8B%A6%E5%8A%9B))

Coolie parse a JSON file to generate models (& their constructors).

## Requirements

Swift 2.1

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
$ xcrun swiftc Sources/*.swift -o coolie
$ ./coolie -i test.json --model-name User
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
		init?(_ info: [String: AnyObject]) {
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
		let description: String
		let name: String
		let url: String
		init?(_ info: [String: AnyObject]) {
			guard let description = info["description"] as? String else { return nil }
			guard let name = info["name"] as? String else { return nil }
			guard let url = info["url"] as? String else { return nil }
			self.description = description
			self.name = name
			self.url = url
		}
	}
	let projects: [Project]
	init?(_ info: [String: AnyObject]) {
		guard let detailJSONDictionary = info["detail"] as? [String: AnyObject] else { return nil }
		guard let detail = Detail(detailJSONDictionary) else { return nil }
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [[String: AnyObject]] else { return nil }
		let projects = projectsJSONArray.map({ Project($0) }).flatMap({ $0 })
		self.detail = detail
		self.name = name
		self.projects = projects
	}
}
```

Pretty cool, ah?

Now you can modify the models (the name of properties or their type) if you need.

You can specify constructor name like following command:

``` bash
$ ./coolie -i test.json --model-name User --constructor-name fromJSONDictionary
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
		static func fromJSONDictionary(info: [String: AnyObject]) -> Detail? {
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
		let description: String
		let name: String
		let url: String
		static func fromJSONDictionary(info: [String: AnyObject]) -> Project? {
			guard let description = info["description"] as? String else { return nil }
			guard let name = info["name"] as? String else { return nil }
			guard let url = info["url"] as? String else { return nil }
			return Project(description: description, name: name, url: url)
		}
	}
	let projects: [Project]
	static func fromJSONDictionary(info: [String: AnyObject]) -> User? {
		guard let detailJSONDictionary = info["detail"] as? [String: AnyObject] else { return nil }
		guard let detail = Detail.fromJSONDictionary(detailJSONDictionary) else { return nil }
		guard let name = info["name"] as? String else { return nil }
		guard let projectsJSONArray = info["projects"] as? [[String: AnyObject]] else { return nil }
		let projects = projectsJSONArray.map({ Project.fromJSONDictionary($0) }).flatMap({ $0 })
		return User(detail: detail, name: name, projects: projects)
	}
}
```

If you need class model, use the following command:

``` bash
$ ./coolie -i test.json --model-name User --model-type class
```

## Contact

NIX [@nixzhu](https://twitter.com/nixzhu)

## License

Coolie is available under the [MIT License][mitLink]. See the LICENSE file for more info.
[mitLink]:http://opensource.org/licenses/MIT
